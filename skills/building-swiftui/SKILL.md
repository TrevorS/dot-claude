---
name: building-swiftui
description: Build, review, debug, and modernize SwiftUI apps for macOS with modern patterns. Use when building SwiftUI UIs, reviewing code quality, debugging view issues, checking anti-patterns, migrating from AppKit, or designing app architecture.
---

# SwiftUI Engineer

Comprehensive support for SwiftUI and macOS development across the full development lifecycle: architecture, code review, debugging, and modernization. Focused on macOS 26 Tahoe patterns and best practices.

## Quick Reference: Common Patterns

### State Management

**Correct pattern**:

- Owner: `@StateObject private var viewModel = ViewModel()`
- Child: `@ObservedObject var viewModel: ViewModel`
- ViewModel: `@MainActor class ViewModel: ObservableObject`

**Why**: Only owner creates instance. Children observe shared instance. @MainActor ensures thread-safe UI updates.

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

Use `.background(.ultraThinMaterial)` for adaptive backgrounds. See REFERENCE.md for examples.

## Workflow for Each Mode

### Architecture: Generate SwiftUI Code

1. Understand the requirement
2. Choose appropriate pattern (MVVM, component hierarchy)
3. Apply macOS standards (8pt grid spacing, NavigationSplitView)
4. Include accessibility labels
5. **Verify**: `swift build` succeeds with zero warnings; preview renders in Xcode canvas

### Review: Assess Code Quality

1. Check property wrappers for correctness
2. Verify @StateObject ownership pattern
3. Validate thread safety (@MainActor usage)
4. Check async/await patterns
5. Identify anti-patterns and improvements
6. **Verify**: `swift build 2>&1 | grep -c warning` returns 0 after applying fixes

### Debug: Root Cause Analysis

1. Gather information (symptoms, steps to reproduce, error messages)
2. Form hypothesis based on symptoms
3. Guide systematic debugging
4. Identify root cause and provide targeted fix
5. **Verify**: Reproduce original issue to confirm fix resolves it

### Modernize: Migration Planning

1. Assess current architecture
2. Plan incremental migration (don't rewrite everything at once)
3. Map AppKit to SwiftUI equivalents
4. Handle API deprecations
5. **Verify**: Each migrated component builds and behaves identically

## Common Anti-Patterns

❌ **Task in .onAppear** → use `.task()`:

```swift
// Wrong
.onAppear { Task { await loadData() } }
// Right
.task { await loadData() }  // Auto-cancels on disappear
```

❌ **Multiple @StateObject instances** → share via @ObservedObject:

```swift
// Wrong: each child creates its own instance
struct ChildView: View {
    @StateObject var vm = ViewModel()  // New instance each time
}
// Right: parent owns, child observes
struct ChildView: View {
    @ObservedObject var vm: ViewModel  // Shared instance
}
```

❌ **Missing @MainActor**: Publishing from background thread
❌ **Business logic in views**: Network calls, complex data processing in body
❌ **LazyVStack for large lists**: Doesn't recycle — use `List` instead

## Resources

For detailed examples, debugging techniques, and migration strategies, see [REFERENCE.md](REFERENCE.md).
