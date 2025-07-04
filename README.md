# streamline.nvim
<img src="./docs/assets/streamline-logo-full.svg" alt="Streamline logo" width="200" />

*Your buffers, beautifully organized. A smarter, smoother way to navigate, reorder, and manage buffers in Neovim.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/emcassi/streamline.nvim)
![GitHub Repo stars](https://img.shields.io/github/stars/emcassi/streamline.nvim)

## Overview

streamline.nvim is a buffer management plugin for Neovim that gives your open files a clear, visual, and navigable structure — just like tabs, but smarter.
Designed to reimagine how you work with buffers, streamline.nvim combines the spatial clarity of modern editors like VSCode with the raw power of Neovim’s buffer model.

It provides:

- An ordered buffer list decoupled from Vim’s internal buffer numbers
- Intuitive navigation and reordering of buffers (←/→ like browser tabs)
- A clean, optional UI buffer bar (tabline, side panel, or floating)
- Extensible APIs for integration and customization

## Installation
Currently, this plugin is recommended to be set up as a dev plugin. For example, with lazy.nvim, it may look something like this:

```lua
{
  "emcassi/streamline.nvim",
  dev = true,
  config = function()
    require("streamline").setup()
  end
}

```

## Status
streamline.nvim is currently in pre-release development (MVP stage).  
Basic buffer tracking is implemented — reordering, commands, and UI are actively being developed.


## Motivation

Neovim’s buffer system is powerful but invisible. By default:

- Buffers have no visual presence
- Users rely on commands like :bnext or plugins like Telescope
- There’s no intuitive spatial model for navigating open files

### This plugin was born out of daily friction:

“Which buffers do I have open? Why doesn’t :b2 go to the second file I opened? Why is buffer switching so unpredictable?”

**We’re fixing that.**
## Goals

- Give buffers a predictable order and visual identity
- Let users navigate like they would tabs — forward/backward or by position
- Provide custom insertion behaviors for new buffers
- Support reordering and pinning via commands or UI
- Keep the core lightweight and UI-agnostic
- Stay keyboard-first, but embrace optional mouse support
- Keep neovim performant even with a large number of open buffers.

## Core Concepts
### Custom Buffer List
- Maintains your buffers in an ordered table
- Tracks active buffer index
- Ignores hidden/special buffers by default

### 🗂 Buffer Bar (UI, optional)
- Shows buffer order with active highlight
- Clickable (when enabled)
- Display file names, filetypes, icons (via nvim-web-devicons)

### Navigation & Reordering
- :BufferNext, :BufferPrev, :BufferGo 3, :BufferMoveLeft, etc.
- :BufferPin, :BufferUnpin
- Configurable keymaps

### Configurable Behavior

```lua
require("streamline").setup({
    insert_behavior = "after_current", -- or "end"
    ui = {
        enabled = true,
        position = "top", -- or "bottom", "left", "right"
    }
})
--  This enables the UI and places it at the top of the screen.
```

### Keymaps
We understand keybinds are a deeply personal workflow decision. As such, streamline.nvim does not assign any keybinds by default. If you want to set up keybinds, here are the available commands along with some recommendations for keybind ideas.

Commands: 
- :StreamBuffers (Show all buffers via vim.notify)
- TODO
- Fill
- Out
- All
- Future
- Commands


```lua 
{
    "streamline.nvim",
    dir = "/path/to/streamline", -- If using local version 
    name = "streamline",
    dev = true,
    config = function()
        require("streamline").setup()
        vim.keymap.set("n", "<leader>sb", ":StreamBuffers<CR>", { noremap = true })
    end,
},
```

## Planned Features

| Feature                      | MVP | Polish |
| ---------------------------- | --- | ------ |
| Ordered buffer list          | ✅   |        |
| Navigation by position/index | ✅   |        |
| Reordering buffers           | ✅   |        |
| Custom insert behavior       | ⬜   |        |
| Optional UI tabline          | ⬜   |        |
| Buffer pinning               |     | ⬜      |
| Named/hidden buffers         |     | ⬜      |
| Session persistence          |     | ⬜      |
| Mouse support                |     | ⬜      |
| Telescope integration        |     | ⬜      |

## Use Cases
### Mental Model Clarity
Replace invisible buffer juggling with a clear left-to-right (or top-down) flow.

### Efficient Navigation
Jump directly to the 3rd buffer, not :b17.

### Workspace Structure
Use pinned/named buffers to anchor sessions:
- main.py always 1st

## Why It Matters
- New users: Makes buffer usage less cryptic
- Intermediate users: Offers predictability + polish
- Power users: Combine with Telescope, LSP, treesitter, etc
- Plugin authors: Simple public API for buffer awareness

## Architecture Plan
### Phase 1: Core Engine
- Buffer list tracking
- Navigation + reordering
- Config loader
- Extensibility API

### Phase 2: UI Layer
- Pluggable renderers (tabline/floating)
- Mouse interactions
- Theme support

### Phase 3: Integrations & Extras
- Session state saving
- Named buffers

## Philosophy

This plugin is built to embody design values such as:
- Clear structure
- Smooth ergonomics
- Extensibility-first.

*Whether you’re a keyboard minimalist or a mouse-friendly power user, streamline.nvim is here to make Neovim a joy to use — one buffer at a time.*

## Contributing & Feedback
🚧 streamline.nvim is under active development.

### Have ideas, feature requests, or feedback?  
👉 [Open an issue](https://github.com/emcassi/streamline.nvim/issues) or ⭐ the repo to follow progress.
