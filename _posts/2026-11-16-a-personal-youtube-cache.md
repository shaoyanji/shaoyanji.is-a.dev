---
layout: post
title: "A personal YouTube cache: ytfzf, rclone, Jotta, and a 5 GB CRUD app"
date: 2026-11-16 00:00:00 +0000
categories: [Blog, Technology]
tags: [technology, automation]
description: "Searching YouTube without opening YouTube already worked on a desktop. This is the cache that makes the result playable on a phone: rclone, a free Jotta account, and a small Go API."
author: matt
image:
  path: https://res.cloudinary.com/de1eajx01/image/upload/f_jpg,q_auto,w_1200,h_630,c_fill/assets/blog/a-personal-youtube-cache.jpg
  alt: "A personal YouTube cache: ytfzf, rclone, Jotta, and a 5 GB CRUD app"
pin: false
toc: true
comments: false
math: false
mermaid: false
---

I already had a way to search YouTube without opening YouTube. ytfzf is a small page that searches through a public Invidious instance, fuzzy-filters the results in the browser the way fzf does, and hands the video to mpv. It works well on a desktop. It does not work on my phone: iOS cannot register a custom `mpv://` scheme, and I cannot run rclone there either. So the missing piece was a cache — a place where a video could live after I asked for it, and a button to play it from there.

This is that cache, as a small CRUD app.

## The shape

There are four parts, and each one does exactly one job:

- **Jottacloud** is the store. A free account gives 5 GB. That is the whole budget, and the app shows it.
- **rclone** is the mover. It is the only thing that talks to Jotta. The account was wired with a single-use personal login token, exchanged for OAuth tokens that live in `~/.config/rclone/rclone.conf` on the server and nowhere else. Never copy that config between machines: every refresh rotates the refresh token, and reusing an old one invalidates the whole token family.
- **serv00** is the machine. It runs yt-dlp and rclone, it holds the playable copies, and its Go webserver serves the pages and the API. I cannot run the same rclone command from my phone, so serv00 is the throughput: the download and the upload both happen there.
- **ytfzf** is the front end. It searches, and now it also adds to the cache and plays from it.

The rule that shaped the whole thing: a video lives in two places. Jotta holds the archive. serv00 holds a playable copy in a public folder, because that is the only copy a browser can play.

## Why two copies

I tested both. A Jotta public link returns the file with `Content-Disposition: attachment`, so the browser treats it as a download, not something to play. The same file served from serv00 plays inline, with seeking, in the browser's native player. So the cache script does not delete the downloaded file after uploading it to Jotta any more. It moves it into the public videos folder instead. Jotta is the archive, serv00 is the player.

## Adding a video

On any search result that is not cached yet, there is an "Add to cache" button. Tapping it posts the video ID to the Go API, and the API starts the cache job in the background:

1. yt-dlp downloads the video (best video up to 1080p plus best audio, merged to mp4).
2. rclone copies it to `jotta:ytcache/`.
3. The playable copy is kept on serv00.
4. The index (`index.json`) gains an entry: id, title, channel, upload date, duration, size, file, and when it was cached.

The add is asynchronous on purpose. A download takes 30 to 60 seconds for a short video, and that is longer than a proxy will patiently wait for one request. So the API answers immediately — "started" — and the page polls a status endpoint every few seconds until the job is done. When it is, the button flips to "▶ cached" and the video plays inline.

Two videos so far, to give a sense of scale: "Me at the zoo" (19 seconds) is 465 KB. "Never Gonna Give You Up" (3:33) is 32 MB and took about half a minute to cache.

## Reading and deleting

The cache page lists what is there, with a search box, a per-video size, and a usage bar: "465 KB of 5 GB used (0.0%)", or "32.7 MB of 5 GB used (0.7%)" when two videos are in. Each entry has a Play link and a Delete button. Delete asks "Sure?" first, then removes the video from all three places: Jotta, the serv00 playable copy, and the index. Deleting is how you make room. The 5 GB is a hard budget, and the bar is there so you can see it filling up before it is full.

## Safety, such as it is

The video ID is validated to the strict 11-character YouTube form before it reaches anything that runs a command, and the cache script is invoked by argument list, never through a shell. There is no auth on these endpoints yet — the same decision as the recipe upload on the same server: get it right first, put the passkey wall on later. That is a known gap, not an oversight.

Two honest notes. Downloading from YouTube violates YouTube's terms even for personal use, and the Jotta personal plan is for personal use only, so this is a single-user cache, not a service. And the Jotta link that forces a download is a reminder that "public link" and "playable link" are not the same thing.

## What is not built

Update. There is no re-cache at a different quality yet — add, list, play, delete, and the usage bar are the whole app. If a video needs a better copy, the path is delete, then add again.

## The files

- `~/ytcache/cache.sh` on serv00 — download, upload, index, keep the playable copy.
- `~/ytcache.go` on serv00 — the API: `POST /vesper/api/ytcache/add`, `GET /vesper/api/ytcache/status`, `POST /vesper/api/ytcache/delete`. Registered in `server.go`, built with `go build`, deployed by moving the binary over the running one and letting the daemon restart it.
- `~/public/vesper/ytfzf/index.html` — search, Add to cache, inline player.
- `~/public/vesper/ytcache/index.html` and `index.json` — the list, the usage bar, delete, and the index the pages read.

The whole loop, end to end: search in ytfzf, tap "Add to cache", wait for it to flip to "▶ cached", play it. When the 5 GB fills up, delete something from the cache page.
