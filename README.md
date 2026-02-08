# lua-toon

A Token Optimized Object Notation (TOON) Library for Lua

**TOON (Token-Oriented Object Notation)** is a compact, human-readable serialization format optimized for LLM contexts, achieving **30-60% token reduction** compared to JSON while maintaining excellent human readability. This library provides a complete Lua implementation of the TOON format.

## Features

- 🚀 **30-60% smaller** than JSON - save tokens, reduce costs
- 📖 **Human-readable** - YAML-like indentation, natural syntax  
- ⚡ **Pure Lua** - no external dependencies
- 🎯 **Type-safe** - handles strings, numbers, booleans, tables
- 📊 **Tabular arrays** - CSV-style format for uniform data structures
- 🔧 **Flexible** - multiple delimiters, custom indentation
- ✅ **Well-tested** - comprehensive test coverage

## Installation

Simply copy `toon.lua` to your project directory and require it:

```lua
local toon = require("toon")
```

Or install via LuaRocks (coming soon):

```bash
luarocks install lua-toon
```

## Quick Start

### Basic Encoding

```lua
local toon = require("toon")

-- Simple object
local user = {name = "Alice", age = 30, active = true}
local toon_str = toon.encode(user)
print(toon_str)
--[[
Output:
active: true
age: 30
name: Alice
]]

-- Nested object
local data = {
  user = {
    name = "Alice",
    contact = {
      email = "alice@example.com",
      phone = "+1234567890"
    }
  },
  timestamp = "2024-11-24T10:30:00Z"
}
print(toon.encode(data))
--[[
Output:
timestamp: "2024-11-24T10:30:00Z"
user:
  contact:
    email: alice@example.com
    phone: +1234567890
  name: Alice
]]
```

### Arrays - Three Powerful Formats

```lua
-- 1. Inline arrays (compact, single line)
local colors = {colors = {"red", "green", "blue"}}
print(toon.encode(colors))
-- Output: colors[3]: red,green,blue

-- 2. Tabular arrays (CSV-style for uniform objects)
local users = {
  users = {
    {id = 1, name = "Alice", score = 95},
    {id = 2, name = "Bob", score = 87},
    {id = 3, name = "Charlie", score = 92}
  }
}
print(toon.encode(users))
--[[
Output:
users[3,]{id,name,score}:
  1,Alice,95
  2,Bob,87
  3,Charlie,92
]]

-- 3. List arrays (for mixed or complex items)
local tasks = {
  tasks = {
    {task = "Review PR", priority = "high"},
    "Send email",
    {task = "Update docs", priority = "low"}
  }
}
print(toon.encode(tasks))
--[[
Output:
tasks[3]:
  - priority: high
    task: Review PR
  - Send email
  - priority: low
    task: Update docs
]]
```

### Decoding

```lua
-- Decode TOON back to Lua tables
local toon_str = [[
user:
  name: Alice
  age: 30
tags[3]: lua,toon,awesome
]]

local data = toon.decode(toon_str)
print(data.user.name)  -- Alice
print(data.user.age)   -- 30
print(data.tags[1])    -- lua
print(data.tags[2])    -- toon
print(data.tags[3])    -- awesome
```

## Token Savings Examples

### Example 1: User Database (3 records)

```lua
local users = {
  users = {
    {id = 1, name = "Alice", email = "alice@example.com", age = 30, active = true},
    {id = 2, name = "Bob", email = "bob@example.com", age = 25, active = false},
    {id = 3, name = "Charlie", email = "charlie@example.com", age = 35, active = true}
  }
}

local json = require("json") -- hypothetical
print("JSON length: " .. #json.encode(users))    -- ~312 chars
print("TOON length: " .. #toon.encode(users))    -- ~178 chars
-- Savings: 43%!
```

### Example 2: API Response

```lua
local response = {
  status = "success",
  data = {
    products = {
      {id = 101, name = "Laptop", price = 999.99, stock = 15},
      {id = 102, name = "Mouse", price = 29.99, stock = 150},
      {id = 103, name = "Keyboard", price = 79.99, stock = 45}
    }
  },
  meta = {page = 1, total = 3}
}

-- JSON: ~380 characters
-- TOON: ~210 characters
-- Savings: 45%
```

## API Reference

### `toon.encode(value [, options])`

Converts a Lua value to TOON format string.

**Parameters:**
- `value` (any): The Lua value to encode (table, string, number, boolean, or nil)
- `options` (table, optional): Encoding options
  - `delimiter` (string): Value delimiter - `","` (default), `"\t"` (tab), or `"|"` (pipe)
  - `indent` (number): Spaces per indentation level (default: 2)

**Returns:** String in TOON format

**Example:**
```lua
local data = {name = "Alice", items = {1, 2, 3}}
local toon_str = toon.encode(data, {delimiter = "|", indent = 4})
```

### `toon.decode(str)`

Converts a TOON format string back to a Lua value.

**Parameters:**
- `str` (string): TOON format string to decode

**Returns:** Lua value (typically a table)

**Example:**
```lua
local toon_str = "name: Alice\nage: 30"
local data = toon.decode(toon_str)
print(data.name)  -- Alice
print(data.age)   -- 30
```

## Format Specification

TOON uses several key syntaxes:

### Objects
```
key: value
nested:
  key1: value1
  key2: value2
```

### Inline Arrays (Primitives)
```
numbers[3]: 1,2,3
words[2]: hello,world
```

### Tabular Arrays (Uniform Objects)
```
users[3,]{id,name,age}:
  1,Alice,30
  2,Bob,25
  3,Charlie,35
```

### List Arrays (Mixed Content)
```
items[2]:
  - first item
  - second: item
    with: properties
```

### Primitive Values
- **Strings**: Unquoted when safe, quoted with `"` when containing special chars
- **Numbers**: Written as-is: `42`, `3.14`, `-17`
- **Booleans**: `true` or `false`
- **Null**: `null` (encoded from Lua `nil`)

### Quoting Rules

Strings need quotes when they:
- Contain structural characters: `[`, `]`, `{`, `}`, `-`, `:`, `,`, `|`, `\t`
- Look like reserved words: `true`, `false`, `null`
- Look like numbers
- Have leading/trailing whitespace
- Contain control characters

## Use Cases

✅ **Perfect for:**
- LLM prompts and responses
- AI agent communication
- API payloads with repeated structures
- Configuration files
- Data interchange between AI systems
- Token-constrained contexts
- Cost optimization in LLM applications

❌ **Consider alternatives:**
- Binary data (use MessagePack)
- Legacy system integration (use JSON/XML)
- Extremely large datasets (use database)

## Testing

Run the test suite:

```bash
lua test_toon.lua
```

Or with Lua 5.3:

```bash
lua5.3 test_toon.lua
```

Run examples:

```bash
lua examples.lua
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Related Projects

- [toon-php](https://github.com/jimmyahalpara/toon-php) - PHP implementation
- [TOON Specification](https://toonformat.dev/reference/spec) - Official specification

## Acknowledgments

Based on the Token Optimized Object Notation (TOON) format specification designed for LLM token efficiency.
