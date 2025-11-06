# Resources Directory

Assets and resources for the Audientia application.

## Structure

```
Resources/
└── Assets.xcassets/    # Asset catalog
    └── AppIcon.appiconset/ # Application icon
```

## Assets

### App Icon
The application icon is defined in `Assets.xcassets/AppIcon.appiconset/` with multiple sizes for macOS:
- 16x16 (1x and 2x)
- 32x32 (1x and 2x)
- 128x128 (1x and 2x)
- 256x256 (1x and 2x)
- 512x512 (1x and 2x)

The icon source image is `brand/audientia.png` in the project root.

## Adding Assets

### Images
Add images to the asset catalog:
1. Open `Assets.xcassets` in Xcode
2. Right-click → New Image Set
3. Drag images into the appropriate slots (1x, 2x, 3x)

### Colors
Add colors to the asset catalog:
1. Open `Assets.xcassets` in Xcode
2. Right-click → New Color Set
3. Define colors for light and dark appearances

### Icons
Add SF Symbols or custom icons:
1. Use SF Symbols for system icons (recommended)
2. Add custom icons to the asset catalog as image sets

## Usage in Code

### SwiftUI
```swift
Image("icon-name")
    .resizable()
    .frame(width: 32, height: 32)

Color("custom-color")
```

### AppKit
```swift
let image = NSImage(named: "icon-name")
let color = NSColor(named: "custom-color")
```

## Asset Organization

- **Icons**: App icons, toolbar icons, menu icons
- **Images**: Artwork placeholders, UI graphics
- **Colors**: Theme colors, semantic colors
- **Data**: Sample data files (if needed)

## Best Practices

1. Use vector assets (PDF) when possible for scalability
2. Provide @2x and @3x variants for raster images
3. Use SF Symbols for system-style icons
4. Organize assets into logical groups in the catalog
5. Name assets descriptively and consistently

