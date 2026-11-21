#!/usr/bin/env bash
# Every PDF this site publishes under `assets/files/` must be the target of a
# `download` anchor on some page, and that href must resolve inside the build.
# GitHub Pages serves a PDF inline without `download`, so a link missing the
# attribute still "works" while navigating away from the page — it fails here.
#
# Usage: ./check-cv-links.sh [site] [files]
#   site   built output (default _site)
#   files  published PDFs (default assets/files)
#
# EXIT: 0 pass · 1 unlinked, navigating, or pointing at nothing · 2 cannot tell.
set -uo pipefail
site=${1:-_site}
files=${2:-assets/files}
[ -d "$site" ] || { echo "check-cv-links: no build at $site — run: bundle exec jekyll b" >&2; exit 2; }
[ -d "$files" ] || { echo "check-cv-links: no $files — run this from the site checkout" >&2; exit 2; }

exec python3 - "$site" "$files" <<'PY'
import os, posixpath, re, sys

site, files = sys.argv[1:3]
HTML = re.compile(r"\.html?$", re.I)
ANCHOR = re.compile(r"<a\b[^>]*>", re.I)
HREF = re.compile(r'\bhref\s*=\s*"([^"]*)"', re.I)
HAS_DOWNLOAD = re.compile(r"(?<![-_\w])download(?![\w-])", re.I)

published = sorted(f for f in os.listdir(files) if f.lower().endswith(".pdf"))
anchors = []
for base, _, names in os.walk(site):
    for name in sorted(names):
        if not HTML.search(name):
            continue
        page = os.path.join(base, name)
        rel = os.path.relpath(page, site)
        here = "/" + posixpath.dirname(rel)
        with open(page, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        for tag in ANCHOR.findall(text):
            match = HREF.search(tag)
            if match is None:
                continue
            href = match.group(1)
            bare = href.split("#")[0].split("?")[0]
            if not bare.lower().endswith(".pdf"):
                continue
            target = bare if bare.startswith("/") else posixpath.join(here, bare)
            anchors.append((rel, posixpath.normpath(target), bare, HAS_DOWNLOAD.search(tag) is not None))

problems = []
for name in published:
    mine = [a for a in anchors if posixpath.basename(a[1]) == name]
    if not mine:
        problems.append(f"no page links {name}")
        continue
    if not any(a[3] for a in mine):
        problems.append(f"{name} is linked without download (the click would navigate)")
    dead = sorted({a[2] for a in mine if not os.path.isfile(os.path.join(site, a[1].lstrip('/')))})
    if dead:
        problems.append(f"{name} is linked as {dead[0]} but that resolves nowhere in {site}")

if problems:
    for line in problems:
        print(f"FAIL {line}")
    print(f"check-cv-links: {len(problems)} problem(s) across {len(published)} published CV(s)")
    sys.exit(1)

print(f"check-cv-links: {len(published)} published CV(s) linked as downloads and resolving ({', '.join(published)})")
PY
