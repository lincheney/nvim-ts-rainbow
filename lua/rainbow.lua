local M = require('rainbow.constants')

function M.init()
  require('nvim-treesitter').define_modules({
    rainbow = {
      module_path = 'rainbow.internal',
      is_supported = function(lang)
        return require('rainbow.query').get_query(lang) and true
      end,
      max_file_lines = nil,
      highlight_middle = true,
      priority = 200,
      colors = {
        'RainbowCol1',
        'RainbowCol2',
        'RainbowCol3',
        'RainbowCol4',
      },
      unmatched_color = 'RainbowColUnmatched',
    },
  })
end

function M.get_matches(...)
  return require('rainbow.internal').get_matches(...)
end

return M
