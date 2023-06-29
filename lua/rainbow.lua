local M = require('rainbow.constants')

local config = {
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
  ignore_syntax = {Comment=true, String=true, shSnglCase=true},
  syn_maxlines = 500,

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

local started = false
local function init()
  if started then
    return
  end
  started = true
  vim.api.nvim_create_autocmd('FileType', {callback=function(args)
    M.attach(args.buf)
  end})
  for _, item in ipairs(vim.fn.getbufinfo{bufloaded=true}) do
    M.attach(item.bufnr)
  end
end

function M.setup(opts)
  for k, v in pairs(opts) do
    config[k] = v
  end
  if type(config.enable) == 'table' then
    local enable = config.enable
    config.enable = function(buf, ft) return vim.tbl_contains(enable, ft) end
  end
  if type(config.treesitter_enable) == 'table' then
    local treesitter_enable = config.treesitter_enable
    config.treesitter_enable = function(buf, ft) return vim.tbl_contains(treesitter_enable, ft) end
  end
  if #config.ignore_syntax > 0 then
    for k, v in ipairs(config.ignore_syntax) do
      config.ignore_syntax[k] = nil
      config.ignore_syntax[v] = true
    end
  end
  init()
end

function M.get_matches(...)
  return require('rainbow.internal').get_matches(...)
end

function M.get_matches_at_pos(...)
  return require('rainbow.internal').get_matches_at_pos(...)
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

function M.update(bufnr)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  return require('rainbow.internal').update(bufnr)
end

return M
