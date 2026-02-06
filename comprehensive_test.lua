#!/usr/bin/env lua5.3

local toon = require("toon")

print("=== Comprehensive TOON Feature Tests ===\n")

-- Test 1: Special characters and quoting
print("Test 1: Special characters and quoting")
local special = {
    empty = "",
    withColon = "key:value",
    withComma = "a,b,c",
    withNewline = "line1\nline2",
    withTab = "col1\tcol2",
    withQuote = 'say "hello"',
    withBackslash = "path\\to\\file",
    numeric = "123",
    leadingZero = "007",
    hyphen = "-",
    startHyphen = "-value"
}
local encoded = toon.encode(special)
print(encoded)
print()

-- Test 2: Number precision and special values
print("Test 2: Number handling")
local numbers = {
    integer = 42,
    negative = -17,
    decimal = 3.14159,
    verySmall = 0.000001,
    veryLarge = 1000000,
    zero = 0
}
encoded = toon.encode(numbers)
print(encoded)
print()

-- Test 3: Complex nested structure
print("Test 3: Complex nested structure")
local complex = {
    config = {
        server = {
            host = "0.0.0.0",
            port = 8080,
            ssl = false
        },
        limits = {
            maxConnections = 100,
            timeout = 30
        }
    },
    features = {"api", "websocket", "logging"}
}
encoded = toon.encode(complex)
print(encoded)
print()

-- Test 4: Array variations
print("Test 4: Array variations")

-- Primitive array
local prims = {10, 20, 30, 40}
print("Primitive array:")
print(toon.encode(prims))
print()

-- String array with quotes
local strings = {"normal", "has:colon", "has,comma", ""}
print("String array with special chars:")
print(toon.encode(strings))
print()

-- Boolean array
local bools = {true, false, true, true}
print("Boolean array:")
print(toon.encode(bools))
print()

-- Test 5: Tabular array with various types
print("Test 5: Tabular array with mixed types")
local products = {
    {id = 1, name = "Widget", price = 9.99, inStock = true},
    {id = 2, name = "Gadget", price = 19.99, inStock = false},
    {id = 3, name = "Doohickey", price = 4.99, inStock = true}
}
encoded = toon.encode(products)
print(encoded)
print()

-- Test 6: Empty structures
print("Test 6: Empty structures")
print("Empty array: " .. toon.encode({}))
print()

-- Test 7: Unicode and emoji (if supported)
print("Test 7: Unicode content")
local unicode = {
    greeting = "Hello 世界",
    emoji = "🎉🎊",
    accents = "café résumé"
}
encoded = toon.encode(unicode)
print(encoded)
print()

-- Test 8: Round-trip with tabular data
print("Test 8: Round-trip with tabular data")
local employees = {
    {id = 1, name = "Alice", dept = "Engineering", active = true},
    {id = 2, name = "Bob", dept = "Sales", active = true},
    {id = 3, name = "Carol", dept = "HR", active = false}
}
encoded = toon.encode(employees)
print("Encoded:")
print(encoded)
local decoded = toon.decode(encoded)
print("\nDecoded successfully: " .. tostring(type(decoded) == "table"))
print("First employee name: " .. tostring(decoded[1] and decoded[1].name))
print("Employee count: " .. #decoded)
print()

print("=== All comprehensive tests complete ===")
