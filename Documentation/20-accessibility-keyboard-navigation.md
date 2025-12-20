# Accessibility - Keyboard Navigation Implementation

## Overview

This document tracks the implementation of comprehensive keyboard navigation support for Audientia, enabling users to navigate and interact with the application entirely via keyboard.

**Status**: 🔄 **IN PROGRESS**  
**Branch**: `22_accessibility`  
**Date**: December 2025

---

## Implementation Plan

### Phase 1: Foundation ✅ COMPLETE

- [x] **KeyboardNavigationManager** - Centralized keyboard navigation state management
  - [x] `KeyboardNavigationSection.swift` - UI sections (toolbar, sidebar, content, player)
  - [x] `KeyboardNavigationElement.swift` - Specific focusable elements
  - [x] `KeyboardNavigationManager.swift` - Focus order management and navigation operations
  - [x] TDD tests (`KeyboardNavigationManagerTests.swift`) with Right-BICEP coverage
  - [x] BDD tests (`KeyboardNavigationManagerBDDTests.swift`) for user scenarios

### Phase 2: Tab Key Navigation 🔄 IN PROGRESS

- [x] **KeyboardNavigationManager Integration** - Added to MainWindowLayoutView
- [x] **Keyboard Event Handlers** - Tab, Shift+Tab, Enter, Space key handling
- [x] **Focus Indicators** - Visual feedback for focused elements
  - [x] Toolbar tabs - Focus ring added to TabButton
  - [x] Sidebar elements - Focus indicators added to SidebarNavItem and SidebarActionButton
  - [x] Player controls - Focus indicators added to transport controls
- [ ] **Component Integration** - Wire up keyboard navigation to all interactive elements
  - [x] Toolbar tabs - Focus indicators added
  - [x] Sidebar elements - Focus indicators added
  - [ ] Content area (tracks, playlists, devices) - In progress
  - [x] Player controls - Focus indicators added

### Phase 3: Arrow Key Navigation 🔄 IN PROGRESS

- [x] **ListNavigationManager** - Created manager for arrow key navigation
  - [x] `ListNavigationManager.swift` - Generic list navigation manager
  - [x] TDD tests (`ListNavigationManagerTests.swift`) with Right-BICEP coverage
  - [x] BDD tests (`ListNavigationManagerBDDTests.swift`) for user scenarios
- [x] **List Navigation** - Up/Down arrow keys for vertical lists
- [x] **Grid Navigation** - Left/Right arrow keys for grid layouts
- [x] **Selection Management** - Track selected items in lists/grids
- [x] **Library Browser** - Arrow key navigation integrated into LibraryBrowserView
  - [x] Up/Down arrow keys for list view
  - [x] Left/Right arrow keys for grid view
  - [x] Selection syncing with TrackSelectionStore
- [x] **Playlist Browser** - Arrow key navigation integrated into PlaylistBrowserView
  - [x] Up/Down arrow keys for playlist list
  - [x] Selection syncing with selectedPlaylist
  - [x] TDD tests (`PlaylistBrowserViewKeyboardNavigationTests.swift`)
  - [x] BDD tests (`PlaylistBrowserViewKeyboardNavigationBDDTests.swift`)
- [x] **Device List** - Arrow key navigation integrated into DeviceListSection
  - [x] Up/Down arrow keys for device list
  - [x] Selection syncing with selectedDevice
  - [x] TDD tests (`DeviceListSectionKeyboardNavigationTests.swift`)
  - [x] BDD tests (`DeviceListSectionKeyboardNavigationBDDTests.swift`)

### Phase 4: Enter/Space Activation 🔄 IN PROGRESS

- [x] **KeyboardActivationManager** - Created manager for Enter/Space/Escape activation
  - [x] `KeyboardActivationManager.swift` - Activation manager with protocol-based design
  - [x] `KeyboardActivatable` protocol - Protocol for activatable elements
  - [x] TDD tests (`KeyboardActivationManagerTests.swift`) with Right-BICEP coverage
  - [x] BDD tests (`KeyboardActivationManagerBDDTests.swift`) for user scenarios
- [x] **KeyboardActivationModifier** - View modifier for easy integration
  - [x] `KeyboardActivationModifier.swift` - SwiftUI modifier for Enter/Space/Escape
  - [x] TDD tests (`KeyboardActivationModifierTests.swift`)
- [x] **Player Controls** - Enter/Space activation integrated
  - [x] Play/Pause button - Enter and Space activate
  - [x] Previous/Next/Stop buttons - Enter activates
- [ ] **Dialog Activation** - Enter to submit, Esc to cancel (partially complete - dialogs already have keyboard shortcuts)
- [ ] **Button Activation** - Enter/Space to activate buttons (in progress - player controls complete)

### Phase 5: Settings UI Keyboard Navigation ⏳ PENDING

- [ ] **Settings Window** - Tab navigation through settings sections
- [ ] **Settings Panels** - Tab navigation through controls
- [ ] **Form Navigation** - Tab through form fields
- [ ] **Form Submission** - Enter to submit forms

### Phase 6: Dialog and Modal Navigation 🔄 IN PROGRESS

- [x] **DialogFocusManager** - Created manager for dialog focus trapping
  - [x] `DialogFocusManager.swift` - Focus trapping and restoration manager
  - [x] TDD tests (`DialogFocusManagerTests.swift`) with Right-BICEP coverage
  - [x] BDD tests (`DialogFocusManagerBDDTests.swift`) for user scenarios
- [x] **Create Playlist Dialog** - Keyboard navigation integrated
  - [x] Tab/Shift+Tab navigation between elements
  - [x] Enter key activation for buttons
  - [x] Escape key to cancel
  - [x] Focus trapping and restoration
  - [x] Integration tests (`DialogKeyboardNavigationTests.swift`)
- [ ] **Create Smart Playlist Dialog** - Tab navigation, Enter/Esc handling (integration pending)
- [ ] **Conflict Resolution Dialog** - Tab navigation, Enter to resolve (integration pending)
- [ ] **Device Configuration Dialog** - Tab navigation, Enter/Esc handling (integration pending)
- [x] **Focus Trapping** - DialogFocusManager provides focus trapping
- [x] **Focus Restoration** - DialogFocusManager provides focus restoration

---

## Architecture

### KeyboardNavigationManager

The `KeyboardNavigationManager` is the central component managing keyboard navigation state:

```swift
@MainActor
public final class KeyboardNavigationManager: ObservableObject {
    @Published public private(set) var currentFocus: KeyboardNavigationElement?
    public let focusOrder: [KeyboardNavigationSection]
    
    func setFocus(to element: KeyboardNavigationElement)
    func moveFocusForward() -> KeyboardNavigationElement?
    func moveFocusBackward() -> KeyboardNavigationElement?
    func moveFocusToSection(_ section: KeyboardNavigationSection) -> KeyboardNavigationElement?
}
```

### ListNavigationManager

The `ListNavigationManager` manages arrow key navigation for lists and grids:

```swift
@MainActor
public final class ListNavigationManager<T: Hashable>: ObservableObject {
    @Published public private(set) var selectedIndex: Int?
    @Published public private(set) var itemCount: Int
    
    func updateItems(_ items: [T])
    func selectIndex(_ index: Int?)
    func selectItem(_ item: T)
    func moveUp() -> Int?
    func moveDown() -> Int?
    func moveLeft(columnsPerRow: Int) -> Int?
    func moveRight(columnsPerRow: Int) -> Int?
}
```

### KeyboardActivationManager

The `KeyboardActivationManager` manages Enter/Space/Escape key activation:

```swift
@MainActor
public final class KeyboardActivationManager: ObservableObject {
    @Published public private(set) var focusedElement: (any KeyboardActivatable)?
    
    func register(_ element: any KeyboardActivatable, identifier: String)
    func unregister(identifier: String)
    func setFocus(to identifier: String)
    func clearFocus()
    func handleEnter() -> Bool
    func handleSpace() -> Bool
    func handleEscape() -> Bool
    func handleActivation(_ type: KeyboardActivationType) -> Bool
}

public protocol KeyboardActivatable {
    func activate()
    func toggle()
    func cancel()
}
```

### DialogFocusManager

The `DialogFocusManager` manages focus trapping and restoration for dialogs:

```swift
@MainActor
public final class DialogFocusManager: ObservableObject {
    @Published public private(set) var previousFocusIdentifier: String?
    @Published public private(set) var dialogFocusIdentifier: String?
    @Published public private(set) var isFocusTrapped: Bool
    
    func registerFocusableElement(_ identifier: String)
    func unregisterFocusableElement(_ identifier: String)
    func openDialog(previousFocus: String?)
    func closeDialog()
    func moveFocusForward() -> String?
    func moveFocusBackward() -> String?
    func setFocus(to identifier: String)
}
```

### Focus Order

Keyboard navigation follows this order:

1. **Toolbar** (if expanded)
   - Home tab
   - Library tab
   - Playlists tab
   - Devices tab
   - Visualiser tab
   - Collapse/Expand button

2. **Sidebar**
   - Search field
   - Quick Access items (Home tab)
   - Browse By items (Library tab)
   - Playlist list (Playlists tab)
   - Device list (Devices tab)
   - Visualisation style options (Visualiser tab)
   - Action buttons

3. **Main Content Area**
   - Tab-specific content (tracks, playlists, devices, visualisation)

4. **Player Controls**
   - Previous track button
   - Play/Pause button
   - Stop button
   - Next track button
   - Shuffle button
   - Loop button
   - Volume control
   - Collapse/Expand button

---

## Keyboard Shortcuts

### Navigation

| Key | Action | Description |
|-----|--------|-------------|
| **Tab** | Next Focus | Move focus to next interactive element |
| **Shift+Tab** | Previous Focus | Move focus to previous interactive element |
| **Enter** | Activate | Activate focused element |
| **Space** | Toggle | Toggle focused element (play/pause, expand/collapse) |
| **Esc** | Cancel/Close | Close dialogs, cancel actions |

### Arrow Keys (Lists/Grids)

| Key | Action | Description |
|-----|--------|-------------|
| **↑** | Move Up | Move selection up in vertical lists |
| **↓** | Move Down | Move selection down in vertical lists |
| **←** | Move Left | Move selection left in horizontal lists/grids |
| **→** | Move Right | Move selection right in horizontal lists/grids |

---

## Testing Strategy

### TDD Tests

All keyboard navigation components have comprehensive TDD tests following Right-BICEP principles:

- **[Right]**: Verify focus order, navigation operations, activation behavior
- **[B]oundary**: First/last elements, empty focus, wrapping, empty lists
- **[I]nverse**: Forward then backward, backward then forward, up then down
- **[C]ross-Check**: Compare with expected navigation flow, verify method calls
- **[E]rror**: Invalid elements, missing focus, out-of-bounds indices
- **[P]erformance**: Fast focus operations, efficient navigation with large lists
- **Edge**: Focus restoration, state persistence, selection during filtering

### BDD Tests

User scenario tests for keyboard navigation workflows:

- "As a keyboard-only user, when I press Tab, then focus should move through all sections"
- "As a keyboard-only user, when I press Shift+Tab, then focus should move backward"
- "As a keyboard-only user, when I press Tab from the last element, then focus should wrap to first"
- "As a keyboard-only user, when I navigate forward then backward, then I should return to original position"
- "As a keyboard-only user, when I press Down arrow in a list, then selection should move to the next item"
- "As a keyboard-only user, when I press Enter on a focused button, then the button should be activated"
- "As a keyboard-only user, when I press Space on a focused toggle, then the toggle state should change"

### Mocking Strategy

Mocking is used extensively for testing keyboard navigation components:

#### Mock Components

1. **MockPlaylistManager** - Used in `PlaylistBrowserViewKeyboardNavigationTests` to provide test data without database dependencies
2. **MockActivatable** - Used in `KeyboardActivationManagerTests` to verify activation method calls without UI dependencies
3. **Mock ViewModels** - Used to test view integration without full view rendering

#### Mocking Patterns

- **Protocol-Based Mocking**: Components use protocols (e.g., `KeyboardActivatable`, `PlaylistManagerProtocol`) to enable easy mocking
- **State Verification**: Mocks track method calls and state changes for verification
- **Isolation**: Each test uses fresh mocks to ensure test independence
- **Behavior Verification**: Tests verify both state changes and method invocations

#### Test Data Factories

Helper methods create test data consistently:
- `createTestPlaylists(count:)` - Creates test playlists with predictable data
- `createTestTracks(count:)` - Creates test tracks for library navigation tests
- `createTestDevices(count:)` - Creates test devices for device list navigation tests

#### Integration Testing

Integration tests verify keyboard navigation works across multiple views:
- **Cross-View Navigation**: Tests navigation consistency across Library, Playlist, and Device views
- **Manager Integration**: Tests ListNavigationManager and KeyboardActivationManager work with different types
- **End-to-End Workflows**: Tests complete keyboard navigation workflows from user perspective

---

## Files Created

### Source Files

- `Sources/UI/Accessibility/KeyboardNavigationSection.swift` - Navigation sections enum
- `Sources/UI/Accessibility/KeyboardNavigationElement.swift` - Focusable elements enum
- `Sources/UI/Accessibility/KeyboardNavigationManager.swift` - Navigation manager
- `Sources/UI/Accessibility/KeyboardNavigationModifier.swift` - View modifier for keyboard navigation
- `Sources/UI/Accessibility/FocusIndicatorModifier.swift` - Focus indicator modifier
- `Sources/UI/Accessibility/ListNavigationManager.swift` - Generic list navigation manager for arrow keys
- `Sources/UI/Accessibility/KeyboardActivationManager.swift` - Enter/Space/Escape activation manager
- `Sources/UI/Accessibility/KeyboardActivationModifier.swift` - View modifier for Enter/Space/Escape activation
- `Sources/UI/Accessibility/DialogFocusManager.swift` - Dialog focus trapping and restoration manager

### Test Files

- `Tests/UITests/Accessibility/KeyboardNavigationManagerTests.swift` - TDD tests
- `Tests/UITests/Accessibility/KeyboardNavigationManagerBDDTests.swift` - BDD tests
- `Tests/UITests/Accessibility/ListNavigationManagerTests.swift` - TDD tests for list navigation
- `Tests/UITests/Accessibility/ListNavigationManagerBDDTests.swift` - BDD tests for list navigation
- `Tests/UITests/Accessibility/PlaylistBrowserViewKeyboardNavigationTests.swift` - TDD tests for PlaylistBrowserView
- `Tests/UITests/Accessibility/PlaylistBrowserViewKeyboardNavigationBDDTests.swift` - BDD tests for PlaylistBrowserView
- `Tests/UITests/Accessibility/DeviceListSectionKeyboardNavigationTests.swift` - TDD tests for DeviceListSection
- `Tests/UITests/Accessibility/DeviceListSectionKeyboardNavigationBDDTests.swift` - BDD tests for DeviceListSection
- `Tests/UITests/Accessibility/KeyboardActivationManagerTests.swift` - TDD tests for activation manager
- `Tests/UITests/Accessibility/KeyboardActivationManagerBDDTests.swift` - BDD tests for activation manager
- `Tests/UITests/Accessibility/KeyboardActivationModifierTests.swift` - TDD tests for activation modifier
- `Tests/UITests/Accessibility/DialogFocusManagerTests.swift` - TDD tests for dialog focus manager
- `Tests/UITests/Accessibility/DialogFocusManagerBDDTests.swift` - BDD tests for dialog focus manager
- `Tests/UITests/Accessibility/DialogKeyboardNavigationTests.swift` - Integration tests for dialog keyboard navigation
- `Tests/UITests/Accessibility/KeyboardNavigationIntegrationTests.swift` - Integration tests for keyboard navigation across views

---

## Next Steps

1. **Complete Tab Key Navigation Integration**
   - Add focus indicators to all interactive elements
   - Wire up keyboard navigation to toolbar, sidebar, content, and player components
   - Test Tab/Shift+Tab navigation through entire UI

2. **Implement Arrow Key Navigation**
   - Add Up/Down arrow key handling for lists
   - Add Left/Right arrow key handling for grids
   - Implement selection management

3. **Complete Enter/Space Activation**
   - Wire up Enter key for all activatable elements
   - Wire up Space key for toggle actions
   - Test activation workflows

4. **Settings UI Keyboard Navigation**
   - Add Tab navigation to Settings window
   - Add form navigation
   - Test settings workflows

5. **Dialog and Modal Navigation**
   - Add keyboard navigation to all dialogs
   - Implement focus trapping
   - Implement focus restoration

---

## References

- [Apple Human Interface Guidelines - Keyboard Navigation](https://developer.apple.com/design/human-interface-guidelines/keyboards-and-input)
- [SwiftUI Focus Management](https://developer.apple.com/documentation/swiftui/focus-management)
- [Accessibility Best Practices](https://developer.apple.com/accessibility/)

