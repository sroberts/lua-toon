--[[
  TOON Format for Lua
  
  Token-Oriented Object Notation (TOON) is a compact, human-readable serialization
  format optimized for LLM contexts. Achieves 30-60% token reduction vs JSON while
  maintaining readability and structure.
  
  Usage:
    local toon = require("toon")
    
    -- Encode Lua table to TOON string
    local data = {name = "Alice", age = 30, tags = {"lua", "toon"}}
    local toon_str = toon.encode(data)
    
    -- Decode TOON string to Lua table
    local result = toon.decode(toon_str)
--]]

local toon = {}

-- Constants
local COLON = ":"
local COMMA = ","
local TAB = "\t"
local PIPE = "|"
local DOUBLE_QUOTE = '"'
local BACKSLASH = "\\"
local OPEN_BRACKET = "["
local CLOSE_BRACKET = "]"
local OPEN_BRACE = "{"
local CLOSE_BRACE = "}"
local LIST_ITEM_PREFIX = "- "

local NULL_LITERAL = "null"
local TRUE_LITERAL = "true"
local FALSE_LITERAL = "false"

local DEFAULT_DELIMITER = COMMA
local DEFAULT_INDENT = 2

-- Helper functions

local function is_array(t)
  if type(t) ~= "table" then
    return false
  end
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
end

local function is_primitive(value)
  local t = type(value)
  return t == "string" or t == "number" or t == "boolean" or value == nil
end

local function is_array_of_primitives(arr)
  if not is_array(arr) then
    return false
  end
  for _, v in ipairs(arr) do
    if not is_primitive(v) then
      return false
    end
  end
  return true
end

local function is_array_of_objects(arr)
  if not is_array(arr) then
    return false
  end
  for _, v in ipairs(arr) do
    if type(v) ~= "table" or is_array(v) then
      return false
    end
  end
  return true
end

local function table_keys(t)
  local keys = {}
  for k in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

local function table_length(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- String utilities

local function needs_quoting(str, delimiter)
  if str == "" then
    return true
  end
  
  -- Check for reserved literals
  if str == TRUE_LITERAL or str == FALSE_LITERAL or str == NULL_LITERAL then
    return true
  end
  
  -- Check if it looks like a number
  if tonumber(str) then
    return true
  end
  
  -- Check for structural characters
  if str:match("[%[%]{}%-:" .. delimiter .. "]") then
    return true
  end
  
  -- Check for control characters
  if str:match("[\0-\31\127]") then
    return true
  end
  
  -- Check for leading/trailing whitespace
  if str:match("^%s") or str:match("%s$") then
    return true
  end
  
  return false
end

local function escape_string(str)
  return str:gsub("\\", "\\\\")
            :gsub('"', '\\"')
            :gsub("\n", "\\n")
            :gsub("\r", "\\r")
            :gsub("\t", "\\t")
end

local function is_valid_unquoted_key(key)
  return key:match("^[A-Za-z_][A-Za-z0-9_.]*$") ~= nil
end

-- Encoding functions

local function encode_primitive(value, delimiter)
  if value == nil then
    return NULL_LITERAL
  end
  
  if type(value) == "boolean" then
    return value and TRUE_LITERAL or FALSE_LITERAL
  end
  
  if type(value) == "number" then
    return tostring(value)
  end
  
  if type(value) == "string" then
    if needs_quoting(value, delimiter) then
      return DOUBLE_QUOTE .. escape_string(value) .. DOUBLE_QUOTE
    else
      return value
    end
  end
  
  return tostring(value)
end

local function encode_key(key)
  if is_valid_unquoted_key(key) then
    return key
  else
    return DOUBLE_QUOTE .. escape_string(key) .. DOUBLE_QUOTE
  end
end

local function join_encoded_values(values, delimiter)
  return table.concat(values, delimiter)
end

local function format_header(key, length, fields, delimiter)
  local parts = {}
  
  -- Start bracket
  table.insert(parts, OPEN_BRACKET)
  table.insert(parts, tostring(length))
  
  -- Add delimiter for tabular or non-comma delimiter
  if fields or delimiter ~= COMMA then
    table.insert(parts, delimiter)
  end
  
  table.insert(parts, CLOSE_BRACKET)
  
  -- Add fields for tabular format
  if fields then
    local field_parts = {}
    for _, field in ipairs(fields) do
      table.insert(field_parts, encode_key(field))
    end
    table.insert(parts, OPEN_BRACE)
    table.insert(parts, table.concat(field_parts, delimiter))
    table.insert(parts, CLOSE_BRACE)
  end
  
  table.insert(parts, COLON)
  
  -- Add key prefix if provided
  if key then
    return encode_key(key) .. table.concat(parts)
  else
    return table.concat(parts)
  end
end

-- Main encoding logic

local function encode_value(value, depth, options, output)
  local indent_str = string.rep(" ", depth * options.indent)
  
  if is_primitive(value) then
    table.insert(output, indent_str .. encode_primitive(value, options.delimiter))
  elseif is_array(value) then
    encode_array(value, depth, nil, options, output)
  else
    encode_object(value, depth, nil, options, output)
  end
end

function encode_object(obj, depth, key, options, output)
  local indent_str = string.rep(" ", depth * options.indent)
  
  -- Empty object at root level produces no output
  if table_length(obj) == 0 and key == nil and depth == 0 then
    return
  end
  
  -- If there's a key, write it with colon
  if key then
    table.insert(output, indent_str .. encode_key(key) .. COLON)
    depth = depth + 1
    indent_str = string.rep(" ", depth * options.indent)
  end
  
  -- Encode each key-value pair
  local keys = table_keys(obj)
  for _, k in ipairs(keys) do
    local v = obj[k]
    encode_key_value_pair(k, v, depth, options, output)
  end
end

function encode_key_value_pair(key, value, depth, options, output)
  local indent_str = string.rep(" ", depth * options.indent)
  
  if is_primitive(value) then
    local prim_str = encode_primitive(value, options.delimiter)
    table.insert(output, indent_str .. encode_key(key) .. COLON .. " " .. prim_str)
  elseif is_array(value) then
    encode_array(value, depth, key, options, output)
  else
    encode_object(value, depth, key, options, output)
  end
end

function encode_array(arr, depth, key, options, output)
  local indent_str = string.rep(" ", depth * options.indent)
  local arr_len = #arr
  
  -- Handle empty array
  if arr_len == 0 then
    local header = format_header(key, 0, nil, options.delimiter)
    table.insert(output, indent_str .. header)
    return
  end
  
  -- Check array type and encode accordingly
  if is_array_of_primitives(arr) then
    encode_inline_primitive_array(arr, depth, key, options, output)
  elseif is_array_of_objects(arr) then
    local fields = detect_tabular_header(arr)
    if fields then
      encode_tabular_array(arr, fields, depth, key, options, output)
    else
      encode_list_array(arr, depth, key, options, output)
    end
  else
    encode_list_array(arr, depth, key, options, output)
  end
end

function encode_inline_primitive_array(arr, depth, key, options, output)
  local indent_str = string.rep(" ", depth * options.indent)
  local encoded_values = {}
  
  for _, item in ipairs(arr) do
    table.insert(encoded_values, encode_primitive(item, options.delimiter))
  end
  
  local joined = join_encoded_values(encoded_values, options.delimiter)
  local header = format_header(key, #arr, nil, options.delimiter)
  table.insert(output, indent_str .. header .. " " .. joined)
end

function detect_tabular_header(arr)
  if #arr == 0 then
    return nil
  end
  
  -- Get keys from first object
  local first_keys = table_keys(arr[1])
  
  -- Check all objects have same keys and all values are primitives
  for _, obj in ipairs(arr) do
    local obj_keys = table_keys(obj)
    if #obj_keys ~= #first_keys then
      return nil
    end
    for i, k in ipairs(first_keys) do
      if obj_keys[i] ~= k then
        return nil
      end
      if not is_primitive(obj[k]) then
        return nil
      end
    end
  end
  
  return first_keys
end

function encode_tabular_array(arr, fields, depth, key, options, output)
  local indent_str = string.rep(" ", depth * options.indent)
  local header = format_header(key, #arr, fields, options.delimiter)
  table.insert(output, indent_str .. header)
  
  -- Encode each row
  for _, obj in ipairs(arr) do
    local row_values = {}
    for _, field in ipairs(fields) do
      table.insert(row_values, encode_primitive(obj[field], options.delimiter))
    end
    local row = join_encoded_values(row_values, options.delimiter)
    table.insert(output, string.rep(" ", (depth + 1) * options.indent) .. row)
  end
end

function encode_list_array(arr, depth, key, options, output)
  local indent_str = string.rep(" ", depth * options.indent)
  local header = format_header(key, #arr, nil, options.delimiter)
  table.insert(output, indent_str .. header)
  
  -- Encode each item with list marker
  for _, item in ipairs(arr) do
    if is_primitive(item) then
      local prim_str = encode_primitive(item, options.delimiter)
      table.insert(output, string.rep(" ", (depth + 1) * options.indent) .. LIST_ITEM_PREFIX .. prim_str)
    elseif is_array(item) then
      if is_array_of_primitives(item) then
        -- Inline primitive array as list item
        local encoded_values = {}
        for _, v in ipairs(item) do
          table.insert(encoded_values, encode_primitive(v, options.delimiter))
        end
        local joined = join_encoded_values(encoded_values, options.delimiter)
        local item_header = format_header(nil, #item, nil, options.delimiter)
        table.insert(output, string.rep(" ", (depth + 1) * options.indent) .. LIST_ITEM_PREFIX .. item_header .. " " .. joined)
      else
        -- Non-inline array
        local item_header = format_header(nil, #item, nil, options.delimiter)
        table.insert(output, string.rep(" ", (depth + 1) * options.indent) .. LIST_ITEM_PREFIX .. item_header)
        encode_array_content(item, depth + 2, options, output)
      end
    else
      encode_object_as_list_item(item, depth + 1, options, output)
    end
  end
end

function encode_object_as_list_item(obj, depth, options, output)
  local indent_str = string.rep(" ", depth * options.indent)
  
  if table_length(obj) == 0 then
    table.insert(output, indent_str .. LIST_ITEM_PREFIX:sub(1, -2))
    return
  end
  
  -- Get first key-value pair
  local keys = table_keys(obj)
  local first_key = keys[1]
  local first_value = obj[first_key]
  
  if is_primitive(first_value) then
    local encoded_val = encode_primitive(first_value, options.delimiter)
    table.insert(output, indent_str .. LIST_ITEM_PREFIX .. encode_key(first_key) .. COLON .. " " .. encoded_val)
  elseif is_array(first_value) and is_array_of_primitives(first_value) then
    -- Inline array
    local encoded_values = {}
    for _, v in ipairs(first_value) do
      table.insert(encoded_values, encode_primitive(v, options.delimiter))
    end
    local joined = join_encoded_values(encoded_values, options.delimiter)
    local item_header = format_header(first_key, #first_value, nil, options.delimiter)
    table.insert(output, indent_str .. LIST_ITEM_PREFIX .. item_header .. " " .. joined)
  else
    -- Complex value, put dash alone
    table.insert(output, indent_str .. LIST_ITEM_PREFIX:sub(1, -2))
    encode_key_value_pair(first_key, first_value, depth + 1, options, output)
  end
  
  -- Rest of the keys
  for i = 2, #keys do
    local k = keys[i]
    encode_key_value_pair(k, obj[k], depth + 1, options, output)
  end
end

function encode_array_content(arr, depth, options, output)
  for _, item in ipairs(arr) do
    if is_primitive(item) then
      table.insert(output, string.rep(" ", depth * options.indent) .. encode_primitive(item, options.delimiter))
    elseif is_array(item) then
      encode_array(item, depth, nil, options, output)
    else
      encode_object(item, depth, nil, options, output)
    end
  end
end

-- Public encode function
function toon.encode(value, options)
  options = options or {}
  options.delimiter = options.delimiter or DEFAULT_DELIMITER
  options.indent = options.indent or DEFAULT_INDENT
  
  local output = {}
  encode_value(value, 0, options, output)
  return table.concat(output, "\n")
end

-- Decoding functions

local function unescape_string(str)
  return str:gsub("\\(.)", function(c)
    if c == "n" then return "\n"
    elseif c == "r" then return "\r"
    elseif c == "t" then return "\t"
    elseif c == "\\" then return "\\"
    elseif c == '"' then return '"'
    else return c
    end
  end)
end

local function decode_primitive(str)
  str = str:match("^%s*(.-)%s*$") -- trim
  
  if str == NULL_LITERAL then
    return nil
  end
  
  if str == TRUE_LITERAL then
    return true
  end
  
  if str == FALSE_LITERAL then
    return false
  end
  
  -- Check for quoted string
  if str:sub(1, 1) == DOUBLE_QUOTE and str:sub(-1) == DOUBLE_QUOTE then
    return unescape_string(str:sub(2, -2))
  end
  
  -- Try to parse as number
  local num = tonumber(str)
  if num then
    return num
  end
  
  -- Otherwise it's an unquoted string
  return str
end

local function split_values(str, delimiter)
  local values = {}
  local current = ""
  local in_quotes = false
  local i = 1
  
  while i <= #str do
    local c = str:sub(i, i)
    
    if c == DOUBLE_QUOTE and (i == 1 or str:sub(i-1, i-1) ~= BACKSLASH) then
      in_quotes = not in_quotes
      current = current .. c
    elseif c == delimiter and not in_quotes then
      table.insert(values, decode_primitive(current))
      current = ""
    else
      current = current .. c
    end
    
    i = i + 1
  end
  
  if current ~= "" then
    table.insert(values, decode_primitive(current))
  end
  
  return values
end

local function parse_header(line)
  -- Extract key, length, fields from header like: key[3,]{field1,field2}: or [3]: 
  local key, rest = line:match("^%s*(.-)(%b[].-):?%s*$")
  
  if not rest then
    return nil
  end
  
  -- Check if key contains the bracket
  local actual_key = nil
  local bracket_part = nil
  
  if key:match("%b[]") then
    actual_key, bracket_part = key:match("^(.-)(%b[].*)$")
    rest = bracket_part
  else
    actual_key = key
  end
  
  -- Parse bracket content [length] or [length,] or [length,]{fields}
  local bracket_content = rest:match("^%[(.-)%]")
  if not bracket_content then
    return nil
  end
  
  local length_str = bracket_content:match("^(%d+)")
  local length = tonumber(length_str)
  
  -- Check for delimiter after length
  local delimiter = COMMA
  if bracket_content:match("^%d+\t") then
    delimiter = TAB
  elseif bracket_content:match("^%d+|") then
    delimiter = PIPE
  end
  
  -- Check for fields
  local fields = nil
  local fields_part = rest:match("%b{}")
  if fields_part then
    fields_part = fields_part:sub(2, -2) -- remove braces
    fields = split_values(fields_part, delimiter)
  end
  
  -- Decode key if it's quoted
  if actual_key and actual_key ~= "" then
    actual_key = decode_primitive(actual_key)
  else
    actual_key = nil
  end
  
  return {
    key = actual_key,
    length = length,
    fields = fields,
    delimiter = delimiter
  }
end

local function get_indent_level(line)
  local spaces = line:match("^( *)")
  return #spaces
end

local function decode_lines(lines, start_idx, parent_indent)
  local result = {}
  local i = start_idx
  local current_key = nil
  
  while i <= #lines do
    local line = lines[i]
    local trimmed = line:match("^%s*(.-)%s*$")
    
    -- Skip empty lines
    if trimmed == "" then
      i = i + 1
      goto continue
    end
    
    local indent = get_indent_level(line)
    
    -- If indent is less than or equal to parent, we're done with this level
    if indent < parent_indent then
      break
    end
    
    -- Check for list item
    if trimmed:match("^%-") then
      -- Handle list items (complex case)
      i = i + 1
      goto continue
    end
    
    -- Check for header (array declaration)
    local header = parse_header(line)
    if header then
      if header.fields then
        -- Tabular array
        local arr = {}
        for j = 1, header.length do
          i = i + 1
          if i > #lines then break end
          local row_line = lines[i]
          local values = split_values(row_line:match("^%s*(.-)%s*$"), header.delimiter)
          local obj = {}
          for k, field in ipairs(header.fields) do
            obj[field] = values[k]
          end
          table.insert(arr, obj)
        end
        
        if header.key then
          result[header.key] = arr
        else
          return arr
        end
      else
        -- Inline primitive array
        local rest_of_line = line:match(":%s*(.+)$")
        if rest_of_line then
          local arr = split_values(rest_of_line, header.delimiter)
          if header.key then
            result[header.key] = arr
          else
            return arr
          end
        end
      end
      
      i = i + 1
      goto continue
    end
    
    -- Check for key-value pair
    local key_part, value_part = trimmed:match("^(.-):%s*(.*)$")
    if key_part then
      local key = decode_primitive(key_part)
      if value_part ~= "" then
        result[key] = decode_primitive(value_part)
      else
        -- Value is on next lines (nested object)
        current_key = key
      end
    else
      -- Continuation of nested value
      if current_key then
        -- This is a nested value for current_key
        -- Need to handle nested objects/arrays
      end
    end
    
    i = i + 1
    ::continue::
  end
  
  return result
end

-- Public decode function (simplified version)
function toon.decode(str)
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  
  return decode_lines(lines, 1, 0)
end

return toon
