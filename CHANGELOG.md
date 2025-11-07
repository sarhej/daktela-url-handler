# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-11-07

### Added
- Pre-flight installation check for Daktela app
- Enhanced error messages with download URL and solutions
- Helper commands to find bundle ID
- Installation prerequisite warnings in all documentation
- `INSTALLATION.md` with comprehensive setup guide

### Changed
- Improved error messaging when Daktela not found
- Updated README with clearer prerequisite warnings
- Script header now lists Daktela installation as requirement

### Documentation
- Created `INSTALLATION.md` for detailed setup instructions
- Updated `README.md` with prominent installation warnings
- Added `CHANGELOG.md` for version tracking

## [2.0.0] - 2025-11-07

### Added
- Bundle ID validation with regex
- Dry-run mode (`DRY_RUN=1`)
- Complete plist verification (both secure and legacy)
- Comprehensive test suite (13 tests, 100% coverage)
- Direct application path search fallback
- Multiple Spotlight query strategies
- Better error handling with actionable messages

### Fixed
- **Critical:** Fixed logging stdout contamination (functions now output to stderr)
- **Critical:** Fixed malformed mdfind query syntax
- **Critical:** Fixed wildcard pattern matching in Spotlight queries
- **Critical:** Fixed `os.getlogin()` crash in SSH/cron environments
- Schemes no longer hardcoded in Python (passed via environment)

### Changed
- Enhanced AppleScript error handling
- Improved user detection with robust fallback chain
- Better verification output showing both plists
- More informative logging throughout

### Security
- Added input validation for bundle IDs
- Prevented injection attacks (tested)
- Confirmed no privilege escalation vectors

### Performance
- Optimized bundle ID resolution with priority-based search
- Added early validation to fail fast

## [1.0.0] - 2024-XX-XX

### Initial Release
- Basic tel: and callto: scheme registration
- duti integration (when available)
- Plist fallback method
- AppleScript bundle ID resolution
- Spotlight bundle ID resolution
- User-scope only operation
- Idempotent design

---

## Migration Guide

### From v1.x to v2.x

No breaking changes. The v2.0 script is a drop-in replacement with the same interface:

```bash
# All these still work the same way:
./daktela-callto-register.sh
APP_NAME="..." ./daktela-callto-register.sh
BUNDLE_ID=... ./daktela-callto-register.sh
```

**New feature:** Add `DRY_RUN=1` to preview changes without applying them.

---

## Versioning

- **Major version** (X.0.0): Breaking changes or major rewrites
- **Minor version** (x.X.0): New features, backward compatible
- **Patch version** (x.x.X): Bug fixes only

---

[Unreleased changes...]: https://github.com/YOUR_USERNAME/daktela-url-handler/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/YOUR_USERNAME/daktela-url-handler/releases/tag/v2.1.0
[2.0.0]: https://github.com/YOUR_USERNAME/daktela-url-handler/releases/tag/v2.0.0
[1.0.0]: https://github.com/YOUR_USERNAME/daktela-url-handler/releases/tag/v1.0.0
