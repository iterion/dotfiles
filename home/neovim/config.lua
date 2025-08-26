vim.g.mapleader = ","
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.spell = true
vim.opt.signcolumn = "auto"
vim.opt.clipboard = "unnamedplus"
vim.opt.wrap = false
vim.opt.completeopt = "menuone,fuzzy,noinsert,popup"

-- use alejandra
vim.lsp.config('nil_ls', {
  cmd = { 'nil' },
  settings = {
    ['nil'] = {
      formatting = { command = { 'alejandra' } },
    },
  },
})

local function on_attach(client, bufnr)
  if vim.lsp.inlay_hint and client.server_capabilities.inlayHintProvider then
    pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
  end
  -- enable built-in completion autotrigger if supported
  if client:supports_method('textDocument/completion') then
    pcall(vim.lsp.completion.enable, true, client.id, bufnr, { autotrigger = true })
  end
end

local fmt_group = vim.api.nvim_create_augroup("LspAutoFormat", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = fmt_group,
  callback = function(args)
    local bufnr = args.buf
    local ft = vim.bo[bufnr].filetype

    if ft == "rust" then
      -- Use rustaceanvim’s formatter directly
      pcall(vim.cmd, "RustFmt")
      return
    end

    if ft == "javascript" or ft == "javascriptreact"
      or ft == "typescript" or ft == "typescriptreact" then
      pcall(vim.cmd, "LspEslintFixAll")
    end

    vim.lsp.buf.format({
      bufnr = bufnr,
      timeout_ms = 2000,
      filter = function(client)
        -- Only nil_ls formats Nix (alejandra)
        if ft == "nix" then
          return client.name == "nil_ls"
        end
        -- Never treat eslint as a formatter
        if client.name == "eslint" then
          return false
        end
        return client.supports_method("textDocument/formatting")
      end,
    })
  end,
})

-- Attach hook for any client started via vim.lsp.enable
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then on_attach(client, ev.buf) end
  end,
})

vim.lsp.enable({'nil_ls', 'terraformls', 'yamlls', 'eslint', 'zls'})

vim.g.rustaceanvim = {
  tools = {
    -- Make hover window behave nicely; set to true if you prefer auto focus.
    hover_actions = { auto_focus = false },
  },
  server = {
    on_attach = function(client, bufnr)
      -- Reuse your global LSP on_attach features (inlay hints, completion, etc.)
      if type(on_attach) == "function" then on_attach(client, bufnr) end

      local opts = { buffer = bufnr, silent = true }
      -- Rough equivalents to your rust-tools mappings:
      vim.keymap.set("n", "<C-space>", function() vim.cmd.RustLsp("hover", "actions") end, opts)
      vim.keymap.set("n", "<Leader>a", function() vim.cmd.RustLsp("codeAction") end, opts)
      vim.keymap.set("n", "<Leader>em", function() vim.cmd.RustLsp("expandMacro") end, opts)

      -- Optional quality-of-life:
      -- vim.keymap.set("n", "<Leader>rd", function() vim.cmd.RustLsp("openDocs") end, opts)
      -- vim.keymap.set("n", "<Leader>rt", function() vim.cmd.RustLsp("runnables") end, opts)
    end,
    default_settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        check = { command = "clippy" },
        -- formatting uses rustfmt via rust-analyzer; your global formatter will pick it up.
      },
    },
  },
}

require("typescript-tools").setup({})

vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})

vim.lsp.handlers["textDocument/hover"] =
  vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] =
  vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

-- Handy LSP keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local bufnr = ev.buf
    local opts = { buffer = bufnr, silent = true }
--     vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
--     vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
--     vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
--     vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
--     vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
--     vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
--     vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
--     vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "x" }, "<F3>", function() vim.lsp.buf.format({ async = true }) end, opts)
--     vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)
--     vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
--     vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
--     vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
  end,
})

vim.o.updatetime = 250
vim.lsp.log.set_level(vim.log.levels.WARN)

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
