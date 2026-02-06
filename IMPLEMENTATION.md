# TOON Implementation for Lua

## Overview

This is an initial implementation of the TOON (Token-Oriented Object Notation) format for Lua, compliant with TOON Specification v3.0.

## Implementation Status

### ✅ Fully Implemented

#### Encoder
- [x] Primitive types (string, number, boolean, nil)
- [x] Objects with key-value pairs
- [x] Nested objects
- [x] Inline primitive arrays: `[N]: v1,v2,v3`
- [x] Tabular arrays (uniform objects): `[N]{f1,f2}: ...`
- [x] Mixed/list arrays
- [x] Canonical number formatting (no exponent notation, normalized)
- [x] Quoting rules per TOON spec
- [x] String escaping: `\\`, `\"`, `\n`, `\r`, `\t`
- [x] Delimiter support: comma (default), tab, pipe
- [x] Configurable indentation (default 2 spaces)

#### Decoder
- [x] Parse primitives (string, number, boolean, null)
- [x] Parse objects
- [x] Parse inline primitive arrays
- [x] Parse tabular arrays
- [x] Parse list arrays
- [x] Unescape strings
- [x] Type inference for unquoted values
- [x] Header parsing with length and field lists
- [x] Delimiter-based splitting

#### Quality
- [x] 28 automated tests (all passing)
- [x] Comprehensive test suite
- [x] Example code
- [x] Demo application
- [x] Full documentation
- [x] Security considerations documented

### ⚠️ Partially Implemented

- [ ] Strict mode validation (basic structure only)
  - Missing: Array count validation
  - Missing: Indentation consistency checks
  - Missing: Delimiter consistency validation
- [ ] Objects as list items (basic support, not all edge cases)
- [ ] Complex nested array structures (basic support)

### ❌ Not Implemented

- [ ] Path expansion (§13.4)
- [ ] Key folding (§13.4)
- [ ] Tab and pipe delimiters (structure exists, not fully tested)
- [ ] Full strict mode error reporting
- [ ] Streaming support
- [ ] Input size/depth limits

## File Structure

```
lua-toon/
├── toon.lua              - Main library (encoder and decoder)
├── test.lua              - Unit tests (28 tests)
├── comprehensive_test.lua - Edge case tests
├── example.lua           - Usage examples
├── demo.lua              - Feature demonstration
├── README.md             - User documentation
├── SECURITY.md           - Security considerations
├── IMPLEMENTATION.md     - This file
└── spec.md               - TOON spec reference
```

## Architecture

### Encoder (`toon.encode`)

1. **Type Detection**: Determines if value is primitive, object, or array
2. **Array Classification**:
   - Primitive array → inline format
   - Uniform objects with primitive values → tabular format
   - Mixed content → list format
3. **Quoting**: Applies quoting rules based on content and delimiter
4. **Formatting**: Generates indented, line-oriented output

### Decoder (`toon.decode`)

1. **Root Form Detection**: Determines if input is primitive, object, or array
2. **Header Parsing**: Extracts array length, delimiter, field list
3. **Line Processing**: Parses lines based on depth and content
4. **Type Inference**: Converts unquoted tokens to appropriate types
5. **Structure Building**: Assembles nested objects and arrays

## Performance Characteristics

- **Time Complexity**: O(n) for flat structures, O(n*m) for nested
- **Space Complexity**: O(n) - entire document in memory
- **Bottlenecks**: 
  - String concatenation in encoder
  - Pattern matching in decoder
  - No optimization for large datasets

## Conformance

This implementation aims for conformance with:
- §2 Data Model ✅
- §3 Encoding Normalization ✅
- §4 Decoding Interpretation ✅ (mostly)
- §5 Concrete Syntax ✅
- §6 Header Syntax ✅
- §7 Strings and Keys ✅
- §8 Objects ✅
- §9 Arrays ✅
- §10 Objects as List Items ⚠️ (partial)
- §11 Delimiters ⚠️ (partial)
- §12 Indentation and Whitespace ✅ (encoding only)
- §13 Conformance and Options ⚠️ (partial)

## Testing

Run all tests:
```bash
lua5.3 test.lua                    # Unit tests
lua5.3 comprehensive_test.lua      # Edge cases
lua5.3 example.lua                 # Examples
lua5.3 demo.lua                    # Feature demo
```

## Known Issues

1. **Decoder complexity**: The decoder uses a simplified line-by-line approach that doesn't handle all edge cases from the spec
2. **Strict mode**: Not fully validated (counts, indentation, delimiters)
3. **Number precision**: Very large numbers may lose precision in Lua's number type
4. **Memory usage**: No streaming support, entire document must fit in memory
5. **Error handling**: Basic error handling, could be more comprehensive

## Future Improvements

1. Implement full strict mode validation
2. Add depth and size limits for security
3. Optimize for large datasets
4. Add streaming support
5. Improve error messages
6. Add more comprehensive tests
7. Support tab and pipe delimiters fully
8. Implement path expansion and key folding options

## License

See LICENSE file.
