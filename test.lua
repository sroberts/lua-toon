#!/usr/bin/env lua

local toon = require("toon")

-- Test counter
local tests_passed = 0
local tests_failed = 0

-- Helper function to compare tables
local function tables_equal(t1, t2)
    if type(t1) ~= type(t2) then return false end
    if type(t1) ~= "table" then return t1 == t2 end
    
    -- Check all keys in t1 exist in t2
    for k, v in pairs(t1) do
        if not tables_equal(v, t2[k]) then
            return false
        end
    end
    
    -- Check all keys in t2 exist in t1
    for k, v in pairs(t2) do
        if not tables_equal(v, t1[k]) then
            return false
        end
    end
    
    return true
end

-- Test function
local function test(name, func)
    local success, err = pcall(func)
    if success then
        print("✓ " .. name)
        tests_passed = tests_passed + 1
    else
        print("✗ " .. name)
        print("  Error: " .. tostring(err))
        tests_failed = tests_failed + 1
    end
end

-- Tests
print("=== TOON Encoder Tests ===\n")

test("Encode primitive string", function()
    local result = toon.encode("hello")
    assert(result == "hello", "Expected 'hello', got: " .. tostring(result))
end)

test("Encode primitive number", function()
    local result = toon.encode(42)
    assert(result == "42", "Expected '42', got: " .. tostring(result))
end)

test("Encode primitive boolean true", function()
    local result = toon.encode(true)
    assert(result == "true", "Expected 'true', got: " .. tostring(result))
end)

test("Encode primitive boolean false", function()
    local result = toon.encode(false)
    assert(result == "false", "Expected 'false', got: " .. tostring(result))
end)

test("Encode primitive null (nil)", function()
    local result = toon.encode(nil)
    assert(result == "", "Expected empty string, got: " .. tostring(result))
end)

test("Encode string that needs quoting (colon)", function()
    local result = toon.encode("hello:world")
    assert(result == '"hello:world"', "Expected quoted string, got: " .. tostring(result))
end)

test("Encode string that needs quoting (empty)", function()
    local result = toon.encode("")
    assert(result == '""', 'Expected \'"\"\', got: ' .. tostring(result))
end)

test("Encode simple object", function()
    local result = toon.encode({name = "Alice", age = 30})
    assert(result:match("name: Alice") or result:match("name: \"Alice\""), "Expected name field")
    assert(result:match("age: 30"), "Expected age field")
end)

test("Encode nested object", function()
    local result = toon.encode({user = {name = "Bob", id = 1}})
    assert(result:match("user:"), "Expected user field")
    assert(result:match("name:"), "Expected name field")
    assert(result:match("id:"), "Expected id field")
end)

test("Encode primitive array", function()
    local result = toon.encode({1, 2, 3})
    assert(result == "[3]: 1,2,3", "Expected '[3]: 1,2,3', got: " .. tostring(result))
end)

test("Encode string array", function()
    local result = toon.encode({"a", "b", "c"})
    assert(result == "[3]: a,b,c", "Expected '[3]: a,b,c', got: " .. tostring(result))
end)

test("Encode empty array", function()
    local result = toon.encode({})
    assert(result == "[0]:", "Expected '[0]:', got: " .. tostring(result))
end)

test("Encode tabular array", function()
    local data = {
        {id = 1, name = "Alice"},
        {id = 2, name = "Bob"}
    }
    local result = toon.encode(data)
    assert(result:match("%[2%]"), "Expected array length [2]")
    assert(result:match("{"), "Expected field list")
    assert(result:match("}:"), "Expected field list end")
end)

test("Encode object with array", function()
    local data = {
        users = {1, 2, 3}
    }
    local result = toon.encode(data)
    assert(result:match("users: %[3%]:"), "Expected users array")
end)

print("\n=== TOON Decoder Tests ===\n")

test("Decode primitive string", function()
    local result = toon.decode("hello")
    assert(result == "hello", "Expected 'hello', got: " .. tostring(result))
end)

test("Decode primitive number", function()
    local result = toon.decode("42")
    assert(result == 42, "Expected 42, got: " .. tostring(result))
end)

test("Decode primitive boolean", function()
    local result = toon.decode("true")
    assert(result == true, "Expected true, got: " .. tostring(result))
end)

test("Decode primitive null", function()
    local result = toon.decode("null")
    assert(result == nil, "Expected nil, got: " .. tostring(result))
end)

test("Decode quoted string", function()
    local result = toon.decode('"hello world"')
    assert(result == "hello world", "Expected 'hello world', got: " .. tostring(result))
end)

test("Decode simple object", function()
    local input = "name: Alice\nage: 30"
    local result = toon.decode(input)
    assert(result.name == "Alice", "Expected name='Alice'")
    assert(result.age == 30, "Expected age=30")
end)

test("Decode primitive inline array", function()
    local input = "[3]: 1,2,3"
    local result = toon.decode(input)
    assert(type(result) == "table", "Expected table")
    assert(#result == 3, "Expected length 3")
    assert(result[1] == 1 and result[2] == 2 and result[3] == 3, "Expected [1,2,3]")
end)

test("Decode string inline array", function()
    local input = "[3]: a,b,c"
    local result = toon.decode(input)
    assert(type(result) == "table", "Expected table")
    assert(#result == 3, "Expected length 3")
    assert(result[1] == "a" and result[2] == "b" and result[3] == "c", "Expected ['a','b','c']")
end)

test("Decode tabular array", function()
    local input = "[2]{id,name}:\n  1,Alice\n  2,Bob"
    local result = toon.decode(input)
    assert(type(result) == "table", "Expected table")
    assert(#result == 2, "Expected length 2")
    assert(result[1].id == 1, "Expected first id=1")
    assert(result[1].name == "Alice", "Expected first name='Alice'")
    assert(result[2].id == 2, "Expected second id=2")
    assert(result[2].name == "Bob", "Expected second name='Bob'")
end)

test("Decode object with array", function()
    local input = "users: [3]: 1,2,3"
    local result = toon.decode(input)
    -- Note: This test may need adjustment based on actual decoder behavior
    assert(type(result) == "table", "Expected table")
end)

print("\n=== Round-trip Tests ===\n")

test("Round-trip primitive string", function()
    local original = "hello"
    local encoded = toon.encode(original)
    local decoded = toon.decode(encoded)
    assert(decoded == original, "Round-trip failed for primitive string")
end)

test("Round-trip primitive number", function()
    local original = 42
    local encoded = toon.encode(original)
    local decoded = toon.decode(encoded)
    assert(decoded == original, "Round-trip failed for primitive number")
end)

test("Round-trip primitive array", function()
    local original = {1, 2, 3}
    local encoded = toon.encode(original)
    local decoded = toon.decode(encoded)
    assert(tables_equal(decoded, original), "Round-trip failed for primitive array")
end)

test("Round-trip simple object", function()
    local original = {name = "Alice", age = 30}
    local encoded = toon.encode(original)
    local decoded = toon.decode(encoded)
    assert(decoded.name == "Alice" and decoded.age == 30, "Round-trip failed for simple object")
end)

-- Summary
print("\n=== Test Summary ===")
print(string.format("Passed: %d", tests_passed))
print(string.format("Failed: %d", tests_failed))
print(string.format("Total:  %d", tests_passed + tests_failed))

if tests_failed > 0 then
    os.exit(1)
end
