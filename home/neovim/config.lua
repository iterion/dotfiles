vim.g.mapleader = ","
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.spell = true
vim.opt.signcolumn = "auto"
vim.opt.clipboard = "unnamedplus"
vim.opt.wrap = false
vim.opt.completeopt = "menuone,fuzzy,noinsert,popup"
local lspconfig = require('lspconfig')
-- local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
lspconfig.nil_ls.setup{}
lspconfig.terraformls.setup{}
lspconfig.yamlls.setup {}
lspconfig.eslint.setup {}
lspconfig.zls.setup {}



require("typescript-tools").setup({
    on_attach = function(client, _)
	client.server_capabilities.documentFormattingProvider = false
    end,
})

local rt = require("rust-tools")

rt.setup({
  server = {
    on_attach = function(_, bufnr)
      -- Hover actions
      vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
      -- Code action groups
      vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
      vim.keymap.set("n", "<Leader>em", rt.expand_macro.expand_macro, { buffer = bufnr })
    end,
  },
})


vim.diagnostic.config({
  virtual_lines = true
})
vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})
--     local opts = {buffer = event.buf}
--
--     vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
--     vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
--     vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
--     vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
--     vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
--     vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
--     vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
--     vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
--     vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
--     vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
--
--     vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
--     vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
--     vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts) 
--   end
-- })

-- require('blink.cmp').setup({
--   sources = {
--     default = {'lsp', 'path', 'snippets', 'buffer'},
--   },
--   keymap = { preset = 'super-tab' },
  -- config = function(_, opts)
  --   local lspconfig = require('lspconfig')
  --   for server, config in pairs(opts.servers) do
  --     -- passing config.capabilities to blink.cmp merges with the capabilities in your
  --     -- `opts[server].capabilities, if you've defined it
  --     config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
  --     lspconfig[server].setup(config)
  --   end
  -- end
  -- mapping = cmp.mapping.preset.insert({
  --   -- Enter key confirms completion item
  --   ['<CR>'] = cmp.mapping.confirm({select = false}),
  --
  --   -- Ctrl + space triggers completion menu
  --   ['<C-Space>'] = cmp.mapping.complete(),
  -- }),
  -- snippet = {
  --   expand = function(args)
  --     require('luasnip').lsp_expand(args.body)
  --   end,
  -- },
-- })

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
