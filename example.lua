#!/usr/bin/env lua5.3

local toon = require("toon")

print("=== TOON for Lua - Examples ===\n")

-- Example 1: Encode a simple object
print("Example 1: Simple Object")
local user = {
    name = "Alice",
    age = 30,
    active = true
}
print("Lua table:")
for k, v in pairs(user) do
    print("  " .. k .. " = " .. tostring(v))
end
print("\nTOON encoded:")
print(toon.encode(user))
print()

-- Example 2: Encode a primitive array
print("Example 2: Primitive Array")
local numbers = {1, 2, 3, 4, 5}
print("Lua array: {1, 2, 3, 4, 5}")
print("TOON encoded:")
print(toon.encode(numbers))
print()

-- Example 3: Encode a tabular array (uniform objects)
print("Example 3: Tabular Array (Uniform Objects)")
local users = {
    {id = 1, name = "Alice", role = "admin"},
    {id = 2, name = "Bob", role = "user"},
    {id = 3, name = "Charlie", role = "user"}
}
print("Lua array of objects:")
for i, u in ipairs(users) do
    print(string.format("  [%d] id=%d, name=%s, role=%s", i, u.id, u.name, u.role))
end
print("\nTOON encoded:")
print(toon.encode(users))
print()

-- Example 4: Nested objects
print("Example 4: Nested Objects")
local config = {
    server = {
        host = "localhost",
        port = 8080
    },
    database = {
        name = "mydb",
        user = "admin"
    }
}
print("Lua nested table:")
print("  server.host = " .. config.server.host)
print("  server.port = " .. config.server.port)
print("  database.name = " .. config.database.name)
print("  database.user = " .. config.database.user)
print("\nTOON encoded:")
print(toon.encode(config))
print()

-- Example 5: Object with array
print("Example 5: Object with Array")
local data = {
    title = "Shopping List",
    items = {"milk", "eggs", "bread"}
}
print("Lua table with array:")
print("  title = " .. data.title)
print("  items = {milk, eggs, bread}")
print("\nTOON encoded:")
print(toon.encode(data))
print()

-- Example 6: Decode TOON back to Lua
print("Example 6: Decode TOON")
local toon_text = "name: Alice\nage: 30\nactive: true"
print("TOON input:")
print(toon_text)
print("\nDecoded to Lua:")
local decoded = toon.decode(toon_text)
for k, v in pairs(decoded) do
    print("  " .. k .. " = " .. tostring(v))
end
print()

-- Example 7: Round-trip encoding and decoding
print("Example 7: Round-trip (Encode then Decode)")
local original = {
    users = {
        {id = 1, name = "Alice"},
        {id = 2, name = "Bob"}
    },
    count = 2
}
print("Original Lua table:")
print("  count = " .. original.count)
print("  users = tabular array with 2 entries")

local encoded = toon.encode(original)
print("\nTOON encoded:")
print(encoded)

local decoded = toon.decode(encoded)
print("\nDecoded back to Lua:")
print("  count = " .. tostring(decoded.count))
if decoded.users then
    print("  users[1].name = " .. tostring(decoded.users[1].name))
    print("  users[2].name = " .. tostring(decoded.users[2].name))
end
print()

print("=== Examples Complete ===")
