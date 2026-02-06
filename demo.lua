#!/usr/bin/env lua5.3

local toon = require("toon")

print("=== TOON Format Demonstration ===\n")

-- Example: Comprehensive data structure
local dataset = {
    metadata = {
        version = "1.0",
        created = "2024-01-15",
        source = "sample-data"
    },
    users = {
        {id = 1, name = "Alice Johnson", email = "alice@example.com", active = true},
        {id = 2, name = "Bob Smith", email = "bob@example.com", active = true},
        {id = 3, name = "Carol White", email = "carol@example.com", active = false}
    },
    stats = {
        total = 3,
        active = 2,
        inactive = 1
    },
    tags = {"production", "verified", "2024"}
}

print("Original Lua data structure:")
print("------------------------------")
print("metadata:")
print("  version: " .. dataset.metadata.version)
print("  created: " .. dataset.metadata.created)
print("users: array of 3 objects with id, name, email, active")
print("stats: object with total, active, inactive")
print("tags: array of 3 strings")
print()

print("Encoded to TOON format:")
print("------------------------------")
local encoded = toon.encode(dataset)
print(encoded)
print()

print("Key features demonstrated:")
print("------------------------------")
print("✓ Nested objects (metadata, stats)")
print("✓ Tabular array format for uniform objects (users)")
print("✓ Simple inline array for primitives (tags)")
print("✓ Minimal quoting (only where necessary)")
print("✓ Clear indentation structure")
print("✓ Explicit array lengths [N]")
print()

-- Decode it back
local decoded = toon.decode(encoded)

print("Decoded validation:")
print("------------------------------")
print("metadata.version: " .. tostring(decoded.metadata and decoded.metadata.version))
print("stats.total: " .. tostring(decoded.stats and decoded.stats.total))
if decoded.users then
    print("users count: " .. #decoded.users)
    if decoded.users[1] then
        print("users[1].name: " .. decoded.users[1].name)
    end
end
if decoded.tags then
    print("tags: " .. table.concat(decoded.tags, ", "))
end
print()

-- Show size comparison with JSON-like representation
print("Format efficiency:")
print("------------------------------")
local manual_json_like = [[{
  "metadata": {
    "version": "1.0",
    "created": "2024-01-15",
    "source": "sample-data"
  },
  "users": [
    {"id": 1, "name": "Alice Johnson", "email": "alice@example.com", "active": true},
    {"id": 2, "name": "Bob Smith", "email": "bob@example.com", "active": true},
    {"id": 3, "name": "Carol White", "email": "carol@example.com", "active": false}
  ],
  "stats": {
    "total": 3,
    "active": 2,
    "inactive": 1
  },
  "tags": ["production", "verified", "2024"]
}]]

print("Approximate JSON size: " .. #manual_json_like .. " bytes")
print("TOON size: " .. #encoded .. " bytes")
print("Savings: ~" .. math.floor((1 - #encoded / #manual_json_like) * 100) .. "%")
print()

print("TOON advantages:")
print("------------------------------")
print("• Tabular format for uniform arrays (no key repetition)")
print("• Explicit array counts (helps detect truncation)")
print("• Minimal quoting (better readability)")
print("• Indentation-based structure (familiar to Python/YAML users)")
print("• Deterministic formatting (good for diffs)")
print()

print("=== Demonstration Complete ===")
