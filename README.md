# lua-toon

A Token Optimized Object Notation (TOON) library for Lua.

This library provides encoding and decoding support for the TOON format (Spec v3.0), a line-oriented, indentation-based text format that efficiently represents the JSON data model with minimal quoting.

## Features

- **Encode**: Convert Lua tables to TOON format
- **Decode**: Parse TOON text back to Lua tables
- **Primitive Support**: strings, numbers, booleans, nil
- **Object Support**: nested objects with key-value pairs
- **Array Support**: 
  - Inline primitive arrays: `[3]: 1,2,3`
  - Tabular arrays (uniform objects): `[2]{id,name}: ...`
  - Mixed/list arrays
- **Quoting Rules**: Automatic quoting when needed per TOON spec
- **Delimiter Support**: Comma (default), tab, and pipe delimiters

## Installation

Simply copy `toon.lua` to your Lua project directory or your Lua module path.

## Usage

### Basic Example

```lua
local toon = require("toon")

-- Encode a Lua table to TOON
local data = {
    name = "Alice",
    age = 30,
    active = true
}
local encoded = toon.encode(data)
print(encoded)
-- Output:
-- name: Alice
-- age: 30
-- active: true

-- Decode TOON text back to Lua
local text = "name: Bob\nage: 25"
local decoded = toon.decode(text)
print(decoded.name)  -- "Bob"
print(decoded.age)   -- 25
```

### Encoding

```lua
local toon = require("toon")

-- Primitives
print(toon.encode(42))           -- "42"
print(toon.encode("hello"))      -- "hello"
print(toon.encode(true))         -- "true"
print(toon.encode(nil))          -- "" (empty)

-- Arrays
print(toon.encode({1, 2, 3}))    -- "[3]: 1,2,3"

-- Tabular arrays (uniform objects)
local users = {
    {id = 1, name = "Alice"},
    {id = 2, name = "Bob"}
}
print(toon.encode(users))
-- Output:
-- [2]{id,name}:
--   1,Alice
--   2,Bob

-- Options
local encoded = toon.encode(data, {
    indent = 4,          -- Use 4 spaces per indent level (default: 2)
    delimiter = ","      -- Use comma delimiter (default: ",")
})
```

### Decoding

```lua
local toon = require("toon")

-- Decode primitive
local num = toon.decode("42")  -- 42

-- Decode object
local obj = toon.decode("name: Alice\nage: 30")
-- Returns: {name = "Alice", age = 30}

-- Decode array
local arr = toon.decode("[3]: a,b,c")
-- Returns: {"a", "b", "c"}

-- Decode tabular array
local tabular = toon.decode("[2]{id,name}:\n  1,Alice\n  2,Bob")
-- Returns: {{id=1, name="Alice"}, {id=2, name="Bob"}}

-- Options
local decoded = toon.decode(text, {
    indent = 2,         -- Expected indent size (default: 2)
    strict = true       -- Strict mode validation (not fully implemented)
})
```

## API Reference

### `toon.encode(value [, options])`

Encodes a Lua value to TOON format.

**Parameters:**
- `value`: The Lua value to encode (string, number, boolean, nil, or table)
- `options` (optional): Table with encoding options
  - `indent` (number): Number of spaces per indentation level (default: 2)
  - `delimiter` (string): Delimiter to use: `","`, `"\t"`, or `"|"` (default: `","`)

**Returns:** String containing the TOON representation

### `toon.decode(text [, options])`

Decodes TOON text to a Lua value.

**Parameters:**
- `text` (string): The TOON text to decode
- `options` (optional): Table with decoding options
  - `indent` (number): Expected indentation size (default: 2)
  - `strict` (boolean): Enable strict mode validation (default: true, not fully implemented)

**Returns:** Decoded Lua value (primitive or table)

## TOON Format Overview

TOON (Token-Oriented Object Notation) is a line-oriented format designed for efficiency, especially with arrays of uniform objects:

- **Objects**: Use indentation and `key: value` syntax
- **Arrays**: Declare length with `[N]:` and optional field list `{f1,f2}`
- **Primitives**: Minimal quoting (only when necessary)
- **Delimiters**: Comma (default), tab, or pipe for separating array values

Example TOON document:

```
users[2]{id,name,role}:
  1,Alice,admin
  2,Bob,user
settings:
  theme: dark
  notifications: true
tags[3]: important,urgent,todo
```

## Compliance

This implementation follows the TOON Specification v3.0:
- ✓ Basic data model (primitives, objects, arrays)
- ✓ Canonical number formatting
- ✓ Primitive arrays (inline)
- ✓ Tabular arrays (uniform objects)
- ✓ Mixed/list arrays
- ✓ Nested objects
- ✓ Quoting rules and escaping
- ✓ Delimiter support (comma, tab, pipe)
- ⚠ Partial: Advanced features (strict mode validation, path expansion, key folding)

## Testing

Run the test suite:

```bash
lua5.3 test.lua
```

Run examples:

```bash
lua5.3 example.lua
```

## License

See LICENSE file.

## References

- [TOON Specification](https://github.com/toon-format/spec)
- [TOON Format Website](https://toon-format.org/)

