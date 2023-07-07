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
  init()
end

local function wrapper(name)
  return function(bufnr, ...)
    if not bufnr or bufnr == 0 then
      bufnr = vim.api.nvim_get_current_buf()
    end
    return require('rainbow.internal')[name](bufnr, ...)
  end
end

M.get_matches = wrapper('get_matches')
M.get_matches_at_pos = wrapper('get_matches_at_pos')
local attach = wrapper('attach')
function M.attach(bufnr)
  return attach(bufnr, nil, config)
end
M.detach = wrapper('detach')
M.update = wrapper('update')

return M
