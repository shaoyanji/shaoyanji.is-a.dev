#!/usr/bin/env bash
grep -h "^categories:" _posts/*.md 2>/dev/null | sed 's/categories: \[//; s/\]//' | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort -u
