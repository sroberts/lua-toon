#!/usr/bin/env lua

--[[
  Example usage of the TOON library
  Demonstrates various encoding scenarios and token savings
]]

local toon = require("toon")

print("====================================")
print("TOON Format Examples for Lua")
print("====================================\n")

-- Example 1: Simple object
print("Example 1: Simple Object")
print("-------------------------")
local user = {
  name = "Alice",
  age = 30,
  active = true,
  role = "admin"
}
print("Input: {name='Alice', age=30, active=true, role='admin'}")
print("\nTOON Output:")
print(toon.encode(user))
print()

-- Example 2: Nested object
print("Example 2: Nested Object")
print("-------------------------")
local profile = {
  user = {
    name = "Bob",
    contact = {
      email = "bob@example.com",
      phone = "+1-555-0123"
    }
  },
  settings = {
    theme = "dark",
    notifications = true
  }
}
print("TOON Output:")
print(toon.encode(profile))
print()

-- Example 3: Inline array
print("Example 3: Inline Array (Primitives)")
print("-------------------------------------")
local colors = {
  palette = {"red", "green", "blue", "yellow", "purple"}
}
print("Input: {palette={'red', 'green', 'blue', 'yellow', 'purple'}}")
print("\nTOON Output:")
print(toon.encode(colors))
print()

-- Example 4: Tabular array
print("Example 4: Tabular Array (Uniform Objects)")
print("-------------------------------------------")
local products = {
  items = {
    {id = 101, name = "Laptop", price = 999.99, stock = 15},
    {id = 102, name = "Mouse", price = 29.99, stock = 150},
    {id = 103, name = "Keyboard", price = 79.99, stock = 45},
    {id = 104, name = "Monitor", price = 399.99, stock = 30}
  }
}
print("TOON Output:")
print(toon.encode(products))
print()

-- Example 5: List array with mixed content
print("Example 5: List Array (Mixed Content)")
print("--------------------------------------")
local tasks = {
  todos = {
    "Buy groceries",
    {task = "Review code", priority = "high", assignee = "Alice"},
    "Call dentist",
    {task = "Write docs", priority = "medium", assignee = "Bob"}
  }
}
print("TOON Output:")
print(toon.encode(tasks))
print()

-- Example 6: Complex nested structure
print("Example 6: Complex Nested Structure")
print("------------------------------------")
local api_response = {
  status = "success",
  timestamp = "2024-11-24T10:30:00Z",
  data = {
    users = {
      {id = 1, name = "Alice", email = "alice@example.com"},
      {id = 2, name = "Bob", email = "bob@example.com"},
      {id = 3, name = "Charlie", email = "charlie@example.com"}
    },
    stats = {
      total = 3,
      active = 2,
      inactive = 1
    }
  },
  meta = {
    page = 1,
    per_page = 10,
    total_pages = 1
  }
}
print("TOON Output:")
print(toon.encode(api_response))
print()

-- Example 7: Decode demonstration
print("Example 7: Decoding TOON")
print("------------------------")
local toon_str = [[
product: Laptop
price: 999.99
specs:
  cpu: Intel i7
  ram: 16
  storage: 512
tags[3]: computer,electronics,portable
]]
print("TOON Input:")
print(toon_str)
print("\nDecoded Lua table:")
local decoded = toon.decode(toon_str)
print("  product: " .. tostring(decoded.product))
print("  price: " .. tostring(decoded.price))
print("  specs.cpu: " .. tostring(decoded.specs.cpu))
print("  specs.ram: " .. tostring(decoded.specs.ram))
print("  tags[1]: " .. tostring(decoded.tags[1]))
print("  tags[2]: " .. tostring(decoded.tags[2]))
print("  tags[3]: " .. tostring(decoded.tags[3]))
print()

-- Example 8: Token savings comparison
print("Example 8: Token Savings")
print("------------------------")
local data = {
  users = {
    {id = 1, name = "Alice", email = "alice@example.com", age = 30},
    {id = 2, name = "Bob", email = "bob@example.com", age = 25},
    {id = 3, name = "Charlie", email = "charlie@example.com", age = 35}
  }
}

-- Simulate JSON encoding (rough approximation)
local json_like = [[{
  "users": [
    {"id": 1, "name": "Alice", "email": "alice@example.com", "age": 30},
    {"id": 2, "name": "Bob", "email": "bob@example.com", "age": 25},
    {"id": 3, "name": "Charlie", "email": "charlie@example.com", "age": 35}
  ]
}]]

local toon_output = toon.encode(data)

print("Approximate JSON length: " .. #json_like .. " characters")
print("TOON length: " .. #toon_output .. " characters")
local savings = math.floor((1 - #toon_output / #json_like) * 100)
print("Token savings: ~" .. savings .. "%")
print()
print("TOON Output:")
print(toon_output)
print()

print("====================================")
print("All examples completed!")
print("====================================")
