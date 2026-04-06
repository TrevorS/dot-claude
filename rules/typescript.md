---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript / JavaScript

- Package manager: prefer `bun`, fallback to `pnpm` or `yarn`
- New projects: use framework-specific scaffolds (`create-next-app`, `create-svelte`, `bun create`, `bun init`)
- Avoid `enum` in new code -- prefer `as const` objects or union types
