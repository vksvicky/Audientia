# Developer Guide: Extending Tab-Specific Views

## Overview

This guide explains how to add new tabs or extend existing tab-specific views in Audientia's UI layout system. The architecture uses SwiftUI with MVVM pattern, following TDD/BDD practices.

**Last Updated**: December 2025

---

## Architecture Overview

### Component Structure

```
MainWindowLayoutView
├── CollapsibleToolbar (Navigation tabs)
├── ContextualSidebar (Tab-specific sidebar content)
├── MainWindowTabContentView (Tab-specific main content)
└── CollapsiblePlayerBar (Always-visible player)
```

### Key Components

1. **`TabItem`** - Enum defining available tabs
2. **`MainWindowTabContentView`** - Switch statement routing to tab-specific views
3. **`ContextualSidebar`** - Sidebar that changes content per tab
4. **ViewModels** - MVVM pattern for business logic and state management

---

## Adding a New Tab

### Step 1: Add Tab to `TabItem` Enum

Edit `Sources/UI/Layout/Navigation/TabItem.swift`:

```swift
public enum TabItem: String, CaseIterable, Identifiable, Hashable {
    case home
    case library
    case playlists
    case devices
    case visualiser
    case yourNewTab  // Add your new tab here
    
    // Add display name
    public var displayName: String {
        switch self {
        // ... existing cases
        case .yourNewTab: return "Your New Tab"
        }
    }
    
    // Add icon
    public var iconName: String {
        switch self {
        // ... existing cases
        case .yourNewTab: return "your.icon.name"
        }
    }
    
    // Add keyboard shortcut (next available number)
    public var keyboardShortcutNumber: Int {
        switch self {
        // ... existing cases
        case .yourNewTab: return 6  // Next available number
        }
    }
    
    // Add search placeholder
    public var searchPlaceholder: String {
        switch self {
        // ... existing cases
        case .yourNewTab: return "Search your tab..."
        }
    }
}
```

### Step 2: Create ViewModel (if needed)

Create a new ViewModel following the MVVM pattern:

```swift
// Sources/UI/Layout/YourTab/YourTabViewModel.swift
import Foundation
import SwiftUI

@MainActor
public class YourTabViewModel: ObservableObject {
    @Published public private(set) var items: [YourItem] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private let yourService: YourServiceProtocol
    
    public init(yourService: YourServiceProtocol) {
        self.yourService = yourService
    }
    
    public func loadItems() async {
        isLoading = true
        error = nil
        
        do {
            items = try await yourService.getItems()
        } catch {
            self.error = error
            items = []
        }
        
        isLoading = false
    }
}
```

**Best Practices:**
- Use `@Published` for state that triggers UI updates
- Use `@MainActor` for thread safety
- Follow Right-BICEP testing principles
- Use dependency injection for testability

### Step 3: Create Tab-Specific View

Create your view component:

```swift
// Sources/UI/Layout/YourTab/YourTabView.swift
import SwiftUI

struct YourTabView: View {
    @ObservedObject var viewModel: YourTabViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
            } else {
                // Your content here
                List(viewModel.items) { item in
                    Text(item.name)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.loadItems()
        }
    }
}
```

### Step 4: Add to `MainWindowTabContentView`

Edit `Sources/UI/Layout/MainWindowTabContentView.swift`:

```swift
struct MainWindowTabContentView: View {
    // ... existing properties
    let yourTabViewModel: YourTabViewModel  // Add your ViewModel
    
    var body: some View {
        Group {
            switch selectedTab {
            // ... existing cases
            case .yourNewTab:
                YourTabView(viewModel: yourTabViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
```

### Step 5: Initialize ViewModel in `MainWindowLayoutView`

Edit `Sources/UI/Layout/MainWindowLayoutView.swift`:

```swift
@MainActor
public struct MainWindowLayoutView: View {
    // ... existing ViewModels
    @StateObject private var yourTabViewModel: YourTabViewModel
    
    public init(audioEngine: AudioEngineProtocol) {
        // ... existing initialization
        _yourTabViewModel = StateObject(
            wrappedValue: YourTabViewModel(yourService: YourService())
        )
    }
    
    // Update MainWindowTabContentView call
    private var mainContentArea: some View {
        // ...
        MainWindowTabContentView(
            selectedTab: selectedTab,
            // ... existing parameters
            yourTabViewModel: yourTabViewModel
        )
    }
}
```

### Step 6: Add Sidebar Content

Edit `Sources/UI/Layout/Navigation/ContextualSidebar.swift`:

```swift
struct ContextualSidebar: View {
    // ... existing properties
    let yourTabViewModel: YourTabViewModel?  // Add your ViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            SearchField(placeholder: selectedTab.searchPlaceholder, text: $searchText)
            
            // Contextual navigation
            contextualNavigation
            
            // Library stats (always at bottom)
            LibraryStatsSection()
        }
        .frame(width: Self.width)
    }
    
    @ViewBuilder
    private var contextualNavigation: some View {
        switch selectedTab {
        // ... existing cases
        case .yourNewTab:
            YourTabNavigationContent(viewModel: yourTabViewModel)
        }
    }
}
```

Create sidebar navigation component:

```swift
// Sources/UI/Layout/Navigation/YourTabNavigationContent.swift
import SwiftUI

struct YourTabNavigationContent: View {
    @ObservedObject var viewModel: YourTabViewModel?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Your sidebar content here
                SidebarSection(title: "Your Section") {
                    // Navigation items, filters, etc.
                }
            }
            .padding()
        }
    }
}
```

### Step 7: Wire Up Search (if needed)

If your tab needs search functionality, add it to `MainWindowLayoutView`:

```swift
.onChange(of: searchText) { _, newValue in
    // ... existing search handlers
    else if selectedTab == .yourNewTab {
        Task {
            await yourTabViewModel?.updateSearchText(newValue)
        }
    }
}
```

Add search method to your ViewModel:

```swift
public func updateSearchText(_ text: String) async {
    // Implement search filtering logic
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    // Update filtered items based on search text
}
```

---

## Extending Existing Tabs

### Adding Features to Home Tab

1. **Add to `HomeViewModel`**: Extend `Sources/UI/Layout/Home/HomeViewModel.swift`
2. **Update `HomeContentView`**: Modify `Sources/UI/Layout/Home/HomeContentView.swift`
3. **Update Sidebar**: Add quick access links in `ContextualSidebar`

### Adding Features to Library Tab

1. **Add to `LibraryBrowserViewModel`**: Extend filtering, sorting, or grouping
2. **Update `LibraryBrowserView`**: Add new UI components
3. **Update Sidebar**: Add new browse modes or filters in `ContextualSidebar`

### Adding Features to Playlists Tab

1. **Add to `PlaylistSidebarViewModel`**: Extend playlist management
2. **Update `PlaylistBrowserView`**: Add new playlist features
3. **Update Sidebar**: Add new playlist actions

---

## Testing Requirements

### TDD Tests

Create unit tests following Right-BICEP principles:

```swift
// Tests/UITests/Layout/YourTab/YourTabViewModelTests.swift
final class YourTabViewModelTests: XCTestCase {
    var viewModel: YourTabViewModel!
    var mockService: MockYourService!
    
    override func setUp() {
        super.setUp()
        mockService = MockYourService()
        viewModel = YourTabViewModel(yourService: mockService)
    }
    
    // [Right]: Are the results right?
    func testLoadItems_WhenServiceReturnsItems_UpdatesItems() async {
        // Given
        let expectedItems = [YourItem(id: UUID(), name: "Test")]
        await mockService.setItems(expectedItems)
        
        // When
        await viewModel.loadItems()
        
        // Then
        XCTAssertEqual(viewModel.items, expectedItems)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    // [B]: Boundary conditions
    func testLoadItems_WhenServiceReturnsEmpty_ShowsEmptyList() async {
        // Test empty state
    }
    
    // [I]: Inverse relationships
    func testLoadItems_WhenServiceFails_ShowsError() async {
        // Test error handling
    }
    
    // [C]: Cross-checking
    func testLoadItems_MatchesServiceResults() async {
        // Verify ViewModel matches service output
    }
    
    // [E]: Error conditions
    func testLoadItems_WhenServiceThrows_HandlesError() async {
        // Test error handling
    }
    
    // [P]: Performance
    func testLoadItems_PerformanceWithManyItems() async {
        // Test performance characteristics
    }
}
```

### BDD Tests

Create behavior-driven tests:

```swift
// Tests/UITests/Layout/YourTab/YourTabViewModelBDDTests.swift
final class YourTabViewModelBDDTests: XCTestCase {
    func testScenario_UserViewsItems() async {
        // Given: User opens your tab
        // When: Items are loaded
        // Then: Items are displayed correctly
    }
    
    func testScenario_UserSearchesItems() async {
        // Given: User has items loaded
        // When: User types in search field
        // Then: Items are filtered by search text
    }
}
```

### UI Tests

Create UI/UX tests:

```swift
// Tests/UITests/Layout/YourTab/YourTabViewTests.swift
final class YourTabViewTests: XCTestCase {
    func testViewRendersCorrectly() {
        let viewModel = YourTabViewModel(yourService: MockYourService())
        let view = YourTabView(viewModel: viewModel)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    func testViewShowsLoadingState() {
        // Test loading indicator
    }
    
    func testViewShowsErrorState() {
        // Test error display
    }
}
```

### E2E Tests

Add to existing E2E test files:

```swift
// Tests/UITests/Layout/TabSwitchingE2ETests.swift
func testE2E_SwitchToYourNewTab() {
    // Test tab switching to your new tab
    // Test content updates
    // Test sidebar updates
}
```

---

## Sidebar Components

### Reusable Sidebar Components

Use existing sidebar components from `Sources/UI/Layout/Navigation/SidebarComponents.swift`:

- **`SidebarNavItem`** - Navigation item with icon and title
- **`SidebarActionButton`** - Action button (e.g., "New Playlist")
- **`SidebarRadioItem`** - Radio button for single selection
- **`SidebarSection`** - Section container with title

### Example: Adding Sidebar Section

```swift
struct YourTabNavigationContent: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Quick Access Section
                SidebarSection(title: "Quick Access") {
                    SidebarNavItem(icon: "star.fill", title: "Favorites") {
                        // Action
                    }
                    SidebarNavItem(icon: "clock.fill", title: "Recent") {
                        // Action
                    }
                }
                
                // Filters Section
                SidebarSection(title: "Filters") {
                    SidebarRadioItem(
                        title: "All Items",
                        isSelected: true,
                        action: { }
                    )
                    SidebarRadioItem(
                        title: "Filtered",
                        isSelected: false,
                        action: { }
                    )
                }
                
                // Actions Section
                SidebarSection(title: "Actions") {
                    SidebarActionButton(icon: "plus", title: "New Item") {
                        // Action
                    }
                }
            }
            .padding()
        }
    }
}
```

---

## Search Integration

### Implementing Search

1. **Add search method to ViewModel**:

```swift
@Published public private(set) var filteredItems: [YourItem] = []
@Published public private(set) var searchText: String = ""

private var allItems: [YourItem] = []

public func updateSearchText(_ text: String) async {
    searchText = text
    applySearchFilter()
}

private func applySearchFilter() {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if trimmed.isEmpty {
        filteredItems = allItems
    } else {
        filteredItems = allItems.filter { item in
            item.name.localizedCaseInsensitiveContains(trimmed) ||
            item.description.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
```

2. **Wire up in `MainWindowLayoutView`**:

```swift
.onChange(of: searchText) { _, newValue in
    if selectedTab == .yourNewTab {
        Task {
            await yourTabViewModel?.updateSearchText(newValue)
        }
    }
}
```

3. **Update search placeholder in `TabItem`**:

```swift
case .yourNewTab: return "Search your items..."
```

---

## ViewModel Best Practices

### State Management

```swift
@MainActor
public class YourTabViewModel: ObservableObject {
    // Published state
    @Published public private(set) var items: [YourItem] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    // Private state
    private var allItems: [YourItem] = []
    private var searchText: String = ""
    
    // Dependencies (injected)
    private let yourService: YourServiceProtocol
    
    // Public methods
    public func loadItems() async {
        // Implementation
    }
    
    // Private helpers
    private func applyFilters() {
        // Filtering logic
    }
}
```

### Error Handling

```swift
public func loadItems() async {
    isLoading = true
    error = nil
    
    do {
        items = try await yourService.getItems()
        allItems = items
        applyFilters()
    } catch {
        self.error = error
        items = []
        allItems = []
    }
    
    isLoading = false
}
```

### Dependency Injection

```swift
public init(yourService: YourServiceProtocol) {
    self.yourService = yourService
}

// In tests:
let mockService = MockYourService()
let viewModel = YourTabViewModel(yourService: mockService)
```

---

## Accessibility Requirements

### VoiceOver Support

All interactive elements must have:

```swift
.accessibilityLabel("Descriptive label")
.accessibilityHint("Action description")
.accessibilityAddTraits(.isButton)  // For buttons
.accessibilityAddTraits(.isSelected)  // For selected items
.accessibilityValue("Current value")  // For dynamic values
```

### Keyboard Navigation

- All interactive elements must be keyboard-accessible
- Use `.keyboardShortcut()` for global shortcuts
- Ensure logical focus order (Tab key navigation)

### Example

```swift
Button("Action") {
    // Action
}
.accessibilityLabel("Action button")
.accessibilityHint("Performs the action. Press to activate.")
.accessibilityAddTraits(.isButton)
.keyboardShortcut("a", modifiers: .command)
```

---

## File Organization

### Directory Structure

```
Sources/UI/Layout/
├── Navigation/
│   ├── TabItem.swift
│   ├── NavigationTabBar.swift
│   ├── CollapsibleToolbar.swift
│   ├── ContextualSidebar.swift
│   └── YourTabNavigationContent.swift  # New
├── YourTab/  # New directory
│   ├── YourTabView.swift
│   └── YourTabViewModel.swift
├── MainWindowLayoutView.swift
└── MainWindowTabContentView.swift
```

### Test Structure

```
Tests/UITests/Layout/
├── YourTab/  # New directory
│   ├── YourTabViewModelTests.swift
│   ├── YourTabViewModelBDDTests.swift
│   └── YourTabViewTests.swift
└── TabSwitchingE2ETests.swift  # Update
```

---

## Integration Checklist

When adding a new tab, ensure:

- [ ] Tab added to `TabItem` enum with all required properties
- [ ] ViewModel created with TDD tests (Right-BICEP)
- [ ] View created with proper SwiftUI structure
- [ ] Added to `MainWindowTabContentView` switch statement
- [ ] ViewModel initialized in `MainWindowLayoutView`
- [ ] Sidebar content created and added to `ContextualSidebar`
- [ ] Search functionality implemented (if needed)
- [ ] Keyboard shortcut assigned (⌘6, ⌘7, etc.)
- [ ] Accessibility labels and hints added
- [ ] TDD tests written and passing
- [ ] BDD tests written and passing
- [ ] UI tests written and passing
- [ ] E2E tests updated
- [ ] Documentation updated

---

## Example: Complete Tab Implementation

See existing tabs for reference:

- **Home Tab**: `Sources/UI/Layout/Home/`
- **Library Tab**: `Sources/UI/Layout/Navigation/` (LibraryBrowserViewModel)
- **Playlists Tab**: `Sources/UI/Layout/Navigation/` (PlaylistSidebarViewModel)
- **Devices Tab**: `Sources/UI/Layout/Navigation/` (DeviceSidebarViewModel)
- **Visualiser Tab**: `Sources/UI/Visualiser/`

Each follows the same pattern:
1. ViewModel with business logic
2. View with SwiftUI UI
3. Sidebar navigation content
4. Comprehensive test coverage

---

## Common Patterns

### Loading State Pattern

```swift
if viewModel.isLoading {
    ProgressView("Loading...")
} else if let error = viewModel.error {
    Text("Error: \(error.localizedDescription)")
} else {
    // Content
}
```

### Empty State Pattern

```swift
if viewModel.items.isEmpty {
    VStack {
        Image(systemName: "music.note.list")
        Text("No items found")
    }
} else {
    // List of items
}
```

### Search Pattern

```swift
.onChange(of: searchText) { _, newValue in
    if selectedTab == .yourTab {
        Task {
            await viewModel.updateSearchText(newValue)
        }
    }
}
```

---

## Related Documentation

- **UI Layout Design**: See `Documentation/16-ui-layout-redesign.md`
- **Testing Strategy**: See `Documentation/05-roadmap-and-testing-strategy.md`
- **Keyboard Shortcuts**: See `Documentation/17-keyboard-shortcuts-reference.md`
- **User Guide**: See `Documentation/18-user-guide-ui-layout.md`

---

## Version History

- **December 2025**: Initial developer guide created
  - Documented tab addition process
  - Documented ViewModel creation
  - Documented sidebar integration
  - Documented search integration
  - Documented testing requirements
  - Added code examples and patterns
  - Added integration checklist

