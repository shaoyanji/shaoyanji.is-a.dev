---
layout: post
title: Static Site Generator Stack is a lot Harder than I Thought
date: 2025-07-04
description: Attempting to make a static site generating using markdown and a cli toolkit around taskfile to incorporate some AI stuff
author: matt
categories: [Blog]
tags: [energy, risk, cybersecurity, technology]
pin: false
toc: true
comments: false
math: false
mermaid: false
---

## I'm making yet another static site generator

On the far end of the spectrum you have a JS framework SPA like Next.JS and on the near end is the [suckless](https://suckless.org) solution with quark and smu.

I would like to do something in the middle but with simplicity in mind.

I call it [cmdstack](https://github.com/shaoyanji/cmdstack) and it really is just two cli tools at the moment: `cmark` and `taskfile`.

What I like about it is how minimalistic it is and how the tools guide the features and properties of the static site generator. Currently, this blog is using the Jekyll static site generator and while it makes things simple, clean and complete. I get perplexed by the lengthy build time. I get it, deploying on github takes a while and it's not instantaneous but then again, a website is just strings of text and the dependency load time makes me gag.

This is why I am pushing for local builds with low dependencies so that it can be or at least appear cache-less.

A final form of this stack would include a docker image builder that features a super fast build tool image that can be summoned for CI/CD. But that is far down the road.

But summoning this demon from the depths of hell has me itching with anxiety.

## Github static hosting

I can't really complain about a free service but it's a little convoluted to make gh-pages work the way I want it (i.e., deploying from a subfolder). It may end up having `index.html` at root directory so that it doesn't become a multi-branch git repo (going counter to the simplicity approach).

## Aesthetic delight

I have also chosen to turn towards the direction of using CDNs for classless CSS. This makes the sites less "declarative" but lighter for local storage and portable across different platforms.

I have also added a few Task scripts that makes parsed markdown syntax for image links and uploads to https://envs.sh for AI automation writing in light of being conservative with low storage space. I am programming from a thin client with 2 GB of RAM and 4 GB of storage running with a DietPi OS. It cannot even handle a `vim` editor without bloating the next kernel upgrade and so I opted for `helix` an editor that has syntax highlighting for multiple languages in less than 50 MB and plugin-less.

These design choices constrain what I can do but it also gives me the freedom to add as many tools and interfaces that I need. When it is ready, it would be a great nix-based static site generator. At the moment, I don't have a full working flakes since it isn't fully fleshed out but the vision is there.

## Things I've been practicing

- `AWK`ing csv files for a data processing task
- Job search
- Preparing for a wedding
- Improving SQL skills
