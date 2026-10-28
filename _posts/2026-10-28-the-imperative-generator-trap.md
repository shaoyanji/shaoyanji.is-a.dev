---
layout: post
title: The imperative generator trap, or why `tool install` breaks a declarative host
date: 2026-10-28
description: A vendor CLI wrote a systemd unit into ~/.config, shadowed the Nix store one, and crash-looped 466 times with a bare interpreter.
author: matt
categories: [Blog, Nix]
tags: [nix, automation, technology]
pin: false
toc: true
comments: false
math: false
mermaid: false
---

Every third-party daemon now ships a convenience command: `hermes gateway install`, `foo service enable`, `bar setup`. On a normal Linux box it is helpful. On NixOS it is a small act of vandalism, and it took me one crash loop to learn exactly how it does the damage.

## Two failures stacked on top of each other

I ran the installer while deploying a messaging gateway. It wrote a systemd user unit directly to `~/.config/systemd/user/hermes-gateway.service`. Two things then went wrong, and they compounded.

**The shadowing.** systemd's user-unit search order puts `~/.config/systemd/user/` *above* `/etc/systemd/user/` and above anything a Nix profile puts on the path. So the imperative file did not sit beside the declarative unit — it replaced it. My Home Manager unit was still in the store, still correct, and completely ignored. That is the part that makes this nasty to debug: the config looks right, the store looks right, and the running unit came from somewhere else.

**The interpreter.** The generator wanted a Python that could import its own package. It decided whether it was in a virtualenv by comparing `sys.prefix` with `sys.base_prefix`. Under Nix those are always equal, because that is what a wrapped interpreter looks like, so the check fell through to the "plain system python" branch and wrote `ExecStart` against an unwrapped `/nix/store/...-python3/bin/python3`. That interpreter has neither the CLI nor its dependencies on `sys.path`.

The result was a unit that could never start, restarting every few seconds. It reached **466 restarts** before I looked at it, and the journal line was a single `ModuleNotFoundError`.

## The fix is one line of Nix

```nix
systemd.user.services.hermes-gateway = {
  Service.ExecStart = "${pkgs.llm-agents.hermes-agent}/bin/hermes gateway run";
};
```

In Home Manager that unit is a symlink into the store, and the store binary is a wrapper with its dependencies and environment baked in. Nothing to get wrong at runtime, nothing to overwrite at activation.

## The rule I now follow

- Never run an `install`, `enable`, or `setup` subcommand of a third-party daemon on a declarative host. Read what it would write, then declare that yourself.
- If a self-check in someone else's code asks "am I in a venv?", on Nix the answer will be wrong in a way that only shows up at runtime.
- When a unit behaves like it is not the one in your repo, ask systemd where it came from before you touch the config: `systemctl --user cat <unit>` names the file it actually loaded.

The uncomfortable part is that this class of bug does not fail at `switch`. It fails at boot, silently, in a loop, on a machine you are not watching — which is the opposite of what declarative configuration is for.
