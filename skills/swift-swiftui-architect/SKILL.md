---
name: SwiftUI Architect
description: Generate macOS SwiftUI views, components, and app architecture with modern patterns. Use when building SwiftUI UIs for macOS, creating reusable components, scaffolding new apps, designing view hierarchies, or exploring AppKit-SwiftUI integration.
---

# SwiftUI Architect

Generate production-ready SwiftUI code for macOS with best practices, educational guidance, and macOS 26 Tahoe-specific patterns.

## Instructions

When generating SwiftUI code:

1. **Understand the requirement**: Ask what you're building, the purpose, and what data it works with
2. **Apply macOS patterns**: Use macOS-appropriate controls (Segmented pickers for tabs, menus for top-level navigation, proper spacing)
3. **Follow Swift best practices**:
   - Use `@State`, `@Binding`, `@StateObject`, `@ObservedObject` appropriately
   - Leverage `@Environment` for system-level values and themes
   - Use property wrappers correctly for data flow
   - Apply `@available` for macOS 26 Tahoe features when relevant
4. **Structure for reusability**: Break complex views into smaller, composable components
5. **Include accessibility**: Add `.accessibilityLabel()`, `.accessibilityHint()` where appropriate
6. **Explain design decisions**: Include comments explaining why certain patterns were chosen

## Common Patterns

### View Container with State Management (Recommended Pattern)

```swift
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationSplitView {
            // Sidebar - adapts to available space
            List(selection: $viewModel.selectedItem) {
                ForEach(viewModel.items) { item in
                    NavigationLink(value: item) {
                        Text(item.name)
                    }
                }
            }
            .navigationTitle("Items")
        } detail: {
            // Detail view
            if let selectedItem = viewModel.selectedItem {
                DetailView(item: selectedItem)
            } else {
                Text("Select an item")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

**Key pattern**: `@StateObject` in owner, `@ObservedObject` in children. `NavigationSplitView` adapts to screen size. ([Reference](https://developer.apple.com/documentation/swiftui/building-a-great-mac-app-with-swiftui))

### Reusable Component Pattern

```swift
struct CustomButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text(title)
            }
        }
        .disabled(isLoading)
    }
}
```

### ViewModel Pattern (MVVM)

```swift
@MainActor
class ContentViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var selectedItem: Item?
    @Published var isLoading = false

    private let dataService: DataService

    init(dataService: DataService = .shared) {
        self.dataService = dataService
    }

    func loadItems() async {
        isLoading = true
        do {
            items = try await dataService.fetchItems()
        } catch {
            // Handle error appropriately
        }
        isLoading = false
    }
}
```

**@MainActor**: Compile-time guarantee that UI updates happen on main thread. ([Reference](https://developer.apple.com/documentation/swift/mainactor))

## macOS 26 Tahoe Design System

### Liquid Glass Material & Vibrancy

```swift
// macOS 26 Tahoe introduces Liquid Glass - translucent, content-aware material
ZStack {
    // Background content shows through the material
    Image(systemName: "mountain.2")
        .font(.system(size: 48))

    // Foreground with Liquid Glass effect
    VStack {
        Text("Using Liquid Glass")
            .font(.headline)
        Text("Translucent & Adaptive")
            .font(.caption)
    }
    .padding()
    .background(.ultraThinMaterial)  // Adapts to background content
}
```

**Key Properties**:

- **Translucency**: Real glass-like behavior, content shows through
- **Content-Aware**: Color informed by surrounding content
- **Adaptive**: Intelligently responds to light/dark environments
- **Vibrancy**: Foreground content (text, symbols) pulls color forward, creating depth
- Material options: `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`

For debugging material issues, see [Swift Debugger skill](swift-debugger).

### Spacing & Layout Standards (Apple HIG)

- **8pt grid system**: 8, 16, 24, 32, 40, 48, etc.
- Padding: 16pt margins for main content
- Intermediate spacing: 12pt between elements
- Compact spacing: 8pt for related elements
- [Reference: Apple HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)

### Window & Control Management

- **Window lifecycle**: `@Environment(\.controlActiveState)` for focus detection
- **Menu integration**: `.commands()` modifier for app-level menus
- **Keyboard navigation**: `.focusable()` and `@FocusState` for focus management
- **Dark mode**: Automatic via `@Environment(\.colorScheme)`

## AppKit Interop

When you need AppKit features unavailable in SwiftUI:

```swift
struct AppKitBridge: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        // Create AppKit view controller
        return CustomViewController()
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // Update when SwiftUI state changes
    }
}
```

## Questions to Ask Before Generating

- What is the primary purpose of this view?
- What data does it display or manage?
- Does this need to be responsive/adaptive?
- Are there specific macOS patterns you want to follow?
- Does this integrate with existing code?
- What's the minimum macOS version? (affects @Observable availability)

## Exports and Outputs

Provide complete, copyable Swift code with:

- Proper `import` statements
- All necessary property wrappers (correctly used for ownership/observation)
- Liquid Glass materials where appropriate
- 8pt grid spacing standards
- Error handling at appropriate abstraction levels
- Accessibility annotations (.accessibilityLabel, .accessibilityHint)
- Comments explaining non-obvious decisions
- Links to relevant Apple documentation
