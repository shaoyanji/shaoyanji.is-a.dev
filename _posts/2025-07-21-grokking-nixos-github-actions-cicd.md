---
layout: post
title: Grokking NixOS Github Actions CI/CD and Git Submodules
date: 2025-07-21
description: They really weren't kidding when they say avoid using git submodules if you could
author: matt
categories: [Blog]
tags: [cybersecurity, technology]
pin: false
toc: true
comments: false
math: false
mermaid: false
---

## I already used up all of my free 1500 mins CI/CD on Garnix

[Garnix](https://garnix.io) is a CI/CD service that is free to use up to 1500 minutes per month. It's a really neat service that goes a long way in making long build times in nix palatable to a common user. As detailed in this wonderful [blog post](https://cy7.sh/posts/ci-nixos/), garnix is way faster than github actions at evaluating nix expressions for multi-device configuration pushes.

However, every tiny change and git push as I have been doing for the past few months with NixOS triggers a 30 minute saga of builds that go into a remarkably useful and readily available binary cache on the cloud.

Basically, running through the entirety of the free minutes rather quickly and basically having to resort to local builds that can be rather boring, nasty, frustrating or all of the caveats of using Nix.

One thing I managed to do this evening was to separate my nixvim configuration and secrets into their own respective submodules. That way when I make pushed modular configurations, it wouldn't trigger all of my darwin, nixos, and home-manager builds every time I add a set of ssh keys from a docker container, a vm, or a pod. It's very important to get this piece right as part of a bigger project of full automation with some neat tricks I have planned with AI deployments using Nix as a wrapper.

## Github Actions

A good CI/CD backup is Github Actions. It's a free service that is a bit slow but is very versatile and I've discovered to be delightful when properly configured and frustrating when learning the ropes.

A very good resource for learning Github Actions is the [checkout](https://github.com/actions/checkout#checkout-multiple-repos-private) repo and its documentation. Although it wasn't necessary to turn my secrets submodule to a private repo since it was encrypted with [sops-nix](https://github.com/Mic92/sops-nix), I thought it was necessary and a challenge to make a git submodule that allowed this. Many reasons why this undertaking is a rabbit hole in its own right as is the case of any Nix journey. 

For one, the reason why submodules are often avoided with nix is because they require a very ugly query syntax for your build commands:

```bash
sudo nixos-rebuild switch --flake .#
```

into something like:

```bash
sudo nixos-rebuild switch --flake .?submodules=1#
```

Syntax doesn't bother me as much since I can use my customized taskfiles to do the alias/shortcuts. It matters that things are done well.

So after doing the usual steps of converting my nix modules into git submodules as a standalone flake and a secrets folder, I went ahead and tried hacking away at the `.github/workflow/*.yml`. Only a few lines were needed. For repo fetch:

```yaml
- name: Checkout
  uses: actions/checkout@v4
  with:
    submodules: recursive
    token: "${{ secrets.GH_PAT }}"
```

and for the build:

```yaml
- name: Build
  run: |
    nix build .?submodules=1#nixosConfigurations.${{ matrix.configuration }}.config.system.build.toplevel
```

Transitioning from Nixlang to yaml is like falling back to earth. Yaml is notoriously stupid when it comes to refactor technology. Some day, I may have to revisit making github actions more automated from a nix flake by taking control of the full range of github actions api. But until then, I am glad I was finally able to get one of the things that I wrote in previous post crossed off my list of todos.
