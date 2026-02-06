-- TOON (Token-Oriented Object Notation) for Lua
-- Spec version 3.0 implementation

local toon = {}

-- Configuration defaults
local DEFAULT_INDENT = 2
local DEFAULT_DELIMITER = ","

-- Pattern constants
local NUMERIC_PATTERN = "^%-?%d+%.?%d*[eE]?[%+%-]?%d*$"
local LEADING_ZERO_PATTERN = "^0%d+$"

-- Helper: Format delimiter symbol for headers
local function format_delimiter_symbol(delimiter)
    if delimiter == "," then
        return ""  -- Comma is default, omit from header
    elseif delimiter == "\t" then
        return "\t"  -- Tab (HTAB)
    elseif delimiter == "|" then
        return "|"  -- Pipe
    else
        return ""  -- Unknown, default to comma
    end
end

-- Helper: Check if value is an array (sequential table)
local function is_array(t)
    if type(t) ~= "table" then return false end
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
        if type(k) ~= "number" or k ~= count then
            return false
        end
    end
    return true
end

-- Helper: Check if string needs quoting
local function needs_quoting(str, delimiter)
    if str == "" then return true end
    if str:match("^%s") or str:match("%s$") then return true end
    if str == "true" or str == "false" or str == "null" then return true end
    if str:match(NUMERIC_PATTERN) then return true end
    if str:match(LEADING_ZERO_PATTERN) then return true end
    if str:match("[:%\"\\%[%]{}]") then return true end
    if str:match("[\n\r\t]") then return true end
    if str:match("^%-") then return true end
    if delimiter and str:match(delimiter) then return true end
    return false
end

-- Helper: Escape string
local function escape_string(str)
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\"", "\\\"")
    str = str:gsub("\n", "\\n")
    str = str:gsub("\r", "\\r")
    str = str:gsub("\t", "\\t")
    return str
end

-- Helper: Quote string if needed
local function quote_if_needed(str, delimiter)
    if needs_quoting(str, delimiter) then
        return '"' .. escape_string(str) .. '"'
    end
    return str
end

-- Helper: Check if key needs quoting
local function needs_key_quoting(key)
    return not key:match("^[A-Za-z_][A-Za-z0-9_.]*$")
end

-- Helper: Quote key if needed
local function quote_key_if_needed(key)
    if needs_key_quoting(key) then
        return '"' .. escape_string(key) .. '"'
    end
    return key
end

-- Helper: Normalize number
local function normalize_number(num)
    if num ~= num then return nil end  -- NaN
    if num == math.huge or num == -math.huge then return nil end  -- Infinity
    if num == -0 then return 0 end
    
    -- Format with enough precision
    local str = string.format("%.17g", num)
    
    -- If still in exponent form, try to expand it
    if str:match("[eE]") then
        -- Try formatting with more decimal places
        local expanded = string.format("%.15f", num)
        -- Remove trailing zeros
        expanded = expanded:gsub("0+$", ""):gsub("%.$", "")
        -- Use expanded form if it's reasonable length
        if #expanded <= 20 then
            str = expanded
        end
    end
    
    -- Remove trailing zeros in decimal part
    if str:match("%.") then
        str = str:gsub("0+$", ""):gsub("%.$", "")
    end
    
    -- If we ended up with just integer, ensure it's an integer
    if not str:match("%.") then
        str = tostring(math.floor(tonumber(str)))
    end
    
    return str
end

-- Helper: Encode a primitive value
local function encode_primitive(value, delimiter)
    local t = type(value)
    
    if t == "nil" or value == nil then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        local normalized = normalize_number(value)
        if normalized == nil then
            return "null"
        end
        return normalized
    elseif t == "string" then
        return quote_if_needed(value, delimiter)
    else
        return "null"
    end
end

-- Helper: Check if array contains only primitives
local function is_primitive_array(arr)
    for _, v in ipairs(arr) do
        local t = type(v)
        if t == "table" then
            return false
        end
    end
    return true
end

-- Helper: Check if array is uniform objects with same primitive keys
local function is_tabular_array(arr)
    if #arr == 0 then return false end
    
    local first = arr[1]
    if type(first) ~= "table" or is_array(first) then
        return false
    end
    
    -- Get keys from first object
    local keys = {}
    for k, v in pairs(first) do
        if type(v) == "table" then
            return false  -- No nested structures in tabular
        end
        table.insert(keys, k)
    end
    
    -- Sort keys once for comparison
    table.sort(keys)
    
    -- Check all other objects have same keys and primitive values
    for i = 2, #arr do
        local obj = arr[i]
        if type(obj) ~= "table" or is_array(obj) then
            return false
        end
        
        local obj_keys = {}
        for k, v in pairs(obj) do
            if type(v) == "table" then
                return false
            end
            table.insert(obj_keys, k)
        end
        
        -- Check key sets match
        table.sort(obj_keys)
        if #keys ~= #obj_keys then return false end
        for j = 1, #keys do
            if keys[j] ~= obj_keys[j] then
                return false
            end
        end
    end
    
    return true, keys
end

-- Encode function
local function encode_value(value, depth, delimiter, indent_size)
    local t = type(value)
    local indent = string.rep(" ", depth * indent_size)
    local lines = {}
    
    if t ~= "table" then
        return encode_primitive(value, delimiter)
    end
    
    if is_array(value) then
        -- Check if it's a primitive array
        if is_primitive_array(value) then
            local parts = {}
            for _, v in ipairs(value) do
                table.insert(parts, encode_primitive(v, delimiter))
            end
            if #value == 0 then
                local delim_sym = format_delimiter_symbol(delimiter)
                return "[0" .. delim_sym .. "]:"
            end
            local delim_sym = format_delimiter_symbol(delimiter)
            return "[" .. #value .. delim_sym .. "]: " .. table.concat(parts, delimiter)
        end
        
        -- Check if it's a tabular array
        local is_tab, keys = is_tabular_array(value)
        if is_tab then
            -- Tabular format
            local delim_sym = format_delimiter_symbol(delimiter)
            local header = "[" .. #value .. delim_sym .. "]{" .. table.concat(keys, delimiter) .. "}:"
            table.insert(lines, header)
            
            for _, obj in ipairs(value) do
                local row_parts = {}
                for _, key in ipairs(keys) do
                    table.insert(row_parts, encode_primitive(obj[key], delimiter))
                end
                table.insert(lines, string.rep(" ", indent_size) .. table.concat(row_parts, delimiter))
            end
            
            return table.concat(lines, "\n")
        end
        
        -- Mixed/list array
        local delim_sym = format_delimiter_symbol(delimiter)
        local header = "[" .. #value .. delim_sym .. "]:"
        table.insert(lines, header)
        
        for _, item in ipairs(value) do
            if type(item) ~= "table" then
                table.insert(lines, string.rep(" ", indent_size) .. "- " .. encode_primitive(item, delimiter))
            elseif is_array(item) then
                if is_primitive_array(item) then
                    local parts = {}
                    for _, v in ipairs(item) do
                        table.insert(parts, encode_primitive(v, delimiter))
                    end
                    local item_delim_sym = format_delimiter_symbol(delimiter)
                    table.insert(lines, string.rep(" ", indent_size) .. "- [" .. #item .. item_delim_sym .. "]: " .. table.concat(parts, delimiter))
                else
                    -- Nested complex array
                    table.insert(lines, string.rep(" ", indent_size) .. "- " .. encode_value(item, depth + 1, delimiter, indent_size))
                end
            else
                -- Object as list item
                local obj_lines = {}
                local first = true
                for k, v in pairs(item) do
                    local key_str = quote_key_if_needed(k)
                    local value_part = encode_value(v, depth + 2, delimiter, indent_size)
                    
                    if first then
                        table.insert(obj_lines, string.rep(" ", indent_size) .. "- " .. key_str .. ": " .. value_part)
                        first = false
                    else
                        if type(v) == "table" and not is_array(v) and next(v) ~= nil then
                            table.insert(obj_lines, string.rep(" ", (depth + 1) * indent_size) .. key_str .. ":")
                            local sub_lines = {}
                            for sk, sv in pairs(v) do
                                local sub_key = quote_key_if_needed(sk)
                                local sub_val = encode_value(sv, depth + 2, delimiter, indent_size)
                                table.insert(sub_lines, string.rep(" ", (depth + 2) * indent_size) .. sub_key .. ": " .. sub_val)
                            end
                            table.insert(obj_lines, table.concat(sub_lines, "\n"))
                        elseif type(v) == "table" and is_array(v) then
                            local arr_encoded = encode_value(v, depth + 2, delimiter, indent_size)
                            if arr_encoded:match("\n") then
                                table.insert(obj_lines, string.rep(" ", (depth + 1) * indent_size) .. key_str .. ": " .. arr_encoded)
                            else
                                table.insert(obj_lines, string.rep(" ", (depth + 1) * indent_size) .. key_str .. ": " .. arr_encoded)
                            end
                        else
                            table.insert(obj_lines, string.rep(" ", (depth + 1) * indent_size) .. key_str .. ": " .. value_part)
                        end
                    end
                end
                table.insert(lines, table.concat(obj_lines, "\n"))
            end
        end
        
        return table.concat(lines, "\n")
    else
        -- Object
        if next(value) == nil then
            return ""  -- Empty object
        end
        
        for k, v in pairs(value) do
            local key_str = quote_key_if_needed(k)
            
            if type(v) ~= "table" then
                table.insert(lines, indent .. key_str .. ": " .. encode_primitive(v, delimiter))
            elseif is_array(v) then
                local arr_encoded = encode_value(v, depth + 1, delimiter, indent_size)
                if arr_encoded:match("\n") then
                    table.insert(lines, indent .. key_str .. ": " .. arr_encoded:gsub("^%s+", ""))
                else
                    table.insert(lines, indent .. key_str .. ": " .. arr_encoded)
                end
            else
                if next(v) == nil then
                    table.insert(lines, indent .. key_str .. ":")
                else
                    table.insert(lines, indent .. key_str .. ":")
                    for sk, sv in pairs(v) do
                        local sub_key = quote_key_if_needed(sk)
                        local sub_encoded = encode_value(sv, depth + 1, delimiter, indent_size)
                        if type(sv) == "table" and not is_array(sv) and next(sv) ~= nil then
                            table.insert(lines, string.rep(" ", (depth + 1) * indent_size) .. sub_key .. ":")
                            for ssk, ssv in pairs(sv) do
                                local subsub_key = quote_key_if_needed(ssk)
                                table.insert(lines, string.rep(" ", (depth + 2) * indent_size) .. subsub_key .. ": " .. encode_primitive(ssv, delimiter))
                            end
                        else
                            table.insert(lines, string.rep(" ", (depth + 1) * indent_size) .. sub_key .. ": " .. sub_encoded)
                        end
                    end
                end
            end
        end
        
        return table.concat(lines, "\n")
    end
end

-- Main encode function
function toon.encode(value, options)
    options = options or {}
    local indent_size = options.indent or DEFAULT_INDENT
    local delimiter = options.delimiter or DEFAULT_DELIMITER
    
    if value == nil then
        return ""
    end
    
    if type(value) ~= "table" then
        return encode_primitive(value, delimiter)
    end
    
    if is_array(value) then
        return encode_value(value, 0, delimiter, indent_size)
    else
        if next(value) == nil then
            return ""
        end
        return encode_value(value, 0, delimiter, indent_size)
    end
end

-- Decoder helpers

-- Unescape string
local function unescape_string(str)
    str = str:gsub("\\\\", "\x00")  -- Temporary placeholder
    str = str:gsub("\\\"", "\"")
    str = str:gsub("\\n", "\n")
    str = str:gsub("\\r", "\r")
    str = str:gsub("\\t", "\t")
    str = str:gsub("\x00", "\\")  -- Restore backslash
    return str
end

-- Parse a quoted string
local function parse_quoted_string(str)
    if str:sub(1, 1) == '"' and str:sub(-1) == '"' then
        return unescape_string(str:sub(2, -2))
    end
    return nil
end

-- Parse unquoted value
local function parse_unquoted_value(str)
    str = str:match("^%s*(.-)%s*$")  -- Trim
    
    if str == "true" then return true end
    if str == "false" then return false end
    if str == "null" then return nil end
    
    -- Try to parse as number
    if str:match(NUMERIC_PATTERN) and not str:match(LEADING_ZERO_PATTERN) then
        return tonumber(str)
    end
    
    return str
end

-- Parse value (quoted or unquoted)
local function parse_value(str)
    str = str:match("^%s*(.-)%s*$")  -- Trim
    
    local quoted = parse_quoted_string(str)
    if quoted ~= nil or str:match("^\"") then
        return quoted or ""
    end
    
    return parse_unquoted_value(str)
end

-- Split by delimiter
local function split_by_delimiter(str, delimiter)
    local parts = {}
    local current = ""
    local in_quote = false
    local escape_next = false
    
    for i = 1, #str do
        local c = str:sub(i, i)
        
        if escape_next then
            current = current .. c
            escape_next = false
        elseif c == "\\" and in_quote then
            current = current .. c
            escape_next = true
        elseif c == '"' then
            in_quote = not in_quote
            current = current .. c
        elseif c == delimiter and not in_quote then
            table.insert(parts, current:match("^%s*(.-)%s*$"))
            current = ""
        else
            current = current .. c
        end
    end
    
    if current ~= "" or #parts > 0 then
        table.insert(parts, current:match("^%s*(.-)%s*$"))
    end
    
    return parts
end

-- Parse header
local function parse_header(line)
    -- Match: [key][N<delim?>]{fields}:
    -- Need to extract delimiter from inside brackets
    local key, bracket_content, fields_str = line:match("^(.-)%[([^%]]+)%](.*)$")
    
    if not bracket_content then return nil end
    
    -- Parse bracket content for count and delimiter
    local count_str = bracket_content:match("^(%d+)")
    if not count_str then return nil end
    
    local count = tonumber(count_str)
    local delimiter = ","  -- Default
    
    -- Check for delimiter after the number
    local delim_char = bracket_content:sub(#count_str + 1, #count_str + 1)
    if delim_char == "\t" then
        delimiter = "\t"
    elseif delim_char == "|" then
        delimiter = "|"
    end
    
    local fields = {}
    
    -- Check for delimiter in header
    if fields_str:match("^%s*:") then
        -- No fields, just colon
        fields_str = fields_str:match("^%s*:%s*(.*)$")
        return {
            key = key ~= "" and key or nil,
            count = count,
            delimiter = delimiter,
            fields = fields,
            remaining = fields_str
        }
    end
    
    -- Parse fields
    local fields_part = fields_str:match("^%{(.-)%}:(.*)$")
    if fields_part then
        local remaining = fields_str:match("^%{.-%}:(.*)$")
        fields = split_by_delimiter(fields_part, delimiter)
        
        -- Parse field names
        for i, f in ipairs(fields) do
            fields[i] = parse_quoted_string(f) or f
        end
        
        return {
            key = key ~= "" and key or nil,
            count = count,
            delimiter = delimiter,
            fields = fields,
            remaining = remaining
        }
    end
    
    -- Just colon after bracket
    local remaining = fields_str:match("^%s*:%s*(.*)$")
    return {
        key = key ~= "" and key or nil,
        count = count,
        delimiter = delimiter,
        fields = fields,
        remaining = remaining
    }
end

-- Calculate indentation depth
local function get_indent_depth(line, indent_size)
    local spaces = line:match("^( *)")
    return math.floor(#spaces / indent_size)
end

-- Main decode function
function toon.decode(text, options)
    options = options or {}
    local indent_size = options.indent or DEFAULT_INDENT
    
    if text == "" or text == nil then
        return {}
    end
    
    local lines = {}
    for line in text:gmatch("[^\n]*") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    
    if #lines == 0 then
        return {}
    end
    
    -- Single line, might be primitive
    if #lines == 1 then
        local line = lines[1]
        local header = parse_header(line)
        
        if header then
            -- Root array
            if header.remaining and header.remaining ~= "" then
                -- Inline primitive array
                local parts = split_by_delimiter(header.remaining, header.delimiter)
                local result = {}
                for _, part in ipairs(parts) do
                    table.insert(result, parse_value(part))
                end
                return result
            else
                -- Empty array or needs more lines
                return {}
            end
        elseif not line:match(":") then
            -- Single primitive
            return parse_value(line)
        end
    end
    
    -- Parse as object or array
    local first_line = lines[1]
    local header = parse_header(first_line)
    
    if header and get_indent_depth(first_line, indent_size) == 0 then
        -- Root array
        if header.remaining and header.remaining ~= "" then
            -- Inline primitive array
            local parts = split_by_delimiter(header.remaining, header.delimiter)
            local result = {}
            for _, part in ipairs(parts) do
                table.insert(result, parse_value(part))
            end
            return result
        elseif #header.fields > 0 then
            -- Tabular array
            local result = {}
            for i = 2, #lines do
                local line = lines[i]
                local parts = split_by_delimiter(line:match("^%s*(.*)$"), header.delimiter)
                local obj = {}
                for j, field in ipairs(header.fields) do
                    obj[field] = parse_value(parts[j] or "")
                end
                table.insert(result, obj)
            end
            return result
        else
            -- List array - parse list items
            local result = {}
            for i = 2, #lines do
                local line = lines[i]
                if line:match("^%s*%- ") then
                    local item_str = line:match("^%s*%- (.*)$")
                    local item_header = parse_header(item_str)
                    if item_header then
                        -- Nested array
                        local parts = split_by_delimiter(item_header.remaining, item_header.delimiter)
                        local arr = {}
                        for _, part in ipairs(parts) do
                            table.insert(arr, parse_value(part))
                        end
                        table.insert(result, arr)
                    else
                        table.insert(result, parse_value(item_str))
                    end
                end
            end
            return result
        end
    end
    
    -- Parse as object
    local result = {}
    for _, line in ipairs(lines) do
        local key, value = line:match("^%s*(.-):%s*(.*)$")
        if key then
            key = parse_quoted_string(key) or key
            if value ~= "" then
                result[key] = parse_value(value)
            else
                result[key] = {}
            end
        end
    end
    
    return result
end

return toon
