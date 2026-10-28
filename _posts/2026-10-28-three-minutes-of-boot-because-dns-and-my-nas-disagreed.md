---
layout: post
title: Three minutes of boot because DNS and my NAS disagreed
date: 2026-10-28
description: A public resolver on the tailnet silently broke split-horizon DNS and stalled an NFS automount until it timed out twelve times.
author: matt
categories: [Blog, Technology]
tags: [technology, homelab, nix, networking]
pin: false
toc: true
comments: false
math: false
mermaid: false
---

One machine started taking 3 minutes 40 seconds to boot. The one before that took 8 seconds. Nothing in the machine's own config had changed, which is the kind of sentence that usually means the problem is somewhere else entirely.

`systemd-analyze blame` put 3 minutes 12 seconds in `home-manager-devji.service`, which is nonsense on its face: home-manager activation is symlinks. Then it opens them, and one of those symlinks lands on `/Volumes/data`, which is an NFS export from the NAS. So the 3 minutes was not home-manager. It was waiting for a filesystem that never arrived.

## The resolver was the saboteur

The tailnet had a public recursive resolver set as its global DNS: `9.9.9.9`. That sounds harmless. It is not, because of the order things happen in during boot:

1. `tailscaled` starts and takes over system DNS routing via `systemd-resolved`.
2. While it converges, it logs `dns: resolver: forward: no upstream resolvers set, returning SERVFAIL`.
3. Anything that needs a LAN name in that window gets nothing.

The NAS is `192.168.3.25`. My LAN resolves `frieren.lan` and friends through a Pi-hole that lives on that box, so the name only exists in split-horizon DNS. With the overlay's public resolver in charge, the LAN name had nowhere to resolve.

So at 08:18:49 the activation touched `/Volumes/data`, which tripped `Volumes-data.automount`. Name resolution hung. The mount unit then failed with `result 'timeout'` **twelve times**, each after a 15-second timeout, between 08:18:55 and 08:21:58. The reason it retried so fast is a line I had written on purpose, `StartLimitIntervalSec=0` — no rate limiting, because for a NAS mount I wanted it to keep trying. Which is right, right up until the last link in the chain is DNS.

At 08:22:01 the resolver stabilized, `9.9.9.9` was off the tailnet, the mount succeeded instantly, and activation finished in under a second. Live mounts on that host now take under 50 ms.

## What I changed in how I debug this

- `systemd-analyze blame` only tells you *which* unit waited. The interesting question is what it was waiting on, and for an automount that is almost always a name or a route.
- An overlay network's DNS settings are not a private matter. `--accept-dns=true` with a public upstream is a machine-wide routing decision for names, and it will happily overrule a LAN zone that only your house can answer.
- A resolver race looks exactly like a broken NAS. The giveaway is that the mount fails with `timeout` repeatedly while `ping` to the NAS's address works — the address is fine, the name is not.

The fix is boring and that is the point: internal zones get split DNS pointed at the LAN resolver, and a public resolver never becomes the tailnet default on a host whose boot depends on a LAN name.

The general lesson is one I keep re-learning in a fleet of immutable machines: a boot dependency on a *name* is a boot dependency on the resolver, and the resolver has its own startup order. If a mount is the first thing that notices, the mount gets blamed.
