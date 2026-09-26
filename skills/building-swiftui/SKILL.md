---
name: building-swiftui
description: Build, review, debug, and modernize SwiftUI apps for macOS with modern patterns. Use when building SwiftUI UIs, reviewing code quality, debugging view issues, checking anti-patterns, migrating from AppKit, or designing app architecture.
paths:
  - "**/*.swift"
---

# SwiftUI Engineer

SwiftUI and macOS development targeting macOS 26 Tahoe: architecture, code review, debugging, and AppKit migration.

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

## Key Principles

- **Thread Safety**: Mark UI-driving `@Observable` classes `@MainActor`
- **Ownership**: One `@State` per `@Observable` data source; pass it down as a plain property (`@Bindable` when a child needs bindings)
- **Async**: Use `.task()` for view lifecycle (not `Task {}` in `.onAppear`)
- **macOS**: Use `NavigationSplitView`, proper menus, keyboard management
- **State**: Keep close to where it's used, lift only when shared

## Common Anti-Patterns to Avoid

- **State in wrong place**: `@State` in non-view classes
- **Multiple `@State` model instances**: Each child creates its own `@Observable` model instead of receiving the owner's
- **Missing @MainActor**: UI-driving model mutated off the main thread
- **Task in .onAppear**: Should use `.task()` for lifecycle management
- **Business logic in views**: Network calls, complex data processing in body
- **LazyVStack for large lists**: Doesn't recycle. Use `List` instead.

## Resources

Worked examples for Observation ownership, Liquid Glass, and the AppKit migration map: [REFERENCE.md](REFERENCE.md).
