#!/usr/bin/env bash
# Jekyll Blog Post Creator with Gum TUI
# Usage: ./new-post.sh

# Configuration
POSTS_DIR="_posts"
DEFAULT_AUTHOR="matt"
DEFAULT_CATEGORY="Blog"

# Check if posts directory exists
if [[ ! -d "$POSTS_DIR" ]]; then
    echo "❌ Posts directory '$POSTS_DIR' not found"
    exit 1
fi

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "❌ gum is not installed. Please install it first:"
    echo "   https://github.com/charmbracelet/gum#installation"
    exit 1
fi

# Get current date
DATE=$(date "+%Y-%m-%d")

# Interactive prompts using gum
echo "📝 Creating new Jekyll blog post"
echo "================================"

# Title
TITLE=$(gum input --prompt "Title> " --width 80 2>/dev/null) || {
    echo "❌ Title input cancelled or failed"
    exit 1
}

if [[ -z "$TITLE" ]]; then
    echo "❌ Title is required"
    exit 1
fi

# Generate slug from title
SLUG=$(echo "$TITLE" | sed -E 's/(.*)/\L\1/; s/[^a-z0-9]+/_/g; s/^_|_$//g')

# Description (optional)
DESCRIPTION=$(gum input --prompt "Description (optional)> " --width 80 --placeholder "Leave empty for no description" 2>/dev/null || true)

# Author
AUTHOR=$(gum input --prompt "Author> " --value "$DEFAULT_AUTHOR" --width 30 2>/dev/null) || {
    echo "❌ Author input cancelled or failed"
    exit 1
}

if [[ -z "$AUTHOR" ]]; then
    echo "❌ Author is required"
    exit 1
fi

# Categories (multi-select)
echo "📁 Select categories (multi-select, press enter to finish):"
CATEGORIES=$(gum choose --no-limit --height 10 \
    "Blog" "Nix" "Technology" "Energy" "Risk" "Analysis" "Cybersecurity" "Longzhong Plan" "Project" "Web" \
    --selected "$DEFAULT_CATEGORY" 2>/dev/null | sed 's/^/  /' | paste -sd, - | sed 's/,/, /g') || {
    echo "❌ Category selection cancelled or failed"
    exit 1
}

if [[ -z "$CATEGORIES" ]]; then
    echo "❌ At least one category is required"
    exit 1
fi

# Tags (multi-select from existing)
echo "🏷️  Select tags (multi-select, type to filter, press enter to finish):"
TAGS=$(echo "technology risk cybersecurity energy analysis blogging automation ai Go chaos longzhong_plan liu_bei han_dynasty strategy career_consultancy react_native cross_platform_development skill_inventory innovation uncertainty guidance ambition future_planning" | \
    tr ' ' '\n' | gum filter --no-limit --height 15 --placeholder "Select tags" 2>/dev/null | \
    sed 's/^/  /' | paste -sd, - | sed 's/,/, /g') || {
    echo "⚠️  Tag selection cancelled or failed, using default tag 'technology'"
    TAGS="technology"
}

if [[ -z "$TAGS" ]]; then
    echo "⚠️  No tags selected, using default tag 'technology'"
    TAGS="technology"
fi

# Boolean flags
echo "⚙️  Configure post options:"

if gum confirm "Pin to top?" 2>/dev/null; then
    PIN="true"
else
    PIN="false"
fi

if gum confirm "Enable table of contents?" --default 2>/dev/null; then
    TOC="true"
else
    TOC="false"
fi

if gum confirm "Enable comments?" 2>/dev/null; then
    COMMENTS="true"
else
    COMMENTS="false"
fi

if gum confirm "Enable math?" 2>/dev/null; then
    MATH="true"
else
    MATH="false"
fi

if gum confirm "Enable mermaid diagrams?" 2>/dev/null; then
    MERMAID="true"
else
    MERMAID="false"
fi

# Create filename
FILENAME="${POSTS_DIR}/${DATE}-${SLUG}.md"

# Show summary
echo ""
echo "📋 Post Summary:"
echo "   Title: $TITLE"
echo "   Date: $DATE"
echo "   Author: $AUTHOR"
echo "   Categories: [$CATEGORIES]"
echo "   Tags: [$TAGS]"
echo "   File: $FILENAME"
echo ""

# Confirm creation
if ! gum confirm "Create this post?" --default; then
    echo "❌ Post creation cancelled"
    exit 0
fi

# Generate front matter
cat > "$FILENAME" << EOF
---
layout: post
title: ${TITLE}
date: ${DATE}
${DESCRIPTION:+description: ${DESCRIPTION}}
author: ${AUTHOR}
categories: [${CATEGORIES}]
tags: [${TAGS}]
pin: ${PIN}
toc: ${TOC}
comments: ${COMMENTS}
math: ${MATH}
mermaid: ${MERMAID}
---

<!-- Start writing your post here -->
EOF

if [[ ! -f "$FILENAME" ]]; then
    echo "❌ Failed to create post file"
    exit 1
fi

echo "✅ Created: ${FILENAME}"
echo "📝 Opening in editor..."

# Open in editor
if [[ -n "$EDITOR" ]]; then
    $EDITOR "$FILENAME"
else
    echo "⚠️  No EDITOR environment variable set, file created but not opened"
    echo "   Set EDITOR environment variable or open manually: $FILENAME"
fi
