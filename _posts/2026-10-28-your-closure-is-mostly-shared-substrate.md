---
layout: post
title: Your 33.8 GiB NixOS closure is mostly one shared substrate
date: 2026-10-28
description: Pruning packages by reported size reclaims almost nothing. Exclusive bytes are the only number that predicts a smaller system.
author: matt
categories: [Blog, Nix]
tags: [nix, analysis, technology]
pin: false
toc: true
comments: false
math: false
mermaid: false
---

`nix-store -q --size` tells you how big a package's closure is. It does not tell you how much disk you get back by deleting it, and the gap between those two numbers is where everybody's first debloat attempt dies.

My main server's system closure was 33.8 GiB. The obvious plan was to find the biggest entries in that list and cut them. That plan is wrong, and here is the worked example.

## The substrate is not yours to slim

In any modern Linux system, a shared core — glibc, Python, LLVM, Mesa, GTK, systemd, the kernel — accounts for **16–17 GiB** of immutable data. Every package that touches any of it reports a closure that includes it. Chromium reporting 4 GiB does not mean Chromium costs 4 GiB; it means Chromium plus a substrate that would still be there afterwards.

The number that predicts your savings is the package's **exclusive** bytes: its unique code plus dependencies that literally nothing else references. Everything else is bookkeeping.

## Three findings from one afternoon of attribution

I built an attribution pass over the store graph rather than guessing from the closure list, and the surprises were the useful part:

- **A genuine duplicate: 703.2 MiB.** Two Chromium closures where only one was used. One edit, real space, no capability lost. This is the rare free win.
- **`mbrola-voices`, 644.7 MiB.** Looked like an unneeded speech synthesizer. `nix-store -q --referrers` showed it was pulled in by `speech-dispatcher`, which browser text-to-speech needs — the browser is in daily use. Deleting it reclaims disk and silently removes a feature somebody in this house uses.
- **`intel-compute-runtime-legacy1`, 264.5 MiB.** Looked like an unneeded OpenCL compiler. It is the runtime that makes Intel QuickSync hardware transcoding work for Jellyfin. Cutting it would have moved every stream on the NAS from hardware to CPU, which is a much bigger cost than a quarter gigabyte.

Two of the three "obvious" removals were capability trades wearing a size label.

## The rule I use now

Classify before cutting:

1. **Tier 1 — free wins.** True duplicate closures, build artifacts, a second copy of something. No behaviour change, so just do it.
2. **Tier 2 — capability trades.** Anything with a live referrer that exists for a reason. These are decisions about what the machine *is*, not disk hygiene, and they belong in a note explaining why, not in a cleanup commit.

And before believing any number: 33.8 GiB of closure is not 33.8 GiB of deletable things. It is 16–17 GiB of shared substrate plus a long tail where the only honest measurement is the exclusive difference.
