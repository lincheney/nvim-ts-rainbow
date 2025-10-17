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

local rainbow_query = require('rainbow.query')
local nsid = vim.api.nvim_create_namespace('rainbow_ns')

local state_table = {}
local CONSTANTS = require('rainbow.constants')

local function get_lang(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  return vim.treesitter.language.get_lang(ft) or ft
end

local function get_parser(bufnr, lang)
  lang = lang or get_lang(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if ok then
    return parser
  end
end

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

local function clear_table(tbl)
  for i = #tbl, 1, -1 do
    tbl[i] = nil
  end
end

local function range_overlap(x, y)
  return tuple_cmp(x, {y[3], y[4]}) < 0 and tuple_cmp(y, {x[3], x[4]}) < 0
end

local function binsearch_items(items, target, start)
  -- find the smallest index such that it is >= target
  start = start or 1
  local finish = #items
  local mid

  while start <= finish do
    mid = math.floor((start + finish) / 2)
    local cmp = tuple_cmp(target, items[mid].start)
    if cmp < 0 then
      finish = mid - 1
    elseif cmp == 0 or tuple_cmp(target, items[mid].finish) < 0 then
      -- there may be more that match, find the first one
      for i = mid-1, start, -1 do
        if tuple_cmp(target, items[i].start) < 0 or tuple_cmp(target, items[i].finish) >= 0 then
          break
        end
        mid = i
      end
      return mid, true
    else
      start = mid + 1
    end
  end
  return start
end

local function get_items_in_range(items, start, finish)
  -- end inclusive
  local i = binsearch_items(items, start)
  -- find the largest index that is <= finish
  local j = binsearch_items(items, finish, i) - 1
  while items[j+1] and tuple_cmp(items[j+1].start, finish) <= 0 do
    j = j + 1
  end
  return i, j
end

local function recycle_from_pool(pool)
  return {}
  -- since most items are not recyclable, it is actually slower to find one
  -- while #pool > 0 do
    -- local val = table.remove(pool)
    -- if val and val.recyclable then
      -- return val
    -- end
  -- end
  -- return {recyclable = true}
end

local function finish_scope(scope, pool)
  -- recycle tables from the pool
  local scope_end = recycle_from_pool(pool)
  scope_end.tree_num = scope.tree_num
  scope_end.kind = scope.kind
  scope_end.type = CONSTANTS.SCOPE_RIGHT
  scope_end.metadata = scope.metadata
  scope_end.matched = scope
  scope.matched = scope_end
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
local function parse_matches(bufnr, nodes, pool, tree_num)
  -- invalidate everything for now
  -- figure out how to do damage later
  local items = {}
  local stack = {}
  local scopes = {}

  for _, node in ipairs(nodes) do
    local type = node.type
    local kind = node.kind

    -- recycle tables from the pool
    local item = node
    -- local item = table.remove(pool) or {}
    -- item.type = type
    item.tree_num = tree_num
    -- item.kind = kind
    item.parent = nil
    item.matched = false
    item.level = nil
    item.hl = nil
    -- item.metadata = node.metadata
    -- if not item.start then
      -- item.start = {}
    -- end
    -- if not item.finish then
      -- item.finish = {}
    -- end
    -- item.start[1] = node.start[1]
    -- item.start[2] = node.start[2]
    -- item.finish[1] = node.finish[1]
    -- item.finish[2] = node.finish[2]

    while #scopes > 0 and tuple_cmp(item.start, scopes[#scopes].finish) >= 0 do
      -- this scope has finished
      table.insert(items, finish_scope(table.remove(scopes), pool))
    end

    if type == CONSTANTS.LEFT then
      -- add to stack
      table.insert(stack, item)
      table.insert(items, item)

    elseif type == CONSTANTS.RIGHT then
      -- find a matching opening bracket
      for i = #stack, 1, -1 do
        local x = stack[i]
        if x.kind == kind then
          x.matched = item
          item.matched = x
          -- pop off the stack
          for j = #stack, i, -1 do
            stack[j] = nil
          end
          break
        end
      end
      table.insert(items, item)

    elseif type == CONSTANTS.MIDDLE then
      table.insert(items, item)

    elseif type == CONSTANTS.SCOPE_LEFT then
      -- need a clone of the finish as it gets modified
      local scope = recycle_from_pool(pool)
      for k, v in pairs(item) do
        scope[k] = v
      end
      scope._node = node
      scope.start = {unpack(scope.start)}
      scope.finish = {unpack(scope.finish)}
      scope.matched = true
      table.insert(scopes, scope)
      table.insert(items, scope)

    end

  end

  for i = #scopes, 1, -1 do
    table.insert(items, finish_scope(scopes[i], pool))
  end

  -- clear stack
  clear_table(stack)

  -- set the level of each bracket, starting from 0
  local level = 0
  for _, item in ipairs(items) do
    item.parent = stack[#stack]
    if item.type == CONSTANTS.MIDDLE then -- TODO currently we do not check for the kind for middle nodes
      item.level = level
    elseif item.matched then
      if item.type == CONSTANTS.LEFT or item.type == CONSTANTS.SCOPE_LEFT then
        level = level + 1
        item.level = level
        stack[#stack+1] = item
      elseif item.type == CONSTANTS.RIGHT or item.type == CONSTANTS.SCOPE_RIGHT then
        item.level = level
        item.parent = item.matched.parent
        level = level - 1
        stack[#stack] = nil
      end
    end
  end
  return items
end

local function get_nodes(bufnr, tree, lang, range, nodes, tree_num)
  if not lang then
    return
  end

  -- load the query
  local query = rainbow_query.get_query(lang)
  if not query then
    return
  end

  local root = tree:root()
  local seen = {}

  local type_map = {left=CONSTANTS.LEFT, right=CONSTANTS.RIGHT, middle=CONSTANTS.MIDDLE, scope=CONSTANTS.SCOPE_LEFT}
  local old_nodes = nodes[tree_num]
  local new_nodes = {}

  for id, node, metadata in query:iter_captures(root, bufnr, range[1], range[2]) do
    if node:missing() then
    elseif seen[node:id()] then
      -- skip nodes we have already processed
      -- this can happen if a node is captured multiple times
      -- merge any new metadata in
      local m = seen[node:id()]
      for k, v in pairs(metadata) do
        m[k] = v
      end
    else
      seen[node:id()] = metadata
      local name, kind = query.captures[id]:match('^([^.]*)%.([^.]*)')
      local start_row, start_col = node:start()
      local end_row, end_col = node:end_()
      if metadata[id] then
        -- capture specific metadata
        metadata = vim.deepcopy(metadata)
        for k, v in pairs(metadata[id]) do
          metadata[k] = v
        end
      end

      table.insert(new_nodes, {
          type = type_map[name],
          kind = kind,
          metadata = metadata,
          start = {start_row, start_col},
          finish = {end_row, end_col},
          node_id = node:id(),
      })
    end
  end

  if #new_nodes == 0 then
    return
  end
  if not old_nodes or #old_nodes == 0 then
    nodes[tree_num] = new_nodes
    return
  end

  local merged = {}
  local j = 1
  for i, new in ipairs(new_nodes) do
    while j <= #old_nodes do
      local old = old_nodes[j]

      if tuple_cmp(old.start, new.start) == 0 and tuple_cmp(old.finish, new.finish) == 0 then
      -- if old.node_id == new.node_id then
        -- remove duplicates
        j = j + 1
        break
      end

      local cmp = tuple_cmp(new.start, old.start)
      if cmp < 0 or (cmp == 0 and tuple_cmp(new.finish, old.finish) > 0) then
        -- new comes first
        break
      end

      table.insert(merged, old)
      j = j + 1
    end
    table.insert(merged, new)
  end
  vim.list_extend(merged, old_nodes, j)
  nodes[tree_num] = merged
end

local function process_on_bytes(state, args)
  local type, start_row, start_col, offset, old_end_row, old_end_col, old_len, end_row, end_col, len = unpack(args)

  if old_end_row == 0 then
    old_end_col = start_col + old_end_col
  end
  if end_row == 0 then
    end_col = start_col + end_col
  end
  local line_shift = end_row - old_end_row
  local col_shift = end_col - old_end_col
  local start = {start_row, start_col}
  local finish = {start_row + old_end_row, old_end_col}
  local new_finish = {start_row + end_row, end_col}

  local needs_change = false
  local function callback(item)
    if tuple_cmp(item.start, start) >= 0 then

      -- if items is in changed range, register change
      if tuple_cmp(item.finish, finish) <= 0 then
        if not needs_change then
          needs_change = true
          table.insert(state.changes, {start_row, start_row + end_row + 1})
        end
        -- these don't matter?
        item.start = {start[1], start[2]}
        item.finish = {start[1], start[2]+1}

      else
        local old_start_row = item.start[1]
        local old_finish_row = item.finish[1]

        if tuple_cmp(item.start, finish) >= 0 then
          item.start[1] = item.start[1] + line_shift
        elseif tuple_cmp(item.start, new_finish) >= 0 then
          item.start = {new_finish[1], new_finish[2]}
        end
        item.finish[1] = item.finish[1] + line_shift

        -- shift columns
        if old_start_row == finish[1] then
          item.start[2] = item.start[2] + col_shift
        end
        if old_finish_row == finish[1] then
          item.finish[2] = item.finish[2] + col_shift
        end
      end

    end
  end

  -- shift some
  for _, item in ipairs(state.items) do
    if item._node then
      callback(item)
    end
  end
  -- also shift any nodes that do not have highlights
  for _, nodes in pairs(state.nodes) do
    for _, item in ipairs(nodes) do
      callback(item)
    end
  end

  -- also need to shift all other changes
  -- do i need this?
  local shift = 0
  for i, change in ipairs(state.changes) do

    if shift > 0 then
      -- cover up a deleted item
      state.changes[i - shift] = change
      state.changes[i] = nil
    end

    if change[1] >= start_row + old_end_row then
      -- after the change but no overlap
      change[1] = change[1] + line_shift
      change[2] = change[2] + line_shift

    elseif change[2] > start_row then
      -- overlap
      local left_overlap = change[1] <= start_row
      local right_overlap = start_row + old_end_row < change[2]

      if left_overlap or right_overlap then

        if left_overlap then
          -- change[1] = change[1]
        elseif right_overlap then
          change[1] = start_row + end_row
        end

        if right_overlap then
          change[2] = change[2] + line_shift
        elseif left_overlap then
          change[2] = start_row + 1
        end

      else
        state.changes[i] = nil
        shift = shift + 1

      end

    end

  end


end

local function process_on_changedtree(state, args)
  local type, changes = unpack(args)
  local change_start = math.huge
  local change_finish = 0
  for _, change in ipairs(changes) do
    change_start = math.min(change_start, change[1])
    change_finish = math.max(change_finish, change[4] + 1)
  end
  if change_start < change_finish then
    table.insert(state.changes, {change_start, change_finish})
  end
end

local function process_change_queue(state)
  for _, args in ipairs(state.queue) do
    if args[1] == 'on_bytes' then
      process_on_bytes(state, args)
    elseif args[1] == 'on_changedtree' then
      process_on_changedtree(state, args)
    end
  end
  clear_table(state.queue)
end

local function need_invalidate(bufnr)
  local state = state_table[bufnr]

  if not state.items then
    -- first run
    return {0, -1}
  end

  process_change_queue(state)
  if #state.changes > 0 then

    -- get a range encompasing all pending ranges
    local range = {math.huge, 0}
    for _, change in ipairs(state.changes) do
      if change[1] and range[1] > change[1] then
        range[1] = change[1]
      end
      if change[2] and range[2] < change[2] then
        range[2] = change[2]
      end
    end

    if range[1] >= range[2] then
      -- invalid range
      return
    end

    -- find the max range across items
    for _ = 1, 2 do
      for _, item in ipairs(state.items) do
        if tuple_cmp(item.start, {range[2], 0}) < 0 and tuple_cmp(item.finish, {range[1], 0}) > 0 then
          range[1] = math.min(range[1], item.start[1])
          range[2] = math.max(range[2], item.finish[1]+1)
          if item.matched then
            range[1] = math.min(range[1], item.matched.start[1])
            range[2] = math.max(range[2], item.matched.finish[1]+1)
          end
        end
      end
    end

    return range

  end

  -- no changes
  return false
end

function M.update(bufnr, force)
  if not state_table[bufnr] or vim.fn.pumvisible() ~= 0 then
    return
  end

  local state = state_table[bufnr]
  local pool = nil
  if force then
    pool = state.items
    state.items = nil
  end
  local invalidate_range = need_invalidate(bufnr)
  clear_table(state.changes)

  if not invalidate_range then
    return
  end

  -- delete nodes in that invalidate_range
  if invalidate_range[1] == 0 and invalidate_range[2] == -1 then
    clear_table(state.nodes)
  else
    local range_start = {invalidate_range[1], 0}
    local range_end = {invalidate_range[2], 0}
    for _, nodes in pairs(state.nodes) do
      local shift = 0
      for i, node in ipairs(nodes) do
        if tuple_cmp(node.start, range_end) < 0 and tuple_cmp(node.finish, range_start) > 0 then
          shift = shift + 1
          nodes[i] = nil
        elseif shift > 0 then
          nodes[i - shift] = node
          nodes[i] = nil
        end
      end
    end
  end

  pool = pool or state.items or {}
  state.items = {}
  state.nodes = state.nodes or {}

  local tree_num = 0
  state.parser:for_each_tree(function(tree, sub_parser)
    tree_num = tree_num + 1
    local lang = sub_parser:lang()
    get_nodes(bufnr, tree, lang, invalidate_range, state.nodes, tree_num)
  end)

  local num_parsed_trees = 0
  for k, v in pairs(state.nodes) do
    if #v > 0 then
      local items = parse_matches(bufnr, v, pool, k)
      vim.list_extend(state.items, items)
      num_parsed_trees = num_parsed_trees + 1
    end
  end

  -- don't need to sort if only 1 tree
  if num_parsed_trees > 1 then
    table.sort(state.items, function(x, y)
      local cmp = tuple_cmp(x.start, y.start)
      if cmp == 0 then
        return x.tree_num < y.tree_num
      else
        return cmp < 0
      end
    end)
  end
end

--- Attach module to buffer. Called when new buffer is opened or `:TSBufEnable rainbow`.
--- @param bufnr number # Buffer number
--- @param lang string # Buffer language
function M.attach(bufnr, lang, config)
  lang = lang or get_lang(bufnr)
  if state_table[bufnr] then
    if state_table[bufnr].lang == lang then
      return true
    end
    M.detach(bufnr)
  end

  if config.enable and not config.enable(bufnr, lang) then
    M.detach(bufnr)
    return false
  end

  local parser = get_parser(bufnr, lang)
  if not parser or not rainbow_query.get_query(lang) then
    M.detach(bufnr)
    return false
  end

  state_table[bufnr] = {
    lang = lang,
    changes = {},
    queue = {},
    items = nil,
    nodes = {},
    parser = parser,
    config = config,
    hl_cache = {},
  }
  local state = state_table[bufnr]

  local on_bytes = function(bufnr, tick, start_row, start_col, offset, old_end_row, old_end_col, old_len, end_row, end_col, len)
    if state_table[bufnr] ~= state then
      -- detach
      return true
    end
    table.insert(state.queue, {'on_bytes', start_row, start_col, offset, old_end_row, old_end_col, old_len, end_row, end_col, len})
  end

  parser:register_cbs({
    on_changedtree = function(changes, tree)
      if #changes == 0 or state_table[bufnr] ~= state then
        return
      end
      table.insert(state.queue, {'on_changedtree', changes})
    end,
    on_bytes = on_bytes,
  }, true)

  vim.api.nvim_create_autocmd('BufReadPost', {buffer=bufnr, callback=function()
    if state_table[bufnr] == state then
      M.detach(bufnr)
      M.attach(bufnr, nil, state.config)
    else
      -- detach
      return true
    end
  end})

  return true
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
  local config = state_table[bufnr].config

  if #config.colors == 0 then
    return
  end

  M.update(bufnr)

  local lang = state_table[bufnr].lang
  local items = state_table[bufnr].items
  -- local start, finish = get_items_in_range(items, {row-1, math.huge}, {row, math.huge})
  for i = 1, #items do
    local item = items[i]
    if item.start[1] <= row
      and item.finish[1] >= row
      and (item.type ~= CONSTANTS.MIDDLE or (item.level and config.highlight_middle))
      and not (item.metadata and item.metadata.no_highlight)
    then

      if not item.hl then
        item.hl = config.unmatched_color
        if item.matched or item.type == CONSTANTS.MIDDLE then
          item.hl = config.colors[(item.level-1) % #config.colors + 1]
        end
        if item.hl:sub(1, 1) == '@' then
          item.hl = item.hl .. '.' .. lang
        end
      end

      vim.api.nvim_buf_set_extmark(bufnr, nsid, item.start[1], item.start[2], {
        end_line = item.finish[1],
        end_col = item.finish[2],
        hl_group = item.hl,
        ephemeral = true,
        priority = config.priority,
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
    if state_table[bufnr] and state_table[bufnr].parser then
      state_table[bufnr].parser:parse()
    end
  end,
})

function M.get_matches(bufnr, start, finish)
  if not state_table[bufnr] then
    return
  end
  start = start or {-1, math.huge}
  finish = finish or {math.huge, math.huge}
  local items = state_table[bufnr].items
  start, finish = get_items_in_range(items, start, finish)

  return vim.list_slice(items, start, finish)
end

function M.get_matches_at_pos(bufnr, pos)
  if not state_table[bufnr] then
    return
  end
  local items = state_table[bufnr].items
  local idx = binsearch_items(items, pos)
  local matches = {}
  for i = idx, #items do
    if tuple_cmp(items[i].start, pos) <= 0 and tuple_cmp(pos, items[i].finish) <= 0 then
      table.insert(matches, items[i])
    end
  end
  return matches
end

return M
