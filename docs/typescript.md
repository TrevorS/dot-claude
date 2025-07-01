# TypeScript / JavaScript Development Instructions

## Language and Environment

- Prefer **TypeScript** over **JavaScript**
- Use `fnm` to manage `Node.js` versions
- Use `pnpm` for package management (`pnpm add`, `pnpm run`, etc...)
- Prefer `const` over `let`, and `let` over `var`
- Use `import` statements instead of `require`
- Use `async/await` for asynchronous code instead of callbacks or promises

## Error Handling

- Use explicit error handling with try/catch blocks for async operations
- Handle errors at the appropriate abstraction level
- Always log error context, never swallow errors silently
- Use Error objects or custom error classes for throwing errors
- Validate inputs and handle edge cases gracefully
- Include error scenarios in test coverage

## Code Style and Formatting

- Use descriptive variable names following camelCase convention
- Use PascalCase for classes, interfaces, and types
- Keep line length reasonable (typically 100-120 characters)
- Use template literals for string interpolation
- Prefer object destructuring when extracting multiple properties
- Use optional chaining (?.) and nullish coalescing (??) operators appropriately

## Type Safety

- Enable strict TypeScript compiler options
- Use explicit types for function parameters and return values
- Avoid `any` type unless absolutely necessary
- Use union types and type guards for handling different data shapes
- Leverage TypeScript's built-in utility types (Partial, Required, etc.)
- Use interfaces for object shapes and types for unions/primitives

## Testing

- Use Jest or Vitest as the testing framework unless project uses different framework
- Write tests in `*.test.ts` or `*.spec.ts` files
- Use descriptive test names that explain the expected behavior
- Mock external dependencies and API calls in unit tests
- Use type assertions in tests when necessary for type safety
- Test both success and error scenarios

## Security Practices

- Never hardcode sensitive information (API keys, tokens, secrets)
- Use environment variables for configuration
- Validate all external inputs at system boundaries
- Sanitize user inputs to prevent XSS attacks
- Use HTTPS for all external API calls
- Regularly update dependencies for security patches
