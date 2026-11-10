---
layout: post
title: "Binary caches are the fast path to a new machine"
date: 2026-11-10
categories: [Blog, Nix]
tags: [nix, technology, automation]
description: "The expensive part of bringing up a NixOS host already happened somewhere else. Fetch it."
author: matt
image:
  path: https://res.cloudinary.com/de1eajx01/image/upload/f_jpg,q_auto,w_1200,h_630,c_fill/assets/blog/binary-caches-are-the-fast-path-to-a-new-machine.jpg
  alt: "Binary caches are the fast path to a new machine"
pin: false
toc: true
comments: false
math: false
mermaid: false
---

The slow part of setting up a new machine is not the configuration. It is the compilation. And in Nix, that work is almost always already done — by someone else, on better hardware, and published at a URL.

## What a cache actually saves

A Nix derivation is a pure function from inputs to output, which means an output that exists somewhere with the same inputs is byte-identical to the one you would build. So when a machine asks for `firefox` or a kernel, the question is not "can I build this" but "does a cache have it". If yes, the bootstrap becomes a download.

That is why pointing a fresh install at an existing Hydra build for its architecture is dramatically faster than compiling the same configuration locally — the evaluation and the compilation both already happened, once, upstream. The same trick carries over when you fork someone's setup instead of writing your own: a proven configuration with cached outputs skips the slowest, most fragile part of the whole exercise.

## The habit that follows

- **Bootstrap by substitution.** Add the cache that matches your architecture before you build anything, so the first switch is a fetch rather than an afternoon.
- **Treat a missing cache entry as a design smell.** If a host needs to compile from source on a dual-core, either the input is too new to be cached or something is pinned oddly. Both are worth knowing before you wait.
- **Warm a cache as a deliberate act.** Building a closure on a cheap machine so the expensive-by-the-minute one only substitutes is the same idea pointed inward. It costs minutes on the right hardware instead of hours on the wrong one.

## Where this goes wrong

Two traps. The first is assuming the cache has it: a package pinned to an unreleased commit or a patched kernel is a build, not a download, and the difference shows up as a two-hour wait. The second is trusting a cache blindly — a cache is a third party asserting "this output is what those inputs produce". That is normally exactly right, and it is still an assertion you should know you are relying on.

The mental model I use is simple: in Nix, speed is mostly a question of *where the work happened*, not how clever your machine is. A new host is slow only in the parts nobody has built before, and those are rarely the parts you care about.
