# Streamline

<div style="width: 100%;margin:auto;width:200px;">
<img src="./assets/streamline-logo-full.svg" alt="Streamline logo" width="200" />
</div>

## Welcome
Thank you for trying Streamline. I hope you find it useful. In this documentation, I hope to provide all the information you need to take full advantage of all of our features - from behavior logic, configuration options, hooks, recommended keybinds, and more.

## About Streamline
streamline.nvim is a buffer management plugin for Neovim that gives your open files a clear, visual, spatial, and navigable structure in a way similar to tabs, but designed for buffer-first workflows. Designed to reimagine how you work with buffers, streamline.nvim combines the spatial clarity of modern editors like VSCode with the raw power of Neovim’s buffer model.

## Quickstart
First, you will need to install the plugin. For example, if using lazy.nvim it may look something like:
```lua 
{
    "emcassi/streamline.nvim",
    name = "streamline",
    dev = true,
    config = function()
        require("streamline").setup({
        config = {
            default_insert_behavior = "end", -- "beginning", "end", "before", or "after"
        }})

        -- Set up keybinds here
        -- (Example)
        vim.keymap.set("n", "<leader>sb", ":StreamBuffers<CR>", { noremap = true })
        vim.keymap.set("n", "<A-n>", ":StreamNavForward<CR>", { noremap = true })
        vim.keymap.set("n", "<A-p>", ":StreamNavBackward<CR>", { noremap = true })
        vim.keymap.set("n", "<A-;>", ":StreamNavToPrevious<CR>", { noremap = true })

        for i = 1, 9 do
            vim.keymap.set("n", "<leader>" .. i, function()
                vim.cmd("StreamNavToIndex " .. i)
            end, { noremap = true, desc = "Jump to buffer " .. i })
        end

    end,
},
```

For a comprehensive list of all commands available, see [Commands](./commands.md)