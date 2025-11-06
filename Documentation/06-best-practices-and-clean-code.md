# Best Practices and Clean Code Guidelines

## Swift

### API Design Guidelines
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use clear, descriptive names
- Prefer value types (structs, enums) over reference types
- Use optionals for nullable values
- Leverage Swift's type system (generics, protocols, associated types)

### Code Style
- Use SwiftLint for consistency
- 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Use `guard` for early returns
- Prefer `let` over `var`

### Architecture Patterns
- **MVVM**: ViewModels for business logic, Views for presentation
- **Protocol-Oriented Programming**: Use protocols for abstraction
- **Dependency Injection**: Pass dependencies via initializers
- **Combine**: Use for reactive data flow

### Example: Clean Swift Code

```swift
// ❌ Bad
class Player {
    var state: Int = 0
    func play() { state = 1 }
    func pause() { state = 2 }
}

// ✅ Good
enum PlaybackState {
    case stopped
    case playing
    case paused
}

protocol AudioPlayback {
    var state: CurrentValueSubject<PlaybackState, Never> { get }
    func play() throws
    func pause()
}

final class AudioPlayer: AudioPlayback {
    private let engine: AudioEngine
    let state = CurrentValueSubject<PlaybackState, Never>(.stopped)

    init(engine: AudioEngine) {
        self.engine = engine
    }

    func play() throws {
        try engine.start()
        state.send(.playing)
    }

    func pause() {
        engine.stop()
        state.send(.paused)
    }
}
```

### Concurrency
- Use `async/await` for asynchronous operations
- Use `@MainActor` for UI-related code
- Use `TaskGroup` for parallel operations
- Use `actor` for shared mutable state
- Avoid blocking the main thread

### Testing
- Use XCTest framework
- Follow AAA pattern (Arrange, Act, Assert)
- Use descriptive test names: `testPlaybackStateTransitionsFromStoppedToPlaying()`
- Mock dependencies using protocols
- Use `XCTExpectation` for async operations

### Resources
- [Swift Style Guide](https://github.com/raywenderlich/swift-style-guide)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)

---

## C++

### Core Guidelines
- Follow [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)
- Prefer modern C++ (C++17/20)
- Use RAII for resource management
- Avoid raw pointers, use smart pointers
- Prefer `const` and `constexpr`

### Code Style
- Use `clang-format` for consistency
- 4 spaces indentation
- Maximum line length: 100 characters
- Use `nullptr` instead of `NULL`
- Use `auto` judiciously (when type is obvious)

### Memory Management
- Use `std::unique_ptr` for exclusive ownership
- Use `std::shared_ptr` for shared ownership
- Avoid `new`/`delete`, use smart pointers
- Use `std::vector` instead of C arrays

### Example: Clean C++ Code

```cpp
// ❌ Bad
class AudioEngine {
    float* buffer;
    int size;
public:
    AudioEngine(int s) {
        buffer = new float[s];
        size = s;
    }
    ~AudioEngine() {
        delete[] buffer;
    }
};

// ✅ Good
class AudioEngine {
    std::vector<float> buffer;
public:
    explicit AudioEngine(size_t size) : buffer(size) {}
    // Destructor not needed - vector handles cleanup
};
```

### Testing
- Use Google Test framework
- Test one thing per test
- Use descriptive test names: `TEST(AudioEngine, StartsPlaybackWhenInitialized)`
- Use fixtures for setup/teardown
- Mock external dependencies

### Resources
- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
- [Effective Modern C++](https://www.aristeia.com/books.html)

---

## Rust

### API Guidelines
- Follow [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- Use `Result<T, E>` for fallible operations
- Prefer `&str` over `String` in function parameters
- Use `Option<T>` for nullable values
- Leverage Rust's type system (enums, traits, generics)

### Code Style
- Use `rustfmt` for formatting
- Use `clippy` for linting
- Follow Rust naming conventions (snake_case, PascalCase)
- Maximum line length: 100 characters

### Error Handling
- Use `thiserror` or `anyhow` for error types
- Propagate errors with `?` operator
- Provide context with `.context()` or `.with_context()`

### Example: Clean Rust Code

```rust
// ❌ Bad
fn parse_tag(data: Vec<u8>) -> String {
    String::from_utf8(data).unwrap()
}

// ✅ Good
use thiserror::Error;

#[derive(Error, Debug)]
enum TagError {
    #[error("Invalid UTF-8: {0}")]
    InvalidUtf8(#[from] std::string::FromUtf8Error),
}

fn parse_tag(data: &[u8]) -> Result<String, TagError> {
    String::from_utf8(data.to_vec())
        .map_err(TagError::InvalidUtf8)
}
```

### Testing
- Use built-in `#[test]` attributes
- Use `Result` in tests: `fn test_parse() -> Result<()>`
- Use `assert_eq!` for comparisons
- Use `#[cfg(test)]` for test modules

### Resources
- [The Rust Book](https://doc.rust-lang.org/book/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)

---

## JavaScript (for Plugin System)

### Style Guide
- Follow [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- Use ES6+ features
- Prefer `const` over `let`, avoid `var`
- Use arrow functions for callbacks
- Use template literals for strings

### Code Style
- Use ESLint for linting
- Use Prettier for formatting
- 2 spaces indentation
- Maximum line length: 100 characters
- Use semicolons consistently

### Example: Clean JavaScript Code

```javascript
// ❌ Bad
function getTrackMetadata(trackId) {
    var metadata = {};
    if (trackId) {
        metadata.id = trackId;
        metadata.name = "Unknown";
    }
    return metadata;
}

// ✅ Good
const getTrackMetadata = (trackId) => {
    if (!trackId) {
        return { id: null, name: 'Unknown' };
    }

    return {
        id: trackId,
        name: 'Unknown',
    };
};
```

### Testing
- Use Jest for unit tests
- Use descriptive test names: `it('should fetch metadata for valid track ID')`
- Use `describe` blocks for grouping
- Mock external APIs

### Resources
- [MDN JavaScript Guide](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide)
- [You Don't Know JS](https://github.com/getify/You-Dont-Know-JS)

---

## General Principles

### SOLID Principles
- **S**ingle Responsibility: Each class/function does one thing
- **O**pen/Closed: Open for extension, closed for modification
- **L**iskov Substitution: Subtypes must be substitutable
- **I**nterface Segregation: Many specific interfaces > one general
- **D**ependency Inversion: Depend on abstractions, not concretions

### DRY (Don't Repeat Yourself)
- Extract common code into functions/classes
- Use inheritance/composition appropriately
- Avoid copy-paste programming

### KISS (Keep It Simple, Stupid)
- Prefer simple solutions over complex ones
- Avoid premature optimization
- Write code that's easy to understand

### YAGNI (You Aren't Gonna Need It)
- Don't add features until needed
- Avoid over-engineering
- Focus on current requirements

### Code Review Checklist
- [ ] Code follows style guide
- [ ] Tests written and passing
- [ ] No hardcoded values (use constants/config)
- [ ] Error handling implemented
- [ ] Documentation/comments where needed
- [ ] Performance considerations addressed
- [ ] Security considerations addressed
- [ ] Accessibility considered (for UI code)

### Documentation
- Write self-documenting code (clear names)
- Add comments for "why", not "what"
- Document public APIs
- Keep README files updated
- Write ADRs (Architecture Decision Records) for major decisions

## Language-Specific Tools

### Swift
- **SwiftLint**: Code style enforcement
- **SwiftFormat**: Automatic code formatting
- **Instruments**: Performance profiling
- **XCTest**: Testing framework

### C++
- **clang-format**: Code formatting
- **clang-tidy**: Static analysis
- **Valgrind**: Memory leak detection
- **Google Test**: Testing framework

### Rust
- **rustfmt**: Code formatting
- **clippy**: Linting
- **cargo test**: Built-in testing
- **criterion**: Benchmarking

### JavaScript
- **ESLint**: Linting
- **Prettier**: Code formatting
- **Jest**: Testing framework
- **TypeScript**: Optional type safety

## Performance Guidelines

### Swift
- Use value types (structs) when possible
- Avoid unnecessary object creation
- Use lazy properties for expensive computations
- Profile with Instruments

### C++
- Prefer stack allocation over heap
- Use move semantics when appropriate
- Avoid unnecessary copies
- Profile with profiling tools

### Rust
- Leverage zero-cost abstractions
- Use appropriate data structures
- Avoid unnecessary allocations
- Profile with `cargo bench`

### JavaScript
- Avoid creating functions in loops
- Use appropriate data structures
- Minimize DOM manipulation
- Profile with browser dev tools

## Security Guidelines

### General
- Validate all inputs
- Sanitize user data
- Use parameterized queries (SQL injection prevention)
- Keep dependencies updated
- Follow principle of least privilege

### Swift
- Use secure coding practices
- Validate file paths
- Sanitize user input
- Use keychain for sensitive data

### C++
- Avoid buffer overflows
- Use smart pointers
- Validate all inputs
- Use secure random number generators

### Rust
- Leverage Rust's safety guarantees
- Validate inputs
- Use `std::fs` for file operations
- Avoid `unsafe` unless necessary

### JavaScript
- Sanitize plugin inputs
- Validate API responses
- Use CSP (Content Security Policy) if applicable
- Avoid `eval()` and similar dangerous functions
