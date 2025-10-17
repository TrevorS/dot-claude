# SwiftUI Engineer Reference

Complete reference for SwiftUI patterns, anti-patterns, debugging techniques, and migration strategies for macOS development.

## Table of Contents

1. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
2. [Architecture Patterns](#architecture-patterns)
3. [Debugging Common Issues](#debugging-common-issues)
4. [macOS 26 Tahoe Patterns](#macos-26-tahoe-patterns)
5. [Migration from AppKit](#migration-from-appkit)
6. [Performance and Optimization](#performance-and-optimization)
7. [Accessibility](#accessibility)
8. [Keyboard and Focus Management](#keyboard-and-focus-management)

---

## Anti-Patterns to Avoid

### 1. Improper State Management

❌ **WRONG**: Using `@State` in non-view classes

```swift
class DataManager {
    @State var items: [Item] = [] // Wrong!
}
```

✅ **CORRECT**: Use `@Published` in ObservableObject

```swift
@MainActor
class DataManager: ObservableObject {
    @Published var items: [Item] = []
}
```

**Why**: `@State` is for View structs only. Reference types use `@Published`.

### 2. View-Based Business Logic

❌ **WRONG**: Network calls directly in view body

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            let data = try? JSONDecoder().decode(...)
            Text("Data: \(data)")
        }
    }
}
```

✅ **CORRECT**: Logic in ViewModel

```swift
@MainActor
class ContentViewModel: ObservableObject {
    @Published var data: [Item] = []

    func loadData() async { ... }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        Text("Data: \(viewModel.data.count)")
            .task {
                await viewModel.loadData()
            }
    }
}
```

**Why**: Separates concerns - makes code testable and maintainable.

### 3. Missing @MainActor for UI Updates

❌ **WRONG**: Publishing from background thread

```swift
class ViewModel: ObservableObject {
    @Published var items: [Item] = []

    func loadItems() async {
        let items = try await fetchRemote()
        self.items = items // Warning: Publishing changes from background thread!
    }
}
```

✅ **CORRECT**: Use @MainActor

```swift
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

❌ **WRONG**: Task in .onAppear without lifecycle management

```swift
.onAppear {
    Task {
        let data = try await fetchData()
        self.data = data // Detached task, potential race conditions
    }
}
```

✅ **CORRECT**: Use .task() modifier

```swift
.task {
    await loadData()
}
```

**Why**: `.task()` auto-cancels on disappear, preventing orphaned tasks and leaks.

### 5. Reference Cycles

❌ **WRONG**: Strong capture of self

```swift
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    self.updateValue() // Reference cycle!
}
```

✅ **CORRECT**: Use weak self

```swift
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.updateValue()
}
```

**Why**: Prevents memory leaks from reference cycles.

### 6. Multiple @StateObject Instances (CRITICAL)

❌ **WRONG**: Creates MULTIPLE independent instances!

```swift
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
```

✅ **CORRECT**: Owner uses @StateObject, children use @ObservedObject

```swift
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

**Why**: Multiple @StateObjects create independent instances. Only the owner creates; children observe the same instance.

### 7. List vs LazyVStack Performance

❌ **PROBLEMATIC**: LazyVStack doesn't recycle views

```swift
ScrollView {
    LazyVStack {
        ForEach(largeArray) { item in
            ItemCell(item: item)
        }
    }
}
```

✅ **CORRECT**: List recycles views like UITableView

```swift
List {
    ForEach(largeArray) { item in
        ItemCell(item: item)
    }
}
```

**Why**: `List` recycles views (memory efficient). `LazyVStack` only defers creation—all views stay in memory.

---

## Architecture Patterns

### View Container with State Management (Recommended)

```swift
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedItem) {
                ForEach(viewModel.items) { item in
                    NavigationLink(value: item) {
                        Text(item.name)
                    }
                }
            }
            .navigationTitle("Items")
        } detail: {
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

**Key pattern**:

- `@StateObject` in owner
- `@ObservedObject` in children
- `NavigationSplitView` adapts to screen size

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

**@MainActor**: Compile-time guarantee that UI updates happen on main thread.

---

## Debugging Common Issues

### Issue: View Updates Not Reflecting State Changes

**Symptoms**: UI doesn't update when @State changes, values appear stale

**Root causes**:

- Missing `@State` or wrong property wrapper
- Modifying state inside nested closure without proper reference
- State belongs to parent view, not child
- Using value types incorrectly

**Solution**:

```swift
@State private var count = 0

var body: some View {
    VStack {
        Text("Count: \(count)")
        Button("Increment") {
            count += 1  // Direct assignment
        }
    }
}
```

### Issue: View Rendering in Infinite Loop

**Symptoms**: High CPU usage, app becomes sluggish, Xcode shows "Executing 1000 closure bodies"

**Root causes**:

- Computed property calling `@State` modification
- Binding creating circular dependency
- View hierarchy triggering parent re-renders repeatedly
- `.onChange()` modifying the value it's observing

**Solution**:

```swift
// Use .task() for side effects, not computed properties
.task {
    let result = await expensiveComputation()
    self.computedValue = result
}

// Or memoize the result
@State private var memoizedValue: String?

var body: some View {
    Text(memoizedValue ?? "Loading")
        .onAppear {
            if memoizedValue == nil {
                memoizedValue = expensiveComputation()
            }
        }
}
```

### Issue: Memory Leak with Reference Cycles

**Symptoms**: App memory grows over time, never decreases; objects not deallocating

**Root causes**:

- Capturing `self` strongly in closures
- Timer or notification subscription not being cleaned up
- Observable objects retaining view dependencies
- Circular references in data models

**Solution**:

```swift
// Use weak capture
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.viewModel.update()
}

// Or better: Use .task() for lifecycle management
.task {
    for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
        await viewModel.update()
    }
}
```

### Issue: Navigation Not Working

**Symptoms**: NavigationLink doesn't navigate, back button doesn't appear, state lost

**Solution** (macOS - use NavigationSplitView):

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

### Issue: Crashes with Background Thread UI Updates

**Symptoms**: "Publishing changes from background thread" warning, then crashes

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

### Issue: List Performance Degradation

**Symptoms**: Scrolling is laggy, large lists are slow, memory grows

**Root causes**:

- Using `LazyVStack` instead of `List` (doesn't recycle views!)
- Complex views in cells
- Missing `.id()` on items

**Solution**:

```swift
List(largeArray, id: \.id) { item in
    LightweightCell(item: item)  // Keep cells simple
}

// Extract expensive computations to ViewModel
// Verify improvements with Instruments > Core Animation
```

---

## macOS 26 Tahoe Patterns

### Liquid Glass Material & Vibrancy

macOS 26 introduces Liquid Glass - translucent, content-aware material that adapts intelligently.

```swift
ZStack {
    // Background content shows through the material
    Image(systemName: "mountain.2")
        .font(.system(size: 48))
        .resizable()
        .ignoresSafeArea()

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
- **Material options**: `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`

**When to use**:

- `.ultraThinMaterial`: Subtle, layered over colorful backgrounds
- `.thinMaterial`: Default, good for most overlays
- `.regularMaterial`: Heavy blur, when you need more occlusion

**Debugging**:

- Material color should adapt to background
- Test with various background colors
- Check both light and dark appearances
- Verify vibrancy working (text color pulling forward)

### Spacing & Layout Standards (Apple HIG)

- **8pt grid system**: 8, 16, 24, 32, 40, 48, etc.
- **Padding**: 16pt margins for main content
- **Intermediate spacing**: 12pt between elements
- **Compact spacing**: 8pt for related elements

### Window & Control Management

- **Window lifecycle**: `@Environment(\.controlActiveState)` for focus detection
- **Menu integration**: `.commands()` modifier for app-level menus
- **Keyboard navigation**: `.focusable()` and `@FocusState` for focus management
- **Dark mode**: Automatic via `@Environment(\.colorScheme)`

### Navigation (NOT deprecated NavigationView)

Use `NavigationSplitView` which adapts to macOS multi-column layout:

```swift
NavigationSplitView {
    Sidebar()
} detail: {
    DetailView()
}
```

---

## Migration from AppKit

### Window Management

❌ **OLD (AppKit)**:

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(...)
        window.makeKeyAndOrderFront(nil)
    }
}
```

✅ **NEW (SwiftUI)**:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)  // macOS 26 styles
        .windowResizability(.contentMinSize(CGSize(width: 400, height: 300)))
    }
}
```

### Deprecated Navigation

❌ **OLD (Deprecated)**:

```swift
NavigationView {
    List { ... }
    DetailView()
}
```

✅ **NEW (Recommended)**:

```swift
NavigationSplitView {
    Sidebar()
} detail: {
    DetailView()
}
```

### Keyboard Shortcuts

❌ **OLD (AppKit - NSMenuBuilder)**:

```swift
// Complex menu builder code
```

✅ **NEW (SwiftUI)**:

```swift
.commands {
    CommandMenu("File") {
        Button("New") {
            newDocument()
        }
        .keyboardShortcut("n", modifiers: .command)
    }
}
```

### Focus Management

❌ **OLD (Responder chain - complex)**

✅ **NEW (Simple with @FocusState)**:

```swift
@FocusState private var focusedField: FocusableField?

TextField("Name", text: $name)
    .focused($focusedField, equals: .nameField)
```

### Migration Strategies

#### Strategy 1: Incremental View-by-View

- Best for: Large apps with many views
- Create SwiftUI wrapper views for new features
- Migrate one screen at a time
- Use NSViewControllerRepresentable for AppKit bridging

#### Strategy 2: Greenfield SwiftUI + Legacy Bridge

- Best for: Long-term plans
- Build new features in SwiftUI
- Bridge existing AppKit via NSViewControllerRepresentable
- Gradually replace AppKit piece by piece

#### Strategy 3: Extract Logic + New UI

- Best for: Well-structured AppKit code
- Extract business logic from AppKit views
- Rewrite logic in modern Swift (no UI)
- Build new SwiftUI views around logic

---

## Performance and Optimization

### List vs LazyVStack Rule

**Use `List`** for large datasets - recycles views like UITableView

**Use `LazyVStack`** only for deferred creation, NOT for scrolling lists

```swift
// ✅ For collections that scroll
List(items) { item in
    ItemCell(item: item)
}

// ❌ Don't use LazyVStack for scrollable lists
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemCell(item: item)  // Won't recycle!
        }
    }
}
```

### Optimization Techniques

1. **Keep cells simple**: Extract expensive computations to ViewModel
2. **Add `.id()` to lists**: Helps with view identity
3. **Use Instruments**: Profile with Core Animation to find dropped frames
4. **Memoize calculations**: Cache expensive computations
5. **Profile memory**: Use Instruments > Memory to check for leaks

---

## Accessibility

### Basic Labels and Hints

```swift
Text("User avatar")
    .accessibilityLabel("Avatar for John Doe")
    .accessibilityHint("Tap to view profile")

Button("Save") { save() }
    .accessibilityLabel("Save document")
    .accessibilityHint("Saves the current document")
```

### Interactive Elements

```swift
TextField("Email", text: $email)
    .accessibilityLabel("Email address field")

Slider(value: $volume, in: 0...100)
    .accessibilityLabel("Volume")
    .accessibilityValue("\(Int(volume))%")
```

### Container Labels

```swift
VStack {
    // Content
}
.accessibilityElement(children: .contain)
.accessibilityLabel("Settings panel")
```

---

## Keyboard and Focus Management

### @FocusState for Focus Management

```swift
@FocusState private var focusedField: FocusableField?

enum FocusableField {
    case email
    case password
}

var body: some View {
    VStack {
        TextField("Email", text: $email)
            .focused($focusedField, equals: .email)

        SecureField("Password", text: $password)
            .focused($focusedField, equals: .password)

        Button("Sign In") {
            if email.isEmpty {
                focusedField = .email
            }
        }
    }
}
```

### Keyboard Shortcuts

```swift
Button("Save") { save() }
    .keyboardShortcut("s", modifiers: .command)

Button("Find") { showSearchBar() }
    .keyboardShortcut("f", modifiers: .command)
```

### Focusable Elements

```swift
VStack {
    Button("Action") { }
        .focusable()
}
```

---

## Checklist for Code Review

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
- [ ] **Liquid Glass**: Materials used appropriately for macOS 26?
