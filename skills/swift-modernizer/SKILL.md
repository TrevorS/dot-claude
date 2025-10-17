---
name: Swift Modernizer
description: Migrate AppKit code to SwiftUI and update for macOS Tahoe APIs. Use when modernizing legacy macOS apps, updating to SwiftUI, migrating AppKit views, handling API deprecations, or planning macOS version upgrades.
---

# Swift Modernizer

Guide migration of legacy macOS code to modern SwiftUI patterns and macOS 26 Tahoe APIs with educational explanations and incremental strategies.

## Instructions

When modernizing Swift code:

1. **Assess current architecture**: Identify AppKit patterns, older Swift versions, deprecated APIs
2. **Plan incremental migration**: Suggest a phased approach rather than big-bang rewrites
3. **Identify SwiftUI equivalents**: Map AppKit classes to SwiftUI views and patterns
4. **Handle breaking changes**: Explain API deprecations and modern alternatives
5. **Preserve functionality**: Ensure no features are lost during migration
6. **Explain trade-offs**: Discuss benefits and limitations of each approach
7. **Provide migration path**: Give step-by-step guidance with examples

## AppKit to SwiftUI Mapping

### Window Management (macOS Tahoe)

```swift
// ❌ OLD (AppKit)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(...)
        window.makeKeyAndOrderFront(nil)
    }
}

// ✅ NEW (SwiftUI)
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)  // macOS 26 styles available
        .windowResizability(.contentMinSize(CGSize(width: 400, height: 300)))
    }
}
```

**Migration notes**:

- SwiftUI handles window lifecycle automatically via `@main` and `App` protocol
- Window styling updated for macOS 26 Tahoe
- Reference: [WWDC 2025 SwiftUI Updates](https://developer.apple.com/documentation/swiftui/building-a-great-mac-app-with-swiftui)

### Basic AppKit Mappings

Claude already knows these equivalents - focus on migration strategy instead of mapping basics.

## macOS 26 Tahoe Updates

### Liquid Glass Material Migration

For full Liquid Glass code examples and characteristics, see [SwiftUI Architect skill](swift-swiftui-architect).

**Migration Strategy**:

1. Replace old `NSVisualEffectView` with SwiftUI material modifiers
2. Use `.ultraThinMaterial`, `.thinMaterial`, or `.regularMaterial` for appropriate blur levels
3. Combine with vibrancy (foreground content pulls color from background)
4. Test in both light and dark appearances

### Navigation Migration

```swift
// ❌ OLD (Deprecated)
NavigationView {
    List { ... }
    DetailView()
}

// ✅ NEW (Recommended for macOS)
NavigationSplitView {
    Sidebar()
} detail: {
    DetailView()
}
```

`NavigationSplitView` automatically adapts from multi-column (macOS/iPad) to single-column (iPhone) layouts. For full pattern details, see [SwiftUI Architect skill](swift-swiftui-architect).

### New APIs & Deprecations

**Added in Tahoe 26:**

- Liquid Glass materials system (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`)
- `@Observable` macro (modern alternative to `ObservableObject`)
- `@FocusState` enhancements for keyboard management

**Deprecated:**

- `NavigationView` (use `NavigationSplitView`)
- `NSAppearance.current.name` (use `@Environment(\.colorScheme)`)

## Migration Strategies

### Strategy 1: Incremental View-by-View Migration

**Best for**: Large apps with many views

1. Create SwiftUI wrapper views for new features
2. Migrate one screen/section at a time
3. Use NSViewControllerRepresentable for AppKit bridging
4. Gradually replace AppKit components

**Pros**: Low risk, can ship incrementally
**Cons**: Longer timeline, potential inconsistency

### Strategy 2: Greenfield SwiftUI + Legacy AppKit Bridge

**Best for**: Long-term plans

1. Build new features in SwiftUI
2. Bridge existing AppKit via NSViewControllerRepresentable
3. Keep AppKit code working as legacy
4. Migrate AppKit piece by piece

**Pros**: Modern foundation, maintains stability
**Cons**: Dual codebase initially

### Strategy 3: Rewrite Core + Preserve UI Bridge

**Best for**: Well-structured AppKit code

1. Extract business logic from AppKit views
2. Rewrite business logic in modern Swift (no UI)
3. Build new SwiftUI views around logic
4. Keep AppKit UI as fallback during transition

**Pros**: Testable, separates concerns
**Cons**: Requires clean architecture

## Common Migration Challenges

### Challenge 1: Complex AppKit Layouts

```swift
// Complex NSStackView arrangement
// Strategy: Use SwiftUI's Grid or LazyVGrid for complex layouts
Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
    GridRow {
        Text("Label 1")
        TextField("Input", text: $input)
    }
    GridRow {
        Text("Label 2")
        TextField("Input", text: $input2)
    }
}
```

### Challenge 2: NSViewController Lifecycle

```swift
// OLD: viewDidLoad, viewWillAppear, etc.
// NEW: Use .onAppear, .task, and lifecycle modifiers
.onAppear {
    loadData()
}
.task {
    await monitorChanges()
}
```

### Challenge 3: NSMenuBuilder Integration

```swift
// NEW: Use .commands() for app-level menus
.commands {
    CommandMenu("File") {
        Button("New") {
            newDocument()
        }
        .keyboardShortcut("n", modifiers: .command)
    }
}
```

### Challenge 4: Responder Chain / First Responder

```swift
// NEW: Use @FocusState for keyboard focus
@FocusState private var focusedField: FocusableField?

TextField("Name", text: $name)
    .focused($focusedField, equals: .nameField)
```

## Migration Checklist (Apple HIG + Tahoe)

### Architecture & Patterns

- [ ] Code compiles for target macOS version
- [ ] NavigationSplitView used (not deprecated NavigationView)
- [ ] @StateObject only in owner views, @ObservedObject in children
- [ ] @MainActor on all ViewModels with @Published properties

### Liquid Glass & Design (macOS 26 Tahoe)

- [ ] Liquid Glass materials applied (.ultraThinMaterial, .thinMaterial, .regularMaterial)
- [ ] 8pt grid spacing followed (8, 16, 24, 32 etc.) per HIG
- [ ] Tested in both light and dark appearances
- [ ] Vibrancy working correctly on material content

### Functionality & Performance

- [ ] All features work in both old and new code
- [ ] No performance regressions (use Instruments to verify)
- [ ] List used instead of LazyVStack for large datasets
- [ ] Memory usage comparable or better

### User Experience

- [ ] Accessibility features preserved (VoiceOver labels/hints)
- [ ] Keyboard navigation and tab order working
- [ ] Window/state restoration working
- [ ] Command menu integration matches macOS conventions
- [ ] Keyboard shortcuts accessible and documented

### Data & System

- [ ] Persistence layer unchanged
- [ ] Testing coverage maintained
- [ ] Error handling at appropriate abstraction levels

## Questions Before Migration

- What is the scope? (Single view vs. whole app?)
- What's the timeline?
- Are you targeting a new macOS minimum version?
- Which features are most important to migrate first?
- Do you have test coverage for existing code?
- Any complex custom drawing or graphics code?

## Resources and References

- Apple SwiftUI documentation: Focus on latest version features
- macOS 26 Tahoe release notes: Check for new APIs and deprecations
- Migration guides: Look for any official Apple guidance
- Community examples: SwiftUI migration patterns from real projects

## Next Steps After Migration

1. Profile performance with Instruments
2. Run accessibility audit
3. Test on actual hardware (not just simulator)
4. Collect user feedback on new UI
5. Plan deprecation of old AppKit code
6. Archive migration code for reference
