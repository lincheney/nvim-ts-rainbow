local M = {}

function M.init()
  require('nvim-treesitter').define_modules({
    rainbow = {
      module_path = 'rainbow.internal',
      is_supported = function(lang)
        return require('rainbow.query').get_query(lang)
      end,
      max_file_lines = nil,
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

return M
