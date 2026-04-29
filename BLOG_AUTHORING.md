# Blog Authoring CLI

This Jekyll blog now includes an enhanced authoring CLI using Taskfile and gum for interactive post creation.

## Requirements

- [Task](https://taskfile.dev/) - Task runner
- [gum](https://github.com/charmbracelet/gum) - Interactive TUI tools

## Usage

### Using Taskfile (Recommended)

```bash
# Interactive post creation with all prompts
task post

# List existing tags
task list-tags

# List existing categories
task list-categories
```

### Using Standalone Script

```bash
./new-post.sh
```

## Features

The authoring CLI provides:

- **Interactive title input** with proper slug generation
- **Optional description** field for SEO
- **Author field** (defaults to "matt")
- **Multi-select categories** from predefined list including existing categories
- **Multi-select tags** from existing blog tags with fuzzy search
- **Boolean toggles** for:
  - Pin to top
  - Table of contents (default: true)
  - Comments (default: false)
  - Math support (default: false)
  - Mermaid diagrams (default: false)
- **Error handling** with clear error messages
- **Confirmation step** showing post summary before creation
- **Automatic file creation** in `_posts/` with proper date format
- **Opens in editor** using `$EDITOR` environment variable (with fallback if not set)

## Front Matter Template

Generated posts include this front matter:

```yaml
---
layout: post
title: Your Title
date: YYYY-MM-DD
description: Optional description
author: matt
categories: [Blog, Technology]
tags: [technology, cybersecurity]
pin: false
toc: true
comments: false
math: false
mermaid: false
---
```

## Tag Management

The tag selection includes all existing tags from your blog:
- technology, risk, cybersecurity, energy, analysis
- blogging, automation, ai, Go
- chaos, longzhong_plan, liu_bei, han_dynasty
- strategy, career_consultancy, react_native
- cross_platform_development, skill_inventory
- innovation, uncertainty, guidance, ambition, future_planning

To add new tags to the selection list, edit the tag list in `new-post.sh`.

## Category Management

The category selection includes existing categories:
- Blog, Nix, Technology, Energy, Risk, Analysis, Cybersecurity
- Longzhong Plan, Project, Web

To add new categories, edit the category list in `new-post.sh`.

## Examples

```bash
# Create a new post with interactive prompts
task post

# List all tags currently used in the blog
task list-tags

# List all categories currently used in the blog
task list-categories
```

## Migration from post.nu

The previous `post.nu` script was a manual attempt at post creation. The new system provides:
- Better UX with gum's interactive prompts
- Proper front matter structure matching your blog's format
- Tag management from existing posts
- Multi-select capabilities
- Integration with existing Taskfile workflow
- Standalone script option for flexibility

## Error Handling

The script includes comprehensive error handling:

- **Missing gum**: Checks if gum is installed before proceeding
- **Missing directory**: Verifies `_posts` directory exists
- **Empty required fields**: Validates title, author, and categories
- **Cancelled operations**: Handles user cancellation gracefully
- **File creation errors**: Verifies file was created successfully
- **Missing editor**: Warns if EDITOR is not set

## Troubleshooting

### gum: error: unexpected argument
This error was caused by incorrect gum confirm syntax. The script has been fixed to use proper gum command syntax.

### Script exits without creating file
Check that:
1. gum is installed (`command -v gum`)
2. `_posts` directory exists
3. You have write permissions to the `_posts` directory

### Editor doesn't open
Set the EDITOR environment variable:
```bash
export EDITOR=vim  # or your preferred editor
```
