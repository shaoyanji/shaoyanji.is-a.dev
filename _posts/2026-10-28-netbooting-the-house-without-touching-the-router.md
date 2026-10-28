---
layout: post
title: Netbooting the house without touching the router
date: 2026-10-28
description: ProxyDHCP plus HTTP streaming turns a consumer router into a PXE-capable network, with no DHCP options and no single point of failure.
author: matt
categories: [Blog, Technology]
tags: [homelab, networking, automation]
pin: false
toc: true
comments: false
math: false
mermaid: false
---

PXE has a bad reputation in home labs, and most of it comes from TFTP. The other half comes from the fact that netbooting normally means owning DHCP: options 66 and 67 point a client at a boot server, and the box that hands out addresses becomes the box that can knock the whole house offline when it reboots.

My router is the ISP one. It has no custom DHCP options, and I am not going to make my NAS the household DHCP server so that I can reinstall a laptop twice a year. So the boot stack runs in **ProxyDHCP** mode instead.

## Addresses from the router, boot metadata from the lab

`dnsmasq` is configured with `port = 0`, which switches off its DNS server entirely — Pi-hole owns port 53 and there is no point fighting over it. Then:

```conf
dhcp-range=192.168.3.0,proxy
```

In proxy mode dnsmasq never leases an address. The client broadcasts a Discover, the ISP router answers with an address, and dnsmasq separately answers on port 4011 with the PXE next-server and bootloader metadata. The router stays the only DHCP server, so a reboot of the lab server cannot take the network down; it can only make the *next* netboot fail.

## Two stages, and the second one is HTTP

1. **Stage 1 (TFTP, port 69):** the firmware pulls a single ~1 MB iPXE binary (`ipxe.efi` for UEFI, `undionly.kpxe` for BIOS). Small enough that TFTP's complete lack of flow control does not matter.
2. **Stage 2 (HTTP, port 80):** iPXE chains to nginx, and everything after that — kernels, squashfs root filesystems, whole ISOs — streams over plain HTTP with `sendfile`, at gigabit line speed.

The ISO library is just a directory on the NAS that nginx serves with `autoindex on`. Dropping a new installer in is `cp`, and any machine that boots to PXE sees it.

## What it bought me

- Router untouched: no DHCP options, no firmware patching, no risk to the household.
- No TFTP lockups on large files, because only the tiny first stage goes over TFTP.
- One place to add an image, and bare-metal reinstall becomes a choice on a boot menu instead of a USB stick scavenger hunt.

Two things to know if you copy it. ProxyDHCP requires that the real DHCP server answer quickly; a router that takes its time can make the PXE handshake flaky. And `port = 0` is load-bearing — the moment dnsmasq also answers DNS on a host that already runs Pi-hole, you have two resolvers fighting over port 53 and a very confusing afternoon.

The whole thing is roughly twenty lines of Nix and one nginx server block, which is the right size for infrastructure that mostly needs to be invisible.
