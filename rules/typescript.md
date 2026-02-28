---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript / JavaScript

## Tooling

- Package manager: prefer `pnpm`, fallback to `yarn` or `bun`
- Node version: `fnm` (check `.node-version` or `.nvmrc`)
- New projects: use framework-specific scaffolds (`create-next-app`, `create-svelte`, `pnpm create`, `bun init`)

## TypeScript Strictness

- Enable all strict compiler options — no `any` types
- Use `unknown` instead of `any` for truly unknown types, then narrow
- Prefer `interface` for object shapes, `type` for unions and intersections
- Use `as const` for literal types and discriminated unions

## Code Patterns

- Prefer `const` over `let` — never use `var`
- Use template literals over string concatenation
- Use optional chaining (`?.`) and nullish coalescing (`??`)
- Prefer `async`/`await` over raw Promise chains
- Use `Map`/`Set` over plain objects for dynamic key collections

## Common Mistakes to Avoid

- NEVER use `==` — always `===`
- NEVER use `any` to silence type errors — fix the types
- NEVER use `@ts-ignore` — use `@ts-expect-error` with a comment if truly needed
- Avoid `enum` in new code — prefer `as const` objects or union types

## Testing

- Check project for existing test framework (vitest, jest, playwright)
- Match existing test patterns in the project
