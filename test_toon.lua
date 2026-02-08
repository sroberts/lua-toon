#!/usr/bin/env lua

-- Test file for TOON format implementation

local toon = require("toon")

local tests_passed = 0
local tests_failed = 0

local function test(name, fn)
  io.write("Testing " .. name .. "... ")
  local success, err = pcall(fn)
  if success then
    io.write("✓\n")
    tests_passed = tests_passed + 1
  else
    io.write("✗\n")
    io.write("  Error: " .. tostring(err) .. "\n")
    tests_failed = tests_failed + 1
  end
end

local function assert_equals(actual, expected, message)
  if actual ~= expected then
    error((message or "Assertion failed") .. "\nExpected: " .. tostring(expected) .. "\nActual: " .. tostring(actual))
  end
end

local function assert_contains(str, substring, message)
  if not string.find(str, substring, 1, true) then
    error((message or "String does not contain expected substring") .. "\nString: " .. str .. "\nExpected substring: " .. substring)
  end
end

-- Test 1: Simple object encoding
test("simple object encoding", function()
  local data = {name = "Alice", age = 30, active = true}
  local result = toon.encode(data)
  assert_contains(result, "name: Alice")
  assert_contains(result, "age: 30")
  assert_contains(result, "active: true")
end)

-- Test 2: Nested object encoding
test("nested object encoding", function()
  local data = {
    user = {
      name = "Bob",
      email = "bob@example.com"
    }
  }
  local result = toon.encode(data)
  assert_contains(result, "user:")
  assert_contains(result, "name: Bob")
  assert_contains(result, "email: bob@example.com")
end)

-- Test 3: Inline primitive array
test("inline primitive array", function()
  local data = {colors = {"red", "green", "blue"}}
  local result = toon.encode(data)
  assert_contains(result, "colors[3]:")
  assert_contains(result, "red,green,blue")
end)

-- Test 4: Tabular array
test("tabular array encoding", function()
  local data = {
    users = {
      {id = 1, name = "Alice", score = 95},
      {id = 2, name = "Bob", score = 87},
      {id = 3, name = "Charlie", score = 92}
    }
  }
  local result = toon.encode(data)
  assert_contains(result, "users[3,]{id,name,score}:")
  assert_contains(result, "1,Alice,95")
  assert_contains(result, "2,Bob,87")
  assert_contains(result, "3,Charlie,92")
end)

-- Test 5: Empty array
test("empty array encoding", function()
  local data = {items = {}}
  local result = toon.encode(data)
  assert_contains(result, "items[0]:")
end)

-- Test 6: Boolean and null values
test("boolean and null values", function()
  local data = {
    enabled = true,
    disabled = false,
    empty = nil
  }
  local result = toon.encode(data)
  assert_contains(result, "disabled: false")
  assert_contains(result, "enabled: true")
end)

-- Test 7: Number encoding
test("number encoding", function()
  local data = {
    integer = 42,
    float = 3.14,
    negative = -17
  }
  local result = toon.encode(data)
  assert_contains(result, "integer: 42")
  assert_contains(result, "float: 3.14")
  assert_contains(result, "negative: -17")
end)

-- Test 8: String quoting
test("string quoting when needed", function()
  local data = {
    normal = "hello",
    needsQuotes = "has:colon",
    alsoNeeds = "true"
  }
  local result = toon.encode(data)
  assert_contains(result, 'normal: hello')
  assert_contains(result, '"has:colon"')
  assert_contains(result, '"true"')
end)

-- Test 9: List array with mixed content
test("list array encoding", function()
  local data = {
    tasks = {
      {task = "Review PR", priority = "high"},
      "Send email",
      {task = "Update docs", priority = "low"}
    }
  }
  local result = toon.encode(data)
  assert_contains(result, "tasks[3]:")
  assert_contains(result, "Review PR")
  assert_contains(result, "Send email")
  assert_contains(result, "high")
  assert_contains(result, "low")
end)

-- Test 10: Array of primitive arrays
test("array of arrays", function()
  local data = {
    matrix = {
      {1, 2, 3},
      {4, 5, 6},
      {7, 8, 9}
    }
  }
  local result = toon.encode(data)
  assert_contains(result, "matrix[3]:")
  assert_contains(result, "- [3]: 1,2,3")
  assert_contains(result, "- [3]: 4,5,6")
  assert_contains(result, "- [3]: 7,8,9")
end)

-- Test 11: Complex nested structure
test("complex nested structure", function()
  local data = {
    status = "success",
    data = {
      products = {
        {id = 101, name = "Laptop", price = 999.99},
        {id = 102, name = "Mouse", price = 29.99}
      }
    },
    meta = {
      page = 1,
      total = 2
    }
  }
  local result = toon.encode(data)
  assert_contains(result, "status: success")
  assert_contains(result, "products[2,]{id,name,price}:")
  assert_contains(result, "101,Laptop,999.99")
  assert_contains(result, "meta:")
  assert_contains(result, "page: 1")
end)

-- Test 12: Simple decode
test("simple decode", function()
  local toon_str = "name: Alice\nage: 30"
  local result = toon.decode(toon_str)
  assert_equals(result.name, "Alice")
  assert_equals(result.age, 30)
end)

-- Test 13: Decode inline array
test("decode inline array", function()
  local toon_str = "colors[3]: red,green,blue"
  local result = toon.decode(toon_str)
  assert_equals(result.colors[1], "red")
  assert_equals(result.colors[2], "green")
  assert_equals(result.colors[3], "blue")
end)

-- Test 14: Decode tabular array
test("decode tabular array", function()
  local toon_str = [[users[2,]{id,name}:
  1,Alice
  2,Bob]]
  local result = toon.decode(toon_str)
  assert_equals(result.users[1].id, 1)
  assert_equals(result.users[1].name, "Alice")
  assert_equals(result.users[2].id, 2)
  assert_equals(result.users[2].name, "Bob")
end)

-- Test 15: Roundtrip encode/decode
test("roundtrip encode/decode", function()
  local original = {
    name = "Test",
    value = 42,
    items = {"a", "b", "c"}
  }
  local encoded = toon.encode(original)
  local decoded = toon.decode(encoded)
  assert_equals(decoded.name, "Test")
  assert_equals(decoded.value, 42)
  assert_equals(decoded.items[1], "a")
  assert_equals(decoded.items[2], "b")
  assert_equals(decoded.items[3], "c")
end)

-- Print test results
print("\n" .. string.rep("=", 50))
print("Test Results:")
print("  Passed: " .. tests_passed)
print("  Failed: " .. tests_failed)
print(string.rep("=", 50))

if tests_failed == 0 then
  print("✓ All tests passed!")
  os.exit(0)
else
  print("✗ Some tests failed")
  os.exit(1)
end
