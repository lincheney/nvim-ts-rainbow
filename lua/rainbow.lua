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
    config.enable = function(ft) return vim.tbl_contains(config.enable, ft) end
  end
end

function M.init()
  vim.api.nvim_create_autocmd('FileType', {callback=function(args)
    local ft = args.match
    if config.enable and not config.enable(ft, args.buf) then
      M.detach(args.buf)
    else
      M.attach(args.buf, ft, config)
    end
  end})
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
