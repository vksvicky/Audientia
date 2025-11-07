# Git Hooks Documentation

## Overview

Audientia uses git hooks to enforce best practices and clean code principles as outlined in [`06-best-practices-and-clean-code.md`](06-best-practices-and-clean-code.md).

## Pre-commit Hook

The pre-commit hook automatically runs before each commit and performs comprehensive code quality checks.

### Features

1. **Merge Conflict Detection** - Prevents committing files with unresolved conflicts
2. **File Size Validation** - Blocks files larger than 1MB (except in allowed directories)
3. **Secrets Scanning** - Detects potential API keys, passwords, and credentials
4. **Line Length Enforcement** - Enforces max line lengths (120 chars Swift, 100 others)
5. **Debug Code Detection** - Warns about print statements in production code
6. **TODO/FIXME Tracking** - Warns about TODO/FIXME comments in production code
7. **Audio File Detection** - Prevents committing audio files (all supported formats are git-ignored)
8. **File Extension Validation** - Ensures files have proper extensions
9. **Language-Specific Checks**:
   - **Swift**: SwiftLint and SwiftFormat
   - **Rust**: rustfmt and clippy
   - **C++**: clang-format
   - **JavaScript**: ESLint and Prettier

### Installation

The hook is automatically installed when you clone the repository. To manually set it up:

```bash
./Scripts/setup_git_hooks.sh
```

Or manually:

```bash
chmod +x .git/hooks/pre-commit
```

### Running Checks Manually

You can run pre-commit checks manually without committing:

```bash
# Check all staged files
./Scripts/pre_commit_checks.sh

# Check specific files
./Scripts/pre_commit_checks.sh Sources/Shared/Models/Track.swift

# Check multiple files
./Scripts/pre_commit_checks.sh Sources/Shared/Models/*.swift
```

This is useful for:
- Testing changes before staging
- Checking files during development
- Verifying fixes before committing

### Usage

The hook runs automatically on `git commit`. If checks fail, the commit is blocked.

**Example:**
```bash
git add Sources/Shared/Models/Track.swift
git commit -m "Add Track model"
# Pre-commit hook runs automatically
```

**Bypass (not recommended):**
```bash
git commit --no-verify -m "Emergency commit"
```

### Configuration

#### Environment Variables

- `SKIP_TESTS=true` - Skip test execution (default: true, tests are slow)

#### Customization

Edit `.git/hooks/pre-commit` to customize:

```bash
# Configuration at the top of the file
MAX_FILE_SIZE=1048576          # 1MB in bytes
MAX_LINE_LENGTH_SWIFT=120      # Max line length for Swift
MAX_LINE_LENGTH_OTHER=100      # Max line length for other languages
```

### Required Tools

For full functionality, install:

**Swift:**
```bash
brew install swiftlint swiftformat
```

**Rust:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**C++:**
```bash
brew install llvm  # Includes clang-format
```

**JavaScript (optional):**
```bash
npm install -g eslint prettier
```

The hook gracefully skips checks if tools are not installed, but shows warnings.

### SwiftLint Configuration

SwiftLint is configured via `.swiftlint.yml` with settings aligned to our best practices:

- Line length: 120 (warning), 150 (error)
- File length: 500 (warning), 1000 (error)
- Function body length: 50 (warning), 100 (error)
- Cyclomatic complexity: 10 (warning), 20 (error)

### Checks Explained

#### 1. Merge Conflict Markers
Prevents committing files with `<<<<<<<`, `=======`, `>>>>>>>` markers.

#### 2. File Size
Blocks files larger than 1MB unless in:
- `Resources/`
- `.xcassets`
- `DerivedData/`
- `build/`
- `target/`
- `node_modules/`

#### 3. Secrets Detection
Scans for patterns like:
- `password = "..."` or `password='...'`
- `api_key = "..."` or `api-key = "..."`
- `BEGIN PRIVATE KEY`
- AWS access keys
- And more...

#### 4. Line Length
- Swift: 120 characters
- Other languages: 100 characters
- Checks only staged changes

#### 5. Debug Code
Warns about:
- `print(...)`
- `NSLog(...)`
- `console.log(...)`
- `debugPrint(...)`
- `fprintf(..., stderr)`

Skipped in test files.

#### 6. TODO/FIXME
Warns about TODO/FIXME/XXX/HACK comments in production code.
Skipped in test files and documentation.

#### 7. File Extensions
Validates files have standard extensions:
- Swift: `.swift`
- Rust: `.rs`
- C++: `.cpp`, `.hpp`, `.h`, `.c`
- JavaScript: `.js`, `.jsx`, `.ts`, `.tsx`
- Config: `.json`, `.yml`, `.yaml`, `.plist`
- Documentation: `.md`, `.txt`
- Scripts: `.sh`, `.rb`, `.py`

#### 8. Language-Specific Checks

**Swift:**
- Runs SwiftLint with strict mode
- Checks SwiftFormat formatting
- Uses `.swiftlint.yml` configuration

**Rust:**
- Runs `rustfmt --check`
- Runs `cargo clippy` (if Cargo.toml exists)

**C++:**
- Checks `clang-format` formatting

**JavaScript:**
- Runs ESLint (if `.eslintrc` exists)
- Checks Prettier formatting (if `.prettierrc` exists)

### Output

The hook provides color-coded output:

- ✅ **Green** - Check passed
- ⚠️ **Yellow** - Warning (doesn't block commit)
- ❌ **Red** - Error (blocks commit)
- ℹ️ **Blue** - Information

### Troubleshooting

**Hook not running:**
```bash
# Check if executable
ls -l .git/hooks/pre-commit

# Make executable
chmod +x .git/hooks/pre-commit

# Verify git config
git config core.hooksPath
```

**False positives:**
- Review the specific check
- Adjust patterns in the hook if needed
- Use `--no-verify` only for emergencies

**Slow performance:**
- Tests are disabled by default
- SwiftLint can be slow on large codebases
- Consider running checks manually before committing

**Tool not found:**
- Install missing tools (see Required Tools above)
- Hook will skip checks gracefully but show warnings

### Best Practices

1. **Fix issues, don't bypass** - Use `--no-verify` only for emergencies
2. **Run checks locally** - Fix issues before committing
3. **Keep tools updated** - Update SwiftLint, SwiftFormat, etc. regularly
4. **Review warnings** - Address warnings even if they don't block commits
5. **Test before committing** - Run tests manually if needed

### Integration with CI/CD

The pre-commit hook complements CI/CD checks:

- **Pre-commit**: Fast, local checks before commit
- **CI/CD**: Comprehensive checks including full test suite

Both should pass for code to be merged.

### Related Documentation

- [`06-best-practices-and-clean-code.md`](06-best-practices-and-clean-code.md) - Best Practices and Clean Code Guidelines
- [`05-roadmap-and-testing-strategy.md`](05-roadmap-and-testing-strategy.md) - Testing Strategy
- [`07-logging-observability.md`](07-logging-observability.md) - Logging and Observability

### Support

For issues or questions:
- Check `.git/hooks/README.md` for detailed hook documentation
- Review hook output for specific error messages
- See [`06-best-practices-and-clean-code.md`](06-best-practices-and-clean-code.md) for coding standards

