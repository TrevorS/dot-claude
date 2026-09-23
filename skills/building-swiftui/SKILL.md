---
name: building-swiftui
description: Build, review, debug, and modernize SwiftUI apps for macOS with modern patterns. Use when building SwiftUI UIs, reviewing code quality, debugging view issues, checking anti-patterns, migrating from AppKit, or designing app architecture.
paths:
  - "**/*.swift"
---

# SwiftUI Engineer

Comprehensive support for SwiftUI and macOS development across the full development lifecycle: architecture, code review, debugging, and modernization. Focused on macOS 26 Tahoe patterns and best practices.

## Modes of Operation

Choose the mode that matches your task:

### 1. Architecture Mode

**Use when**: Building SwiftUI views, designing components, planning app structure

- Generate production-ready SwiftUI code
- Apply macOS-appropriate patterns
- Create reusable components
- Structure for testability
- Use modern property wrappers correctly

**Ask**: What are you building? What data does it work with? Does it need to be responsive?

### 2. Review Mode

**Use when**: Checking code quality, looking for anti-patterns, validating patterns

- Scan for SwiftUI anti-patterns
- Verify state management correctness
- Check async/await patterns
- Validate thread safety (@MainActor)
- Assess architecture and separation of concerns

**Ask**: Show me the code. What specific concern do you have?

### 3. Debug Mode

**Use when**: Debugging crashes, performance issues, rendering problems, mysterious behavior

- Diagnose view update issues
- Identify state management problems
- Solve reference cycles and memory leaks
- Find performance bottlenecks
- Debug threading and async issues

**Ask**: What exactly is happening? When does it occur? What have you tried?

### 4. Modernize Mode

**Use when**: Migrating from AppKit, updating deprecated APIs, planning upgrades

- Map AppKit patterns to SwiftUI
- Handle API deprecations
- Explain breaking changes
- Provide migration strategies
- Preserve functionality during transitions

**Ask**: What's the scope? What's your timeline? Do you have test coverage?

## Quick Reference: Common Patterns

### State Management

**Correct pattern** (Observation framework, macOS 14+; the only pattern for macOS 26 code):

- Model: `@Observable final class Model` — plain stored properties, no `@Published`
- Owner: `@State private var model = Model()`
- Child (read): `let model: Model` — a plain property, no wrapper
- Child (two-way bindings): `@Bindable var model: Model`
- Main-thread isolation still comes from `@MainActor` on the class when it drives UI

**Why**: `@State` owns the instance; children observe it through plain properties. Views update only on the specific properties they read, and optionals and collections are tracked. `ObservableObject` / `@Published` / `@StateObject` / `@ObservedObject` are the pre-Observation API; use them only in code that must run on macOS 13 or earlier.

### Navigation (macOS)

**Use NavigationSplitView** (not deprecated NavigationView). See REFERENCE.md for detailed example.

### Async/Await

**Use `.task()` in views**, not `Task {}` in `.onAppear`:

```swift
.task {
    await loadData()  // Auto-cancels on disappear
}
```

### macOS 26 Tahoe: Liquid Glass

Liquid Glass is `.glassEffect()` (with `Glass` styles such as `.regular` / `.clear`, and `in:` for a shape), grouped in a `GlassEffectContainer` when several glass views sit together so they can merge and morph. `.ultraThinMaterial` is the pre-Tahoe material API, not Liquid Glass. See REFERENCE.md for examples.

## Workflow for Each Mode

### Architecture: Generate SwiftUI Code

1. Understand the requirement
2. Choose appropriate pattern (MVVM, component hierarchy)
3. Apply macOS standards (8pt grid spacing, NavigationSplitView)
4. Include accessibility labels
5. Explain design decisions

### Review: Assess Code Quality

1. Check property wrappers for correctness
2. Verify `@State` ownership of `@Observable` models (one owner, children get plain properties)
3. Validate thread safety (@MainActor usage)
4. Check async/await patterns
5. Identify anti-patterns and improvements
6. Explain why each issue matters

### Debug: Root Cause Analysis

1. Gather information (symptoms, steps to reproduce, error messages)
2. Form hypothesis based on symptoms
3. Guide systematic debugging
4. Identify root cause
5. Provide targeted fix
6. Explain prevention for future

### Modernize: Migration Planning

1. Assess current architecture
2. Plan incremental migration (don't rewrite everything at once)
3. Map AppKit to SwiftUI equivalents
4. Handle API deprecations
5. Preserve functionality
6. Provide migration checklist

## Key Principles

- **Thread Safety**: Mark UI-driving `@Observable` classes `@MainActor`
- **Ownership**: One `@State` per `@Observable` data source; pass it down as a plain property (`@Bindable` when a child needs bindings)
- **Async**: Use `.task()` for view lifecycle (not `Task {}` in `.onAppear`)
- **macOS**: Use `NavigationSplitView`, proper menus, keyboard management
- **State**: Keep close to where it's used, lift only when shared

## Common Anti-Patterns to Avoid

❌ **State in wrong place**: `@State` in non-view classes
❌ **Multiple `@State` model instances**: Each child creates its own `@Observable` model instead of receiving the owner's
❌ **Missing @MainActor**: Publishing from background thread
❌ **Task in .onAppear**: Should use `.task()` for lifecycle management
❌ **Business logic in views**: Network calls, complex data processing in body
❌ **LazyVStack for large lists**: Doesn't recycle. Use `List` instead.

## When to Use Each Mode

| Need                        | Mode         |
| --------------------------- | ------------ |
| Build a new view            | Architecture |
| Check if code is good       | Review       |
| App is crashing             | Debug        |
| Fix rendering issue         | Debug        |
| Find performance problem    | Debug        |
| Update to new Swift version | Review       |
| Migrate from AppKit         | Modernize    |
| Fix anti-pattern            | Review       |
| Design new component        | Architecture |

## Resources

For detailed examples, anti-patterns, debugging techniques, and migration strategies, see [REFERENCE.md](REFERENCE.md).

## Questions Before Starting

**Architecture**:

- What is the primary purpose?
- What data does it manage?
- Does it need responsive/adaptive layout?

**Review**:

- What specific concern?
- Performance, correctness, or style?

**Debug**:

- What exactly is happening?
- When does it occur?
- What have you already tried?

**Modernize**:

- What's the scope (single view or whole app)?
- Timeline and priority?
- Do you have test coverage?
