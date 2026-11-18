require("nvim-treesitter").setup()

      require("nvim-treesitter").install({
        "bash",
        "c",
        "cpp",
        "cmake",
        "css",
        "html",
        "javascript",
        "json",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "c_sharp"
      })

      -- Включаем Tree-sitter highlighting
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
