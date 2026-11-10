---
layout: post
title: "The old laptop is the best UPS I own"
date: 2026-11-10
categories: [Blog, Technology]
tags: [homelab, energy, nix]
description: "A retired Ideapad with an integrated battery is a quieter, cheaper and more honest UPS than the box you would buy for a homelab."
author: matt
image:
  path: https://res.cloudinary.com/de1eajx01/image/upload/f_jpg,q_auto,w_1200,h_630,c_fill/assets/blog/the-old-laptop-is-the-best-ups-i-own.jpg
  alt: "The old laptop is the best UPS I own"
pin: false
toc: true
comments: false
math: false
mermaid: false
---

The NAS in this house is an old Lenovo Ideapad 320-15IKB with a Core i5-8250U, running NixOS with the screen closed. Before that it was a laptop. The reason it is still the NAS is not the CPU — it is the battery.

## A UPS is a box you buy to imitate a laptop

A dedicated UPS for a small homelab is bulky, makes noise, burns standby power, and costs more than the hardware it protects. Meanwhile every laptop already contains a battery, a charge controller, and an embedded controller that is very good at knowing when the lights went out. What laptops do not ship with is a *policy* for what to do at 5%.

That is the whole project:

```nix
services.upower = {
  enable = true;
  usePercentageForPolicy = true;
  percentageLow = 15;       # warn
  percentageCritical = 8;   # urgent
  percentageAction = 5;     # act
  criticalPowerAction = "PowerOff";
};
```

Four numbers and a shutdown action. On a brownout the machine simply keeps running — services, storage pools, containers, all of it — with no UPS beep and no downtime, because a laptop does not consider losing mains power an event.

## Why the graceful part matters more than the backup part

Uninterruptible power is nice. Clean shutdown of a Btrfs filesystem with live databases is the actual goal. The machine runs Immich, Vaultwarden and a handful of containers, and pulling the plug on those is how you get torn journals and half-written writes. A UPS that dies before the host notices is a UPS that fails exactly when it is needed.

With the upower policy, when the battery does reach 5% the host performs a normal `systemd` poweroff: filesystems unmount, database caches flush, containers stop in order. The battery's last few percent are spent shutting down rather than holding the internet up for another four minutes.

## The efficiency argument

Idle consumption on battery, while driving the storage pools and the services, measures about **1.96 W**. A conventional UPS next to it would draw more than that just staying warm. Add silence — no fan, no transformer hum — and the fact that the hardware was already paid for, and the comparison stops being close.

The trade-offs are honest ones: a laptop tops out at two 2.5-inch bays, has a weak thermal budget and no ECC. It is not a server. But for a household NAS that has to survive the grid in a country where the lights flicker, the integrated battery plus a shutdown threshold is the cheapest reliable design I have found, and it degrades gracefully: when the battery eventually wears out, the machine still works, it just stops being a UPS.
