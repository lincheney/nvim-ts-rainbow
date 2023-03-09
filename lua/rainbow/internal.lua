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

local parsers = require('nvim-treesitter.parsers')
local configs = require('nvim-treesitter.configs')
local highlighter = vim.treesitter.highlighter

local nsid = vim.api.nvim_create_namespace('rainbow_ns')

local rainbow_query = require('rainbow.query')
local colors = configs.get_module('rainbow').colors
local unmatched_color = configs.get_module('rainbow').unmatched_color
local priority = configs.get_module('rainbow').priority
local highlight_middle = configs.get_module('rainbow').highlight_middle

local state_table = {}

local LEFT = 1
local RIGHT = 2
local MIDDLE = 3
local SCOPE_LEFT = 4
local SCOPE_RIGHT = 5

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

local function finish_scope(scope, pool)
  -- recycle tables from the pool
  local scope_end = table.remove(pool) or {}
  scope_end.kind = scope.kind
  scope_end.type = SCOPE_RIGHT
  scope_end.matched = true
  if not scope_end.start then
    scope_end.start = {}
  end
  if not scope_end.finish then
    scope_end.finish = {}
  end
  scope_end.start[1], scope_end.start[2] = unpack(scope.finish)
  scope_end.finish[1], scope_end.finish[2] = unpack(scope.finish)
  -- scope start finishes at the start
  scope.finish[1], scope.finish[2] = unpack(scope.start)
  return scope_end
end

--- Update highlights for a range. Called every time text is changed.
--- @param bufnr number # Buffer number
--- @param tree table # Syntax tree
--- @param lang string # Language
--- @param pool of tables for reuse
local function update_range(bufnr, tree, lang, pool)
  if vim.fn.pumvisible() ~= 0 or not lang then
    return
  end

  -- load the query
  local query = rainbow_query.get_query(lang)
  if not query then
    return
  end

  local root = tree:root()

  -- invalidate everything for now
  -- figure out how to do damage later
  local items = {}

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
      local name, kind = query.captures[id]:match('^([^.]*)%.(.*)$')

      -- recycle tables from the pool
      local item = table.remove(pool) or {}
      item.kind = kind
      item.matched = false
      item.level = nil
      item.hl = nil
      if not item.start then
        item.start = {}
      end
      if not item.finish then
        item.finish = {}
      end
      item.start[1], item.start[2] = node:start()
      item.finish[1], item.finish[2] = node:end_()

      while #scopes > 0 and tuple_cmp(item.start, scopes[#scopes].finish) >= 0 do
        -- this scope has finished
        table.insert(items, finish_scope(table.remove(scopes), pool))
      end

      if name == 'left' then
        -- add to stack
        item.type = LEFT
        table.insert(stack, item)
        table.insert(items, item)

      elseif name == 'right' then
        -- find a matching opening bracket
        item.type = RIGHT
        for i = 0, #stack-1 do
          local x = stack[#stack-i]
          if x.kind == kind then
            x.matched = true
            item.matched = true
            -- pop off the stack
            for j = #stack-i, #stack do
              stack[j] = nil
            end
            break
          end
        end
        table.insert(items, item)

      elseif name == 'middle' then
          item.type = MIDDLE
          table.insert(items, item)

      elseif name == 'scope' then
        item.type = SCOPE_LEFT
        item.matched = true
        table.insert(scopes, item)
        table.insert(items, item)

      end

    end
  end

  for _, scope in ipairs(scopes) do
    table.insert(items, finish_scope(scope, pool))
  end

  -- set the level of each bracket, starting from 0
  local level = 0
  for _, item in ipairs(items) do
    if item.type == MIDDLE then -- TODO currently we do not check for the kind for middle nodes
      item.level = level
    elseif item.matched then
      if item.type == LEFT or item.type == SCOPE_LEFT then
        level = level + 1
        item.level = level
      elseif item.type == RIGHT or item.type == SCOPE_RIGHT then
        item.level = level
        level = level - 1
      end
    end
  end
  return items
end

local function need_invalidate(bufnr)
  local state = state_table[bufnr]

  if not state.items then
    -- first run
    return true

  elseif #state.changes > 0 then
    -- tree changes
    return true

  elseif #state.byte_changes > 0 and #state.items > 0 then
    -- we only care about byte changes if they make line changes OR we have brackets on the same row
    for _, change in ipairs(state.byte_changes) do
      local item = state.items[binsearch_items(state.items, change)]
      if item and (change[1] ~= change[3] or item.start[1] == change[1]) then
        return true
      end
    end

  end

  -- no changes
  return false
end

local function update_all_trees(bufnr, force)
  local invalidate = force or need_invalidate(bufnr)

  local state = state_table[bufnr]
  state.changes = {}
  state.byte_changes = {}
  if not invalidate then
    return
  end

  local num_trees = 0
  local pool = state.items or {}
  state.items = {}

  state.parser:for_each_tree(function(tree, sub_parser)
    local new_items = update_range(bufnr, tree, sub_parser:lang(), pool)
    if new_items then
      num_trees = num_trees + 1
      vim.list_extend(state.items, new_items)
    end
  end)

  -- don't need to sort if only 1 tree
  if num_trees > 1 then
    table.sort(state.items, function(x, y) return tuple_cmp(x.start, y.start) < 0 end)
  end
end

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
    byte_changes = {},
    items = nil,
    parser = parser,
  }

  parser:register_cbs({
    on_changedtree = function(changes, tree)
      if state_table[bufnr] then
        vim.list_extend(state_table[bufnr].changes, changes)
      end
    end,
    on_bytes = function(bufnr, tick, start_row, start_col, offset, old_end_row, old_end_col, old_len, end_row, end_col, len)
      -- sometimes there's no syntax/tree changes, but there are byte changes
      -- these can shift the positions of later brackets
      -- so we reparse in these cases
      if state_table[bufnr] then
        local change = {
          start_row + math.min(0, end_row-old_end_row),
          start_col + math.min(0, end_col-old_end_col),
          start_row + math.max(0, end_row-old_end_row),
          start_col + math.max(0, end_col-old_end_col),
        }
        table.insert(state_table[bufnr].byte_changes, change);
      end
    end,
  })
end

--- Detach module from buffer. Called when `:TSBufDisable rainbow`.
--- @param bufnr number # Buffer number
function M.detach(bufnr)
  state_table[bufnr] = nil
end

local function on_line(_, win, bufnr, row)
  if not state_table[bufnr] then
    return
  end

  if #colors == 0 then
    return
  end

  update_all_trees(bufnr)

  local items = state_table[bufnr].items
  local start, finish = get_items_in_range(items, {row-1, math.huge}, {row, math.huge})
  for i = start, finish-1 do
    local item = items[i]
    if item.type ~= MIDDLE or (item.level and highlight_middle) then

      if not item.hl then
        item.hl = unmatched_color
        if item.matched or item.type == MIDDLE then
          item.hl = colors[(item.level-1) % #colors + 1]
        end
      end

      vim.api.nvim_buf_set_extmark(bufnr, nsid, item.start[1], item.start[2], {
        end_line = item.finish[1],
        end_col = item.finish[2],
        hl_group = item.hl,
        ephemeral = true,
        priority = priority,
      })
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
