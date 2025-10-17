# Common SwiftUI Debugging Issues

Detailed troubleshooting for Issues #4, #5, and #6.

## Issue 4: Navigation Not Working (macOS: Use NavigationSplitView)

**Symptoms**: NavigationLink doesn't navigate, back button doesn't appear, state lost

**Root causes**:

- Deprecated `NavigationView` or wrong pattern for macOS
- Navigation state not properly stored
- Missing `.navigationTitle()`

**macOS Solution** (Apple Recommended):

```swift
@State private var selectedItem: Item?

NavigationSplitView {
    List(items, selection: $selectedItem) { item in
        NavigationLink(value: item) {
            Text(item.name)
        }
    }
    .navigationTitle("Items")
} detail: {
    if let item = selectedItem {
        DetailView(item: item)
            .navigationTitle(item.name)
    } else {
        Text("Select an item")
            .foregroundColor(.secondary)
    }
}
```

**Debugging**: Add `.onChange(of: selectedItem)` to track selection changes:

```swift
.onChange(of: selectedItem) { old, new in
    print("Selection: \(old?.id ?? "nil") → \(new?.id ?? "nil")")
}
```

---

## Issue 5: Crashes with Background Thread UI Updates

**Symptoms**: "Publishing changes from background thread" warning, then crashes

**Root causes**:

- Updating `@Published` properties from background thread
- Missing `@MainActor` on ViewModel

**Solution**:

```swift
@MainActor  // Ensures all updates on main thread
class ViewModel: ObservableObject {
    @Published var data: [Item] = []

    func loadData() async {
        let items = try await fetchRemote()
        self.data = items  // Safe now
    }
}
```

**Debugging**: Check crash stack trace and console for "MainThread violation" warnings.

---

## Issue 6: List Performance Degradation

**Symptoms**: Scrolling is laggy, large lists are slow, memory grows

**Root causes**:

- Using `LazyVStack` instead of `List` (doesn't recycle views!)
- Complex views in cells
- Missing `.id()` on items

**Debugging**:

```swift
// Profile with Instruments > Core Animation
// Check for: dropped frames, memory growth during scrolling

// Quick optimization:
List(largeArray, id: \.id) { item in
    LightweightCell(item: item)  // Keep cells simple
}

// Extract expensive computations to ViewModel
// Verify improvements with Instruments
```

For the List vs LazyVStack performance rule, see [Swift Code Reviewer skill](swift-code-reviewer).

---

## Debugging Tools & Techniques

### Print Debugging

```swift
var body: some View {
    Text("Rendering")
        .onAppear { print("View appeared") }
        .onDisappear { print("View disappeared") }
}
```

### Debug View Hierarchy

```swift
#if DEBUG
struct DebugView: View {
    var body: some View {
        // Your view
            ._debugPrint()  // Built-in debugging
    }
}
#endif
```

### Check Binding Values

```swift
let binding = Binding(
    get: {
        print("Getting: \(value)")
        return value
    },
    set: {
        print("Setting to: \($0)")
        value = $0
    }
)
```

### Xcode Console Commands

```swift
// Check if view is visible
p view.frame
p view.isHidden

// Disable animations for testing
po NSView.setAnimationsEnabled(false)
```

---

## macOS-Specific Debugging

### Window Focus

```swift
@Environment(\.controlActiveState) var activeState

Text(activeState == .key ? "Active" : "Inactive")
```

### Keyboard Shortcuts

```swift
Button("Save") { save() }
    .keyboardShortcut("s", modifiers: .command)
    .onAppear { print("Keyboard shortcut registered") }
```

### Liquid Glass Material Issues (macOS 26 Tahoe)

**Problem**: Material not showing through

```swift
// ❌ WRONG: Material may be invisible
ZStack {
    Image(...)
    Text("Content").background(.ultraThinMaterial)
}

// ✅ CORRECT: Material on top of content
ZStack {
    Image(...)
        .resizable()
        .ignoresSafeArea()

    VStack {
        Text("Content")
    }
    .background(.ultraThinMaterial)
}
```

**Debugging Tips**:

- Material color should adapt to background
- Test with various background colors
- Check both light and dark appearances
- Verify vibrancy working (text color pulling forward)
- Use `.debugLayout()` to see bounds
