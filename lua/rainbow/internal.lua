--[[
   Copyright 2023 Cheney Lin
   Copyright 2020-2022 Chinmay Dalal

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
--]]

local M = {}

local queries = require('nvim-treesitter.query')
local parsers = require('nvim-treesitter.parsers')
local configs = require('nvim-treesitter.configs')
local api = vim.api
local highlighter = vim.treesitter.highlighter

local add_predicate = vim.treesitter.query.add_predicate
local nsid = vim.api.nvim_create_namespace('rainbow_ns')
local extended_languages = { 'latex', 'html', 'verilog', 'jsx' }
local colors = configs.get_module('rainbow').colors
local termcolors = configs.get_module('rainbow').termcolors

local state_table = {}

local function tuple_cmp(x, y)
  if     x[1] < y[1] then
    return -1
  elseif x[1] > y[1] then
    return 1
  elseif x[2] < y[2] then
    return -1
  elseif x[2] > y[2] then
    return 1
  else
    return 0
  end
end

local function range_overlap(x, y)
  return tuple_cmp(x, {y[3], y[4]}) < 0 and tuple_cmp(y, {x[3], x[4]}) < 0
end

local function binsearch_items(items, target, start)
  local start = start or 1
  local finish = #items
  local mid

  while start <= finish do
    mid = math.floor((start + finish) / 2)
    -- we are just comparing start ; is that good enough?
    local cmp = tuple_cmp(target, items[mid].start)
    if cmp < 0 then
      finish = mid - 1
    elseif cmp == 0 or tuple_cmp(target, items[mid].finish) < 0 then
      return mid, true
    else
      start = mid + 1
    end
  end
  return start
end

local function get_items_in_range(items, start, finish)
  local start = binsearch_items(items, start)
  local finish = binsearch_items(items, finish, start)
  return start, finish
end

--- Update highlights for a range. Called every time text is changed.
--- @param bufnr number # Buffer number
--- @param changes table # Range of text changes
--- @param tree table # Syntax tree
--- @param lang string # Language
--- Update highlights for a range. Called every time text is changed.
--- @param bufnr number # Buffer number
--- @param changes table # Range of text changes
--- @param tree table # Syntax tree
--- @param lang string # Language
local function update_range(bufnr, changes, tree, lang)
  if #changes == 0 then
    return
  end

  if vim.fn.pumvisible() ~= 0 or not lang then
    return
  end

  local root = tree:root()

  -- load the query
  local query = queries.get_query(lang, "parens")
  local items = state_table[bufnr].items[lang] or {}
  -- invalidate everything for now
  -- figure out how to do damage later
  items = {}

  local seen = {}
  local stack = {}
  local scopes = {}

  for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
    if node:has_error() then
    elseif seen[node:id()] then
      -- skip nodes we have already processed
      -- this can happen if a node is captured multiple times
    else
      seen[node:id()] = true
      local name = query.captures[id]:match('^[^.]*')
      local type = query.captures[id]:sub(#name+2)

      local item = {type=type, matched=false, start={node:start()}, finish={node:end_()}}

      if name == 'left' then
        -- add to stack
        item.open = true
        table.insert(stack, item)
        table.insert(items, item)

      elseif name == 'right' then
        -- find a matching opening bracket
        item.open = false
        local index
        for i = 0, #stack-1 do
          local x = stack[#stack-i]
          if x.type == type then
            x.matched = true
            item.matched = true
            stack = vim.list_slice(stack, 1, #stack-i-1)
            break
          end
        end
        table.insert(items, item)

      end

    end
  end

  -- set the level of each bracket, starting from 0
  local level = 0
  for _, item in ipairs(items) do
    if item.matched then
      if item.open then
        level = level + 1
        item.level = level
      else
        item.level = level
        level = level - 1
      end
    end
  end
  state_table[bufnr].items[lang] = items
end

--- Update highlights for every tree in given buffer.
--- @param bufnr number # Buffer number
local function full_update(bufnr)
  local parser = state_table[bufnr].parser
  parser:invalidate(true)
  parser:parse()
  parser:for_each_tree(function(tree, sub_parser)
    update_range(bufnr, { { tree:root():range() } }, tree, sub_parser:lang())
  end)
end

--- Register predicates for extended mode.
--- @param config table # Configuration for the `rainbow` module in nvim-treesitter
local function register_predicates(config)
  local extended_mode

  if type(config.extended_mode) == 'table' then
    extended_mode = {}
    for _, lang in pairs(config.extended_mode) do
      extended_mode[lang] = true
    end
  elseif type(config.extended_mode) == 'boolean' then
    extended_mode = config.extended_mode
  else
    vim.api.nvim_err_writeln('nvim-ts-rainbow: `extended_mode` can be a boolean or a table')
  end

  for _, lang in ipairs(extended_languages) do
    local enable_extended_mode
    if type(extended_mode) == 'table' then
      enable_extended_mode = extended_mode[lang]
    else
      enable_extended_mode = extended_mode
    end
    add_predicate(lang .. '-extended-rainbow-mode?', function()
      return enable_extended_mode
    end, true)
  end
end

--- Define highlight groups. This had to be a function to allow an autocmd doing this at colorscheme change.
function M.defhl()
  for i = 1, math.max(#colors, #termcolors) do
    local s = string.format('highlight default rainbowcol%d', i)
    if #colors > 0 then
      s = s .. ' guifg=' .. colors[(i % #colors == 0) and #colors or (i % #colors)]
    end
    if #termcolors > 0 then
      s = s .. ' ctermfg=' .. termcolors[(i % #termcolors == 0) and #termcolors or (i % #termcolors)]
    end
    vim.cmd(s)
  end
end

M.defhl()

--- Attach module to buffer. Called when new buffer is opened or `:TSBufEnable rainbow`.
--- @param bufnr number # Buffer number
--- @param lang string # Buffer language
function M.attach(bufnr, lang)
  local config = configs.get_module('rainbow')
  config = config or {}
  ---@diagnostic disable-next-line
  local max_file_lines = config.max_file_lines or 9999999
  if max_file_lines ~= nil and vim.api.nvim_buf_line_count(bufnr) > max_file_lines then
    return
  end

  -- register_predicates(config)
  local parser = parsers.get_parser(bufnr, lang)
  state_table[bufnr] = {
    changes = {},
    items = {},
    parser = parser,
  }
  parser:register_cbs({
    on_changedtree = function(changes, tree)
      if state_table[bufnr] then
        vim.list_extend(state_table[bufnr].changes, changes)
      end
    end,
    on_bytes = function(bufnr, tick, start_row, start_col, offset, old_end_row, old_end_col, old_len, end_row, end_col, len)
      if state_table[bufnr] then
        table.insert(state_table[bufnr].changes, {
          start_row + math.min(0, end_row-old_end_row),
          start_col + math.min(0, end_col-old_end_col),
          start_row + math.max(0, end_row-old_end_row),
          start_col + math.max(0, end_col-old_end_col),
        })
      end
    end,
  })
  full_update(bufnr)
end

--- Detach module from buffer. Called when `:TSBufDisable rainbow`.
--- @param bufnr number # Buffer number
function M.detach(bufnr)
  state_table[bufnr] = nil
  ---@diagnostic disable-next-line
  if vim.treesitter.highlighter.hl_map then
    ---@diagnostic disable-next-line
    vim.treesitter.highlighter.hl_map['punctuation.bracket'] = 'TSPunctBracket' -- luacheck: ignore
  else
    vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'TSPunctBracket' })
  end
end

local function on_line(_, win, bufnr, row)
  if not state_table[bufnr] then
    return
  end

  if #state_table[bufnr].changes > 0 then
    state_table[bufnr].parser:for_each_tree(function(tree, sub_parser)
      update_range(bufnr, state_table[bufnr].changes, tree, sub_parser:lang())
    end)
    state_table[bufnr].changes = {}
  end

  local size = #configs.get_module('rainbow').colors
  for lang, items in pairs(state_table[bufnr].items) do
    local start, finish = get_items_in_range(items, {row, 0}, {row+1, 0})
    for i = start, finish-1 do
      local item = items[i]
      if true then -- TODO

        if not item.hl then
          item.hl = 'Error'
          if item.matched then
            item.hl = 'rainbowcol'..tostring((item.level-1) % size + 1)
          end
        end

        vim.api.nvim_buf_set_extmark(bufnr, nsid, item.start[1], item.start[2], {
          end_line = item.finish[1],
          end_col = item.finish[2],
          hl_group = item.hl,
          ephemeral = true,
          priority = 1000,
        })
      end
    end
  end
end

vim.api.nvim_set_decoration_provider(nsid, {
  on_win = function(_, winnr, bufnr, topline, botline_guess)
    return state_table[bufnr] and true
  end,
  on_line = on_line,
  on_buf = function(_, bufnr)
    -- if we are using treesitter highlighting, it will do this for us
    -- otherwise, we have to do it
    if state_table[bufnr] and not highlighter.active[bufnr] then
      state_table[bufnr].parser:parse()
    end
  end,
})

return M
