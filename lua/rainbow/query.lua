local M = {}

local query_name = 'parens'
local fallback_queries = {'_square', '_curly', '_round', '_comma'}

local queries = {}
local query_strings = {}

local function load_query(name)
  if not query_strings[name] then
    local contents = {}
    for _, file in ipairs(vim.treesitter.query.get_files(name, query_name)) do
      table.insert(contents, table.concat(vim.fn.readfile(file), '\n'))
    end
    query_strings[name] = table.concat(contents, '\n')
  end
  return query_strings[name]
end

local default_query = nil
local function get_default_query()
  if not default_query then
    local contents = {}
    for _, name in ipairs(fallback_queries) do
      table.insert(contents, load_query(name))
    end
    default_query = table.concat(contents, '\n')
  end
  return default_query
end

function M.get_query(lang)
  if not queries[lang] then
    queries[lang] = vim.treesitter.query.get(lang, query_name)

    if not queries[lang] then
      local ok, query = pcall(vim.treesitter.query.parse, lang, get_default_query())
      if ok then
        queries[lang] = query
      end
    end

    if not queries[lang] then
      -- check one by one if square, curly, round work
      local working = {}
      for _, name in ipairs(fallback_queries) do
        if pcall(vim.treesitter.query.parse, lang, load_query(name)) then
          table.insert(working, load_query(name))
        end
      end

      if #working == 0 then
        return
      end

      queries[lang] = vim.treesitter.query.parse(lang, table.concat(working, '\n'))
    end
  end

  return queries[lang]
end

return M
