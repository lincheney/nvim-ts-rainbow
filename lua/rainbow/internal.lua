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
  local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype'):match('[^.]*')
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
  scope_end.tree_num = scope.tree_num
  scope_end.kind = scope.kind
  scope_end.type = CONSTANTS.SCOPE_RIGHT
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
local function parse_matches(bufnr, iterator, pool, tree_num)
  -- invalidate everything for now
  -- figure out how to do damage later
  local items = {}
  local stack = {}
  local scopes = {}

  iterator(function(type, kind, metadata, start_row, start_col, end_row, end_col)
    -- recycle tables from the pool
    local item = table.remove(pool) or {}
    item.type = type
    item.tree_num = tree_num
    item.kind = kind
    item.matched = false
    item.level = nil
    item.hl = nil
    item.metadata = metadata and next(metadata) and metadata or nil
    if not item.start then
      item.start = {}
    end
    if not item.finish then
      item.finish = {}
    end
    item.start[1] = start_row
    item.start[2] = start_col
    item.finish[1] = end_row
    item.finish[2] = end_col

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
      for i = 0, #stack-1 do
        local x = stack[#stack-i]
        if x.kind == kind then
          x.matched = item
          item.matched = x
          -- pop off the stack
          for j = #stack-i, #stack do
            stack[j] = nil
          end
          break
        end
      end
      table.insert(items, item)

    elseif type == CONSTANTS.MIDDLE then
      table.insert(items, item)

    elseif type == CONSTANTS.SCOPE_LEFT then
      item.matched = true
      table.insert(scopes, item)
      table.insert(items, item)

    end

  end)

  for _, scope in ipairs(scopes) do
    table.insert(items, finish_scope(scope, pool))
  end

  -- set the level of each bracket, starting from 0
  local level = 0
  for _, item in ipairs(items) do
    if item.type == CONSTANTS.MIDDLE then -- TODO currently we do not check for the kind for middle nodes
      item.level = level
    elseif item.matched then
      if item.type == CONSTANTS.LEFT or item.type == CONSTANTS.SCOPE_LEFT then
        level = level + 1
        item.level = level
      elseif item.type == CONSTANTS.RIGHT or item.type == CONSTANTS.SCOPE_RIGHT then
        item.level = level
        level = level - 1
      end
    end
  end
  return items
end

local function get_treesitter_iterator(bufnr, tree, lang)
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
  return function(callback)
    for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
      if node:has_error() then
      elseif seen[node:id()] then
        -- skip nodes we have already processed
        -- this can happen if a node is captured multiple times
      else
        seen[node:id()] = true
        local name, kind = query.captures[id]:match('^([^.]*)%.(.*)$')
        local start_row, start_col = node:start()
        local end_row, end_col = node:end_()
        callback(type_map[name], kind, metadata, start_row, start_col, end_row, end_col)
      end
    end
  end
end

local syn_name_cache = {}
local function get_syn_name(bufnr, row, col)
  local id = vim.fn.synID(row, col, 1)
  if not syn_name_cache[id] then
    syn_name_cache[id] = vim.fn.synIDattr(vim.fn.synIDtrans(id), 'name')
  end
  return syn_name_cache[id]
end

local function get_buffer_visible_syn_range(bufnr, offset)
  local state = state_table[bufnr]

  local bufinfo = vim.fn.getbufinfo(bufnr)[1]
  local minline = math.huge
  local maxline = 0

  for _, winid in ipairs(bufinfo.windows) do
    local window = vim.fn.getwininfo(winid)[1]
    if window.topline < minline then
      minline = window.topline
    end
    if window.botline > maxline then
      maxline = window.botline
    end
  end
  local offset = offset or state.config.syn_maxlines
  minline = math.max(0, minline - offset - 1)
  maxline = math.min(bufinfo.linecount, maxline + offset)
  return minline, maxline
end

local function get_buffer_iterator(bufnr)
  return function(callback)

    local state = state_table[bufnr]
    local minline, maxline = get_buffer_visible_syn_range(bufnr)
    state.visible_syn_range = {minline, maxline}
    local lines = vim.api.nvim_buf_get_lines(bufnr, minline, maxline, false)
    local calc_syntax = next(state.config.ignore_syntax)

    for row, line in ipairs(lines) do
      local col = 1

      while true do
        local start_col, end_col = line:find(state.matchers_pattern, col)
        if not start_col then
          break
        end

        local row = row + minline
        col = start_col + 1
        local ignore = false

        if calc_syntax then
          if not state.hl_cache[row] then
            state.hl_cache[row] = {}
          end
          if not state.hl_cache[row][start_col] then
            state.hl_cache[row][start_col] = get_syn_name(bufnr, row, start_col)
          end
          ignore = ignore or state.config.ignore_syntax[state.hl_cache[row][start_col]]
        end

        if not ignore then
          local opt = state.matchers[line:sub(start_col, end_col)]
          callback(opt[1], opt[2], opt[3], row-1, start_col-1, row-1, end_col)
        end
      end
    end

  end
end

local function invalidate_hl_cache(bufnr, byte_changes)
  local state = state_table[bufnr]
  local maxline = vim.api.nvim_buf_line_count(bufnr)
  for _, change in ipairs(byte_changes) do
    -- invalidate everything after this change
    for i = change[1]+1, maxline do
      if state.hl_cache[i] then
        for k, v in pairs(state.hl_cache[i]) do
          state.hl_cache[i][k] = nil
        end
      end
    end
    maxline = change[1]
  end
end

local function need_invalidate(bufnr)
  local state = state_table[bufnr]

  if not state.items then
    -- first run
    return true

  elseif #state.changes > 0 then
    -- tree changes
    return true

  elseif not state.parser then
    if #state.byte_changes > 0 then
      -- if not treesitter, can't rely on tree changes
      -- so pretty much any change invalidates
      return true
    end

    -- invalidate if we have scrolled out of range
    local minline, maxline = get_buffer_visible_syn_range(bufnr, 0)
    if not state.visible_syn_range or minline < state.visible_syn_range[1] or state.visible_syn_range[2] < maxline then
      return true
    end

  elseif #state.byte_changes > 0 and #state.items > 0 then
    -- we only care about byte changes if they make line changes OR we have brackets on the same row
    for _, change in ipairs(state.byte_changes) do
      local item = state.items[binsearch_items(state.items, {change[1], 0})]
      if item and (change[1] ~= change[3] or item.start[1] == change[1]) then
        return true
      end
    end

  end

  -- no changes
  return false
end

function M.update(bufnr, force)
  if not state_table[bufnr] or vim.fn.pumvisible() ~= 0 then
    return
  end

  local invalidate = force or need_invalidate(bufnr)

  local state = state_table[bufnr]
  state.changes = {}
  local byte_changes = state.byte_changes
  state.byte_changes = {}
  if not invalidate then
    return
  end

  if not state.parser then
    invalidate_hl_cache(bufnr, byte_changes)
  end
  local num_trees = 0
  local pool = state.items or {}

  if state.parser then
    local lang = get_lang(bufnr)
    state.items = {}
    state.parser:for_each_tree(function(tree, sub_parser)
      local lang = sub_parser:lang()
      if state.enabled_langs[lang] == nil then
        state.enabled_langs[lang] = not state.config.treesitter_enable or state.config.treesitter_enable(lang, bufnr)
      end

      if state.enabled_langs[lang] then
        local iterator = get_treesitter_iterator(bufnr, tree, lang)
        if iterator then
          local items = parse_matches(bufnr, iterator, pool, num_trees)
          num_trees = num_trees + 1
          vim.list_extend(state.items, items)
        end
      end
    end)

  else
    vim.api.nvim_buf_call(bufnr, function()
      local iterator = get_buffer_iterator(bufnr)
      state.items = parse_matches(bufnr, iterator, pool, num_trees)
      num_trees = num_trees + 1
    end)
  end

  -- don't need to sort if only 1 tree
  if num_trees > 1 then
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
  if state_table[bufnr] then
    if state_table[bufnr].lang == lang then
      return
    end
    M.detach(bufnr)
  end
  lang = lang or get_lang(bufnr)

  if config.enable and not config.enable(bufnr, lang) then
    M.detach(bufnr)
    return
  end

  local parser = nil
  if not config.treesitter_enable or config.treesitter_enable(bufnr, lang) then
    if rainbow_query.get_query(lang) then
      parser = get_parser(bufnr, lang)
    end
  end

  state_table[bufnr] = {
    lang = lang,
    changes = {},
    byte_changes = {},
    items = nil,
    parser = parser,
    enabled_langs = {},
    config = config,
    hl_cache = {},
  }
  local state = state_table[bufnr]

  state.matchers = config.matchers[lang] or config.matchers['']
  if config.additional_matchers[lang] then
    state.matchers = {table.unpack(config.matchers), table.unpack(config.additional_matchers[lang])}
  end
  state.matchers_pattern = '['..table.concat(vim.tbl_keys(state.matchers), ''):gsub('[%]%%]', '%%%1')..']'

  local on_bytes = function(bufnr, tick, start_row, start_col, offset, old_end_row, old_end_col, old_len, end_row, end_col, len)
    -- sometimes there's no syntax/tree changes, but there are byte changes
    -- these can shift the positions of later brackets
    -- so we reparse in these cases
    if state_table[bufnr] == state then
      local change = {
        start_row + math.min(0, end_row-old_end_row),
        start_col + math.min(0, end_col-old_end_col),
        start_row + math.max(0, end_row-old_end_row),
        start_col + math.max(0, end_col-old_end_col),
        delete = old_end_col > end_col,
      }
      table.insert(state.byte_changes, change);
    else
      -- detach
      return true
    end
  end

  if parser then
    parser:register_cbs({
      on_changedtree = function(changes, tree)
        if state_table[bufnr] == state then
          vim.list_extend(state.changes, changes)
        end
      end,
      on_bytes = on_bytes,
    })
  else
    local attached = vim.api.nvim_buf_attach(bufnr, false, {
      on_bytes = function(_bytes, ...) return on_bytes(...) end,
      on_detach = function(_detach, bufnr) M.detach(bufnr) end,
    })
    if not attached then
      -- failed attaching
      state_table[bufnr] = nil
      return
    end
  end

  vim.api.nvim_create_autocmd('BufReadPost', {buffer=bufnr, callback=function()
    if state_table[bufnr] == state then
      M.detach(bufnr)
      M.attach(bufnr, nil, state.config)
    else
      -- detach
      return true
    end
  end})

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

  local items = state_table[bufnr].items
  local start, finish = get_items_in_range(items, {row-1, math.huge}, {row, math.huge})
  for i = start, finish-1 do
    local item = items[i]
    if item.type ~= CONSTANTS.MIDDLE or (item.level and config.highlight_middle) then

      if not item.hl then
        item.hl = config.unmatched_color
        if item.matched or item.type == CONSTANTS.MIDDLE then
          item.hl = config.colors[(item.level-1) % #config.colors + 1]
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
    -- if we are using treesitter highlighting, it will do this for us
    -- otherwise, we have to do it
    if state_table[bufnr] and state_table[bufnr].parser and not vim.treesitter.highlighter.active[bufnr] then
      state_table[bufnr].parser:parse()
    end
  end,
})

function M.get_matches(bufnr, start, finish)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local start = start or {-1, math.huge}
  local finish = finish or {math.huge, math.huge}
  local items = state_table[bufnr].items
  local start, finish = get_items_in_range(items, start, finish)

  return vim.list_slice(items, start, finish-1)
end

return M
