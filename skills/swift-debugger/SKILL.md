---
name: Swift Debugger
description: Diagnose and fix SwiftUI bugs, state management issues, performance problems, and macOS app crashes. Use when debugging view rendering issues, state loops, memory leaks, crashes, performance problems, or mysterious behavior in SwiftUI apps.
---

# Swift Debugger

Diagnose and solve SwiftUI and macOS app issues with systematic debugging, root cause analysis, and educational explanations.

## Instructions

When debugging Swift/SwiftUI issues:

1. **Gather information**: Ask about the specific problem, when it occurs, error messages, and reproduction steps
2. **Form hypothesis**: Based on symptoms, identify likely causes
3. **Guide diagnosis**: Suggest systematic debugging steps
4. **Identify root cause**: Explain why the problem is happening
5. **Provide solution**: Offer targeted fix with code examples
6. **Prevent recurrence**: Explain how to avoid the issue in future

## Common Issues and Solutions

### Issue 1: View Updates Not Reflecting State Changes

**Symptoms**: UI doesn't update when @State changes, values appear stale

**Root causes**:

- Missing `@State` or wrong property wrapper
- Modifying state inside nested closure without proper reference
- State belongs to parent view, not child
- Using value types incorrectly

**Diagnosis**:

```swift
// Add debug output to understand state flow
@State private var count = 0

var body: some View {
    VStack {
        Text("Count: \(count)")
            .onChange(of: count) { oldVal, newVal in
                print("Count changed from \(oldVal) to \(newVal)")
            }
        Button("Increment") {
            print("Before: \(count)")
            count += 1
            print("After: \(count)")
        }
    }
}
```

**Solution**:

```swift
// Correct pattern
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

### Issue 2: View Rendering in Infinite Loop

**Symptoms**: High CPU usage, app becomes sluggish, Xcode shows "Executing 1000 closure bodies"

**Root causes**:

- Computed property calling `@State` modification
- Binding creating circular dependency
- View hierarchy triggering parent re-renders repeatedly
- `.onChange()` modifying the value it's observing

**Diagnosis**:

```swift
var body: some View {
    VStack {
        // ❌ This might be the culprit if `expensiveComputation` modifies state
        Text(expensiveComputation())
        // Add print statement to track re-renders
            .onAppear { print("Rendered at \(Date())") }
    }
}
```

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

### Issue 3: Memory Leak with Reference Cycles

**Symptoms**: App memory grows over time, never decreases; objects not deallocating

**Root causes**:

- Capturing `self` strongly in closures
- Timer or notification subscription not being cleaned up
- Observable objects retaining view dependencies
- Circular references in data models

**Diagnosis**:

```swift
// Use Instruments: Xcode > Product > Profile > Memory
// Check for:
// - Growing heap
// - Unreleased object allocations
// - Notification observers not removed

@StateObject private var viewModel = ViewModel()

var body: some View {
    VStack { }
    .onAppear {
        // ❌ Potential issue: strong capture of self
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.viewModel.update()  // Could be retained
        }
    }
}
```

**Solution**:

```swift
.onAppear {
    // ✅ Weak capture avoids reference cycle
    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
        self?.viewModel.update()
    }
}

// Or better: Use .task() for lifecycle management
.task {
    for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
        await viewModel.update()
    }
}
```

### Issues 4-6: See Reference File

For detailed troubleshooting of navigation, threading, and performance issues, see [COMMON_ISSUES.md](COMMON_ISSUES.md).

**Quick reference**:

- **Issue 4**: Navigation - Use NavigationSplitView for macOS
- **Issue 5**: Background thread crashes - Add @MainActor to ViewModels
- **Issue 6**: List scrolling laggy - Use List instead of LazyVStack

## Systematic Debugging Approach

1. **Reproduce consistently**: Can you repeat the issue on demand?
2. **Isolate the component**: Does it happen in a minimal example?
3. **Check recent changes**: Did you add/modify related code?
4. **Review logs**: Console output, crash logs, warnings
5. **Use Instruments**: Profile memory, CPU, threads
6. **Create minimal reproduction**: Smaller = easier to debug
7. **Test on device**: Simulator behavior may differ
8. **Check Apple documentation**: Maybe it's a known behavior

## When to Ask for Help

You're ready to escalate when:

- [ ] You've isolated a minimal reproduction case
- [ ] You've checked Apple documentation (especially WWDC sessions)
- [ ] You've tried 2-3 different solutions without success
- [ ] You have error messages, crash logs, or Instruments data
- [ ] You can clearly describe expected vs. actual behavior
- [ ] You've tested on actual macOS device (not just simulator)

**Debugging Package Information** to provide:

- macOS version and minimum target
- SwiftUI version / Xcode version
- Complete error messages or console output
- Minimal code reproduction
- What you've already tried
- Screenshots or video of the issue

**Documentation References**:

- [Apple SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Building a Great Mac App](https://developer.apple.com/documentation/swiftui/building-a-great-mac-app-with-swiftui)
- [WWDC Sessions](https://developer.apple.com/wwdc/)
- [macOS HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos)
