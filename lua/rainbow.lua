local M = require('rainbow.constants')

local config = {
  max_file_lines = 9999999,
  highlight_middle = true,
  priority = 200,
  colors = {
    'RainbowCol1',
    'RainbowCol2',
    'RainbowCol3',
    'RainbowCol4',
  },
  unmatched_color = 'RainbowColUnmatched',
  enable = nil,
  treesitter_enable = nil,

  matchers = {
    [''] = {
      ['('] = {M.LEFT, 'round', {right=')'}},
      [')'] = {M.RIGHT, 'round'},
      ['['] = {M.LEFT, 'square', {right=']'}},
      [']'] = {M.RIGHT, 'square'},
      ['{'] = {M.LEFT, 'curly', {right='}'}},
      ['}'] = {M.RIGHT, 'curly'},
      [','] = {M.MIDDLE, 'comma'},
    }
  },
  additional_matchers = {},

  -- treesitter things
  module_path = 'rainbow.internal',
  is_supported = function(lang)
    return require('rainbow.query').get_query(lang) and true
  end,
}

function M.setup(opts)
  for k, v in pairs(opts) do
    config[k] = v
  end
  if type(config.enable) == 'table' then
    config.enable = function(buf, ft) return vim.tbl_contains(config.enable, ft) end
  end
  if type(config.treesitter_enable) == 'table' then
    config.treesitter_enable = function(buf, ft) return vim.tbl_contains(config.treesitter_enable, ft) end
  end
end

function M.init()
  vim.api.nvim_create_autocmd('FileType', {callback=function(args)
    M.attach(args.buf, args.match, config)
  end})
  for _, item in ipairs(vim.fn.getbufinfo{bufloaded=true}) do
    M.attach(item.bufnr, nil, config)
  end
end

function M.get_matches(...)
  return require('rainbow.internal').get_matches(...)
end

function M.attach(bufnr)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  return require('rainbow.internal').attach(bufnr, nil, config)
end

function M.detach(bufnr)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  return require('rainbow.internal').detach(bufnr)
end

return M
