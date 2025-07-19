---
layout: post
title: Entertainment is a Furthering Concept
date: 2025-07-18
description: brutalism but with affordances
author: matt
categories: [Blog]
tags: [energy, blogging, automation, ai]
pin: false
toc: true
comments: false
math: false
mermaid: false
image:
  path: https://envs.sh/bNM.jpg
  alt: a snowglobe website
---

## Updating the ol' website

The website that I've been using as a profile landing page is a bootstrap template that has very aesthetic appeal. Although load times are slower than desirable, it serves a very rudimentary purpose of not looking like vomit. But the downside is that with the tightly knit html, it's difficult to template the documents and make certain elements up-to-date like a static site generator. But yet, it shouldn't be as dense as a blog either. So I have been looking at different ways to template the site so the content can remain fresh from the notes that I take.

### Go Templ

There is a an interesting case for starting a go templ project just for the purpose of templating the content into html. It would be the fastest runtime/devtime combo and it neededn't be a full-fledged server but just a composable utility that is lighter weight than hugo.

### Nix

I have recently been dabbling with nix as a way to build a static site generator. The repo is [here](https://github.com/shaoyanji/nixstix). The idea isthat nix has the flexibility to switch contexts very quickly and although static site generation is a minor utility, it is consistently a painpoint fordocumentation and active development.

### yq and taskfile

I had a lot of fun statically generating the README.md file for my [github profile](https://github.com/shaoyanji). It is quite dynamic at templating a pattern but extremely slow. Regardless, it seems like whichever solution I decide to go with, I will end up making most of the content hierarchy in yaml.

## Bootstrap on cdn and unpkg

Blogposts should not take up more than 20 minutes to write.

There is also the appeal to go ultra brtualistic. A [post](https://x.com/melqtx/status/1946249533543076159) shows that 14kB pages can perhaps shave half a second off of page load times. There is something called a TCP slow algorithm that kicks in when a page is above 15 kB. Currently, my [website](https://bountystash.com) is about 3.2 MB per a [cloudflare scan](https://radar.cloudflare.com/scan/6f0d1425-5757-428e-87c0-6144d7133f60/summary). So I am currently looking at a 20x refactor of website. I remembered the hero image alone was 650 kB. Since the uncompressed total page must be under. I would have to make do with whatever clever arrangements I can with ascii to get the effects that I am aiming for.

## Things I've been practicing
- jp2a as an alternative to the images I use
- cmark --unsafe as an alternative to pandoc
- alpinejs might actually be to big for the brutalism

## Things I've been avoiding
- hugo
- jekyll
