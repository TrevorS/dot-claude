---
name: Swift Code Reviewer
description: Review Swift and SwiftUI code for best practices, anti-patterns, and macOS patterns. Use when reviewing code quality, checking for SwiftUI anti-patterns, validating async/await usage, improving state management, or analyzing macOS-specific issues.
---

# Swift Code Reviewer

Conduct thorough reviews of Swift and SwiftUI code with educational feedback on improvements, anti-patterns, and best practices.

## Instructions

When reviewing Swift code:

1. **Scan for anti-patterns**: Look for common SwiftUI mistakes (unnecessary re-renders, improper state management, view-based business logic)
2. **Check async/await usage**: Verify proper use of `async`, `await`, `.task()`, actor isolation, and structured concurrency
3. **Evaluate state management**: Ensure appropriate property wrapper usage (`@State` vs `@StateObject` vs `@ObservedObject`)
4. **Assess architecture**: Review separation of concerns (Views, ViewModels, Models, Services)
5. **Verify error handling**: Ensure proper error handling at appropriate abstraction levels
6. **Check macOS patterns**: Validate macOS-specific considerations (menus, window management, keyboard shortcuts)
7. **Accessibility**: Confirm accessibility labels and hints are appropriate
8. **Explain reasoning**: Always explain WHY something is an anti-pattern, not just what to fix

## Common Anti-Patterns to Flag

### 1. Improper State Management

```swift
// ❌ ANTI-PATTERN: State in a non-ViewModel class
class DataManager {
    @State var items: [Item] = [] // Wrong!
}

// ✅ CORRECT: Use @Published in ObservableObject
@MainActor
class DataManager: ObservableObject {
    @Published var items: [Item] = []
}
```

**Why**: `@State` is for View structs only. Use `@Published` for reference types.

### 2. View-Based Business Logic

```swift
// ❌ ANTI-PATTERN: Network calls in View body
struct ContentView: View {
    var body: some View {
        VStack {
            // Data fetching directly in view
        }
        .onAppear {
            let data = try? JSONDecoder().decode(...)
        }
    }
}

// ✅ CORRECT: Business logic in ViewModel
@MainActor
class ContentViewModel: ObservableObject {
    @Published var data: [Item] = []

    func loadData() async { ... }
}
```

**Why**: Separates concerns - makes code testable and maintainable.

### 3. Missing MainActor for UI Updates

```swift
// ❌ ANTI-PATTERN: Updating UI from background thread
class ViewModel: ObservableObject {
    @Published var items: [Item] = []

    func loadItems() async {
        let items = try await fetchRemote()
        self.items = items // Warning: Publishing changes from background thread!
    }
}

// ✅ CORRECT: Use @MainActor
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []

    func loadItems() async {
        let items = try await fetchRemote()
        self.items = items // Safe: executes on MainActor
    }
}
```

**Why**: Compile-time guarantee for thread safety on main thread.

### 4. Improper Async Handling

```swift
// ❌ ANTI-PATTERN: Using Task without proper handling
.onAppear {
    Task {
        let data = try await fetchData()
        self.data = data // Detached task, potential race conditions
    }
}

// ✅ CORRECT: Use .task() modifier for lifecycle management
.task {
    await loadData()
}
```

**Why**: `.task()` auto-cancels on disappear, preventing orphaned tasks and leaks.

### 5. Reference Cycles

```swift
// ❌ ANTI-PATTERN: Capturing self in closure
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    self.updateValue() // Reference cycle!
}

// ✅ CORRECT: Use weak self or let Swift manage it
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.updateValue()
}
```

**Why**: Prevents memory leaks from reference cycles.

### 6. Multiple @StateObject Instances (Critical Anti-Pattern)

```swift
// ❌ ANTI-PATTERN: Creates MULTIPLE independent instances!
struct ParentView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            ChildView1()  // Creates its own ViewModel instance
            ChildView2()  // Creates another ViewModel instance!
        }
    }
}

struct ChildView1: View {
    @StateObject private var viewModel = ViewModel()  // Wrong!
    var body: some View { Text("View 1") }
}

// ✅ CORRECT: Owner uses @StateObject, children use @ObservedObject
struct ParentView: View {
    @StateObject private var viewModel = ViewModel()  // Owner

    var body: some View {
        VStack {
            ChildView1(viewModel: viewModel)
            ChildView2(viewModel: viewModel)
        }
    }
}

struct ChildView1: View {
    @ObservedObject var viewModel: ViewModel  // Observer, same instance
    var body: some View { Text("View 1") }
}
```

**Why**: Multiple @StateObjects create independent instances. Only owner uses @StateObject. ([Docs](https://developer.apple.com/documentation/swiftui/stateobject))

## Performance: List vs LazyVStack (Documented Best Practice)

```swift
// ❌ PROBLEMATIC: LazyVStack doesn't recycle views
ScrollView {
    LazyVStack {
        ForEach(largeArray) { item in
            ItemCell(item: item)
        }
    }
}

// ✅ CORRECT: List recycles views like UITableView
List {
    ForEach(largeArray) { item in
        ItemCell(item: item)
    }
}
```

**Rule**: Use `List` for large datasets (recycles views, memory efficient). `LazyVStack` only defers creation—it doesn't recycle, so all views stay in memory. For debugging performance issues, see [Swift Debugger skill](swift-debugger).

## Review Checklist

- [ ] **Property wrappers**: Correct for context? (@StateObject only in owners, @ObservedObject in children?)
- [ ] **Ownership pattern**: No multiple @StateObject instances creating duplicate data?
- [ ] **Thread safety**: Do UI updates happen on main thread? (@MainActor on ViewModels?)
- [ ] **Async/await**: Is `.task()` used instead of `Task {}` in `.onAppear`?
- [ ] **Memory management**: Any reference cycles or weak/unowned misuse?
- [ ] **Error handling**: Are errors handled appropriately at correct abstraction level?
- [ ] **Testability**: Can this code be tested easily?
- [ ] **Performance**: List for large collections, not LazyVStack? Any unnecessary re-renders?
- [ ] **macOS patterns**: NavigationSplitView used? Menu commands defined?
- [ ] **Accessibility**: Views properly annotated with labels/hints?
- [ ] **Style**: Swift naming and code style conventions followed?

## Feedback Format

Provide feedback structured as:

1. **Summary**: One sentence on overall code quality
2. **Strengths**: What the code does well (be genuine)
3. **Improvements** (rated by importance):
   - 🔴 Critical (bugs, memory leaks, crashes)
   - 🟡 Important (anti-patterns, performance issues)
   - 🟢 Nice-to-have (style, minor improvements)
4. **Example fixes**: Show before/after for key improvements
5. **Learning notes**: Explain why each change matters

## Modern Best Practices (iOS 17+, macOS 14+)

For iOS 17+ and macOS 14+, consider using `@Observable` macro instead of `ObservableObject + @Published`. It's simpler and Apple's recommended approach for new code. See [SwiftUI Architect skill](swift-swiftui-architect) for full details.

## macOS-Specific Considerations

- **Navigation**: Verify `NavigationSplitView` is used (recommended over deprecated NavigationView)
- **Window commands**: Check proper use of `.commands()` and `CommandMenu`
- **Keyboard shortcuts**: Verify `@FocusState` is used for focus management, `.keyboardShortcut()` for commands
- **Menu integration**: System menus follow macOS conventions (File, Edit, View, etc.)
- **Responder chain**: Validate first responder behavior and tab order with `.focusable()`
- **Materials**: Use appropriate material blur levels (.ultraThinMaterial, .thinMaterial, .regularMaterial)
- **Liquid Glass**: Check Liquid Glass materials are used appropriately for macOS 26
- **Spaces/Exposé**: Consider multi-window behavior and workspace awareness

## When to Deep Dive

Ask follow-up questions for deeper review:

- "What's the expected size of the items array?"
- "Could this trigger memory warnings with large datasets? Should we use List instead?"
- "Is this called frequently? Should we add caching or memoization?"
- "How does this integrate with the rest of the app? Any shared ViewModels?"
- "What's the minimum macOS version? Can we use @Observable macro?"
- "Are there accessibility requirements beyond standard VoiceOver support?"
