---
layout: post
title: "Print for screens: one design system across the whole site"
date: 2026-11-23 00:00:00 +0000
categories: [Blog, Web]
tags: [blogging, css, jekyll]
description: "Chirpy shipped three typefaces, card shadows and pill-shaped tags. This is how a site-owned layer put every page on one paper, one measure and one signal colour without forking the theme."
author: matt
pin: false
toc: true
comments: false
math: false
mermaid: false
---

The site has run on Chirpy for two years. It is a good theme: it renders posts, archives, tags, categories and a search index without asking anything of me. What it does not have is a point of view. Left alone it is dark grey on darker grey with Lato body text, cards in soft shadow, a gradient strip behind every tag, a sidebar where each link is a FontAwesome glyph, and a timeline in the archives made of dot characters positioned with fixed pixel offsets.

I have a design document for a different look, and one page already published in it. Ryoku is the surface language I use for everything else: near-black paper, warm ink, hairlines instead of boxes, a serif for statements, a geometric sans for reading, a mono face for signage, exactly one signal colour, and Japanese glyphs as section ornaments. This is the post that took it from one CV page to the whole site.

## The constraint decided the method

The theme is a gem (`jekyll-theme-chirpy`, 6.5.5), not a vendored directory. Forking it would mean carrying every future upstream fix by hand. Overriding it properly is a cascade problem instead, and Jekyll gives a clean way in: if the site owns the file the theme *also* provides, the site's copy wins, and the theme's own `_sass/main` can still be imported underneath it.

So the whole pass is three files that are genuinely mine:

```scss
/* assets/css/jekyll-theme-chirpy.scss */
@import url('https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,300;9..144,400&family=Noto+Sans+JP:wght@400&family=Space+Grotesk:wght@400;500&family=Space+Mono:wght@400&display=swap');
@import 'main';
@import 'ryoku-site';
```

Fonts first, the theme second, the layer last. Everything in `_sass/ryoku-site.scss` therefore lands after the theme's rules at compile time, which is the only reason a one-file override can retune a whole theme without `!important` on every line.

One layout is copied as well, and only because the design needs a hook the theme does not emit: `<body class="ry">` plus a fixed grain element. The copy is the theme's own base layout with those two lines added, so a future upstream change to the layout is a diff I can still read.

## One paper, two editions

The tokens come straight out of the design document. The site uses the NixOS edition — paper `#0b0c1b`, ink `#c4c6d2`, signal `#9299d3` — because `/cv/ryoku/` was already published in it and two editions of the same site is not a style, it is an accident.

```css
:root {
  --ry-paper: #0b0c1b;
  --ry-ink: #c4c6d2;
  --ry-line-soft: color-mix(in srgb, var(--ry-ink) 13%, transparent);
  --ry-line: color-mix(in srgb, var(--ry-ink) 26%, transparent);
  --ry-line-strong: color-mix(in srgb, var(--ry-ink) 42%, transparent);
  --ry-signal: #9299d3;
}
```

Three rule weights at 13, 26 and 42 percent of the ink carry all the structure the theme used to express with borders, backgrounds and shadows. Retuning the theme's own custom properties (`--card-bg`, `--text-color`, `--sidebar-bg` and about thirty others) is what stops the parts Chirpy paints itself — search, the mobile mask, panels — from falling back to its grey.

The cascade is the whole design. Nothing moves; no template is rewritten to produce a different layout.

## Page by page

The home page was the first pass: a numbered eyebrow (`00 · Writing · 記`) and the existing tagline promoted to the one serif statement, with the post list turned from shadowed cards into hairline rows whose thumbnails are greyscale until you hover.

Posts then got the same treatment from the other end. The article header opens on a rule, the title is Fraunces, and the metadata line — posted, updated, author, reading time — is mono, uppercase, wide-tracked, with the theme's calendar and folder glyphs gone. The tail turns into a short sheet: categories and tags as mono labels in square hairline boxes, share icons in muted ink, prev/next as two halves of one rule with serif titles. The contents column sits on a one-pixel spine, and the entry you are reading is marked with the single signal-coloured bar on the page.

Archives, tags and categories each needed a decision the theme had already made badly for this look:

- **Archives.** The theme's timeline is dots and floats positioned against fixed pixel offsets, with a literal white gradient on alternating rows. Re-tinting it would have kept the shadows; I dropped the dots and the gradient and let the page be a ledger — year in Fraunces under a strong rule, one hairline row per post, mono dates.
- **Tags.** The chips had a `0.7em` radius, a drop shadow and a gradient. They are now a mono word inside a hairline, and that is it.
- **Categories.** Cards became rule groups, folder icons retired the same way the sidebar's did, and the collapse chevron survived because it is the tap target, not decoration.

The last piece is the one I like most: every tab page now announces itself with the catalogue head — `01 · Categories · 目`, `03 · Archives · 陳`, `05 · CV · 歴` — rendered from three front-matter fields by a 26-line copy of the `page` layout. The tab title is still there as the `<h1>`, hidden visually so it does not double up with the heading the page content already carries. Screen readers and search engines see the same title they saw before.

## What the layer refuses

No box shadow anywhere. No `backdrop-filter` — the top bar is paper at 88 percent with a bottom hairline. No radius above two pixels except the avatar, which is a circle on purpose. One signal colour, spent on exactly one element per view: the dot beside the current section in the sidebar, or the active contents entry in a post. Prompts and notices, which Chirpy paints as blue and green panels, are the blockquote rule at five percent ink instead.

The one place I departed from a straight port is the hero number. The sidebar counts its own links, so Categories is `01`. Numbering the home page `01` as well made the first page of the site disagree with its own navigation. Home is the cover, so it counts `00`.

## Verifying without a browser

There is no browser on the machine that builds this site, so "does it look right" had to become questions a shell can answer:

- the compiled stylesheet contains the layer's tokens and selectors, and a byte-offset check proves the layer is emitted after the theme's rules;
- every page serves the markup the layer hangs on — `body.ry`, the grain element, the catalogue head with the right number;
- every route returns 200 from a local build, and again over HTTPS after the Pages deploy;
- `task cvcheck` builds and proves both CV PDFs are linked and resolve;
- htmlproofer runs on the CI runner, where it can actually load `libcurl`.

That is weaker than looking at it, and worth saying out loud: a design system verified by assertions is a design system with no obvious breakage, not one that is beautiful. The parts I would look at first in a browser are the archives ledger at 360 px and the tag wall, where ten short words and one long one sit in the same flex row.

## What is next

The theme still owns the search overlay and the 404 page, which are the last two surfaces in its own grey. After that, the design document already asks for something the site does not have: a bone band, one inverted block per page, for the closing call to action. A blog index is not short of places to put one.
