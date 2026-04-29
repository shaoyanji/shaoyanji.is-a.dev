#!/usr/bin/env bash
grep -h "^tags:" _posts/*.md 2>/dev/null | sed 's/tags: \[//; s/\]//' | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort -u
