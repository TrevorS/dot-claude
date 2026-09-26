# SwiftUI Reference (macOS 26)

Worked examples for the patterns in SKILL.md.

## Observation: ownership and bindings

One owner holds the model in `@State`; everything below it receives the same instance.

```swift
@MainActor @Observable
final class LibraryModel {
    var items: [Item] = []
    var selection: Item.ID?
    var filter = ""
    var isLoading = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = (try? await ItemService.shared.fetchItems()) ?? []
    }
}

struct ContentView: View {
    @State private var model = LibraryModel()      // owner

    var body: some View {
        NavigationSplitView {
            List(model.items, selection: $model.selection) { item in
                Text(item.name)
            }
            .navigationTitle("Items")
        } detail: {
            ItemDetail(model: model)               // same instance, plain property
        }
        .task { await model.load() }
    }
}

struct ItemDetail: View {
    let model: LibraryModel                        // read-only: no wrapper

    var body: some View {
        if let id = model.selection, let item = model.items.first(where: { $0.id == id }) {
            Text(item.name)
        } else {
            Text("Select an item").foregroundStyle(.secondary)
        }
    }
}

struct FilterField: View {
    @Bindable var model: LibraryModel              // needs bindings into the model

    var body: some View {
        TextField("Filter", text: $model.filter)
    }
}
```

For a model many views deep, inject it once with `.environment(model)` and read it with `@Environment(LibraryModel.self) private var model`.

A child that declares its own `@State private var model = LibraryModel()` gets a separate instance, and its changes never reach the parent.

### Pre-Observation API

Use only for code that must run on macOS 13 or earlier; when reviewing or migrating, map it across:

| Pre-Observation | Observation |
| --- | --- |
| `class M: ObservableObject` | `@Observable final class M` |
| `@Published var x` | `var x` |
| `@StateObject var m = M()` | `@State var m = M()` |
| `@ObservedObject var m: M` | `let m: M`, or `@Bindable var m: M` for bindings |
| `@EnvironmentObject var m: M` | `@Environment(M.self) var m` |

## Async work

`.task` cancels when the view disappears; `.task(id:)` also cancels and restarts when the value changes:

```swift
.task(id: model.selection) {
    await model.loadDetail(for: model.selection)
}
```

## Liquid Glass

Glass belongs on the control and navigation layer that floats above content, not on the content itself. Toolbars, sidebars, and sheets built with the macOS 26 SDK get it automatically; a custom opaque background on them hides it. Don't layer glass on glass.

```swift
// Buttons: use the glass button styles
Button("Share", systemImage: "square.and.arrow.up") { share() }
    .buttonStyle(.glass)                 // .glassProminent for the primary action

// Custom views: glassEffect with a style and a shape
Label("Synced", systemImage: "checkmark.icloud")
    .padding()
    .glassEffect(.regular.tint(.green).interactive(), in: .rect(cornerRadius: 12))

// Several glass views together: one container so they merge and morph
@Namespace private var glass

GlassEffectContainer(spacing: 16) {
    HStack(spacing: 16) {
        Image(systemName: "pencil")
            .frame(width: 44, height: 44)
            .glassEffect()
            .glassEffectID("pencil", in: glass)
        if showEraser {
            Image(systemName: "eraser")
                .frame(width: 44, height: 44)
                .glassEffect()
                .glassEffectID("eraser", in: glass)
        }
    }
}
```

## AppKit migration

| AppKit | SwiftUI |
| --- | --- |
| `NSApplicationDelegate` + `NSWindow` | `App` with `WindowGroup`, `Window`, `Settings` scenes; `@NSApplicationDelegateAdaptor` for delegate callbacks still needed |
| `NSMenu` / main menu | `.commands { CommandMenu(...) }` with `.keyboardShortcut` |
| First responder chain | `@FocusState` + `.focused(_:equals:)`; `.focusedSceneValue` for menu commands |
| `NavigationView` / split view controllers | `NavigationSplitView` |
| Keep an AppKit view | `NSViewRepresentable` / `NSViewControllerRepresentable` |
| Put SwiftUI inside AppKit | `NSHostingController` / `NSHostingView` |

Migrate one screen at a time: host new SwiftUI screens in the AppKit app with `NSHostingController`, and wrap the AppKit views that aren't worth rewriting yet.
