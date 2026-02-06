# Security Considerations

This document outlines security considerations for the lua-toon implementation.

## Input Validation

### String Escaping
- The implementation correctly escapes only the five valid escape sequences per TOON spec: `\\`, `\"`, `\n`, `\r`, `\t`
- Any other escape sequences are not generated during encoding
- During decoding, invalid escape sequences should be rejected (current implementation accepts them - this is a known limitation)

### Number Handling
- Numbers are normalized to prevent issues with -0, NaN, and Infinity
- Large numbers may lose precision in Lua's native number type
- Leading zeros are correctly detected and handled as strings

### Quoting Rules
- Strings are quoted when necessary to prevent injection attacks
- Delimiter-aware quoting prevents delimiter confusion attacks
- Empty strings are always quoted

## Injection Risks

### Command Injection
- The library does not execute any system commands
- No `os.execute()` or `io.popen()` calls

### Code Injection
- No use of `loadstring()` or `dofile()`
- No dynamic code execution

### Delimiter Confusion
- Active delimiter is properly scoped per array header
- Delimiter-aware quoting prevents parsing ambiguities
- Non-active delimiters in strings do not cause splits

## Resource Limits

### Stack Depth
- Deeply nested structures may cause stack overflow in recursive encoding
- No explicit depth limit is enforced (consider adding in production use)

### Memory Usage
- Large arrays and objects may consume significant memory
- No streaming support - entire document must fit in memory
- Consider implementing size limits for untrusted input

## Recommendations for Production Use

1. **Add input size limits**: Limit the size of input strings to prevent memory exhaustion
2. **Add depth limits**: Limit nesting depth to prevent stack overflow
3. **Validate untrusted input**: If decoding untrusted TOON input, consider additional validation
4. **Error handling**: Current implementation has basic error handling; enhance for production use
5. **Strict mode**: Implement full strict mode validation for security-critical applications

## Known Limitations

1. **Strict mode validation**: Not fully implemented (count validation, indentation validation)
2. **Invalid escape handling**: Decoder may accept invalid escape sequences instead of rejecting them
3. **Large number precision**: May lose precision for very large integers or decimals
4. **No streaming**: Must load entire document into memory

## Reporting Security Issues

Please report security issues to the repository maintainers.
