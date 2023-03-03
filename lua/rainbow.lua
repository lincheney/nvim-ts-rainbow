local M = {}

function M.init()
  require('nvim-treesitter').define_modules({
    rainbow = {
      module_path = 'rainbow.internal',
      is_supported = function(lang)
        return require('nvim-treesitter.query').get_query(lang, 'parens') ~= nil
      end,
      max_file_lines = nil,
      extended_mode = true,
      colors = {
        'rainbowcol1',
        'rainbowcol2',
        'rainbowcol3',
        'rainbowcol3',
      },
    },
  })
end

return M
