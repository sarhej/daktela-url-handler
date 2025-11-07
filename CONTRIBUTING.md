# Contributing to Daktela URL Handler

Thank you for considering contributing! 🎉

This is a small but important tool, and we welcome improvements from the community.

## 🚀 Quick Start for Contributors

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/daktela-url-handler.git
cd daktela-url-handler

# Make executable
chmod +x daktela-callto-register.sh run-tests.sh

# Run tests
./run-tests.sh
```

## 📋 How to Contribute

### Reporting Bugs

Found a bug? Please [open an issue](../../issues/new) with:

1. **macOS version** (run `sw_vers`)
2. **Daktela version** (if known)
3. **Error message** or unexpected behavior
4. **Steps to reproduce**
5. **Debug output** (run with `bash -x ./daktela-callto-register.sh`)

### Suggesting Enhancements

Have an idea? [Open an issue](../../issues/new) describing:

1. **The problem** you're trying to solve
2. **Your proposed solution**
3. **Why it would be useful** to others
4. **Any alternatives** you've considered

### Pull Requests

We love pull requests! Here's the process:

1. **Fork** the repository
2. **Create a branch** (`git checkout -b feature/my-feature`)
3. **Make your changes**
4. **Test thoroughly** (`./run-tests.sh`)
5. **Commit with clear messages** (`git commit -m 'Add: feature description'`)
6. **Push** (`git push origin feature/my-feature`)
7. **Open a Pull Request** with a clear description

## ✅ Pull Request Checklist

Before submitting, ensure:

- [ ] All tests pass (`./run-tests.sh` shows 13/13 passing)
- [ ] Code follows existing style (bash best practices)
- [ ] No new external dependencies (unless absolutely necessary)
- [ ] Security best practices maintained (no sudo, user-scope only)
- [ ] Error messages are helpful and actionable
- [ ] Documentation updated (if needed)
- [ ] CHANGELOG.md updated (if user-facing change)

## 🧪 Testing Guidelines

### Running Tests

```bash
# Run all tests
./run-tests.sh

# Test specific functionality manually
DRY_RUN=1 ./daktela-callto-register.sh
```

### Writing Tests

If adding new features, please add corresponding tests to `run-tests.sh`:

```bash
test_my_feature() {
  # Your test logic here
  if [[ condition ]]; then
    echo "  ✓ Test passed"
    return 0
  else
    echo "  ✗ Test failed"
    return 1
  fi
}
```

Then add it to the test execution in `main()`.

## 📝 Code Style

### Bash Style Guide

```bash
# Functions: lowercase with underscores
my_function() {
  local variable="value"
  echo "$variable"
}

# Variables: descriptive names
BUNDLE_ID="com.example.app"
app_name="My App"

# Error handling: always check exit codes
if ! command_that_might_fail; then
  err "Error message"
  exit 1
fi

# Logging: use the provided functions
info "Informational message"
ok "Success message"
err "Error message"
```

### Security Requirements

- ✅ **No sudo required** - Script must work without elevation
- ✅ **User-scope only** - No system-wide modifications
- ✅ **Input validation** - Validate all user-provided input
- ✅ **No eval** - Never use `eval` with user input
- ✅ **Quote variables** - Always quote: `"$variable"`
- ✅ **Set strict mode** - Use `set -euo pipefail`

## 🎯 Development Priorities

### High Priority

- macOS compatibility (new versions)
- Security fixes
- Critical bugs
- Test coverage improvements

### Medium Priority

- New features (with tests)
- Documentation improvements
- Performance optimizations
- Error message improvements

### Low Priority

- Code refactoring (unless improves readability)
- Style changes
- Minor optimizations

## 📚 Resources

### Useful References

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck](https://www.shellcheck.net/) - Shell script linter
- [macOS Launch Services](https://developer.apple.com/documentation/coreservices/launch_services)
- [duti documentation](https://github.com/moretension/duti)

### Testing Your Changes

```bash
# Dry run to see what would change
DRY_RUN=1 ./daktela-callto-register.sh

# Run in debug mode
bash -x ./daktela-callto-register.sh

# Check syntax
shellcheck daktela-callto-register.sh

# Run full test suite
./run-tests.sh
```

## 🤝 Code of Conduct

### Our Pledge

We're committed to providing a welcoming and inclusive environment for everyone.

### Expected Behavior

- ✅ Be respectful and considerate
- ✅ Welcome newcomers
- ✅ Accept constructive criticism
- ✅ Focus on what's best for the community
- ✅ Show empathy

### Unacceptable Behavior

- ❌ Harassment or discrimination
- ❌ Trolling or insulting comments
- ❌ Personal attacks
- ❌ Publishing others' private information

## 📞 Getting Help

- **Questions?** Open a [discussion](../../discussions)
- **Bugs?** Open an [issue](../../issues)
- **Ideas?** Start a [discussion](../../discussions)

## 🙏 Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes (for significant contributions)
- This project's README

Thank you for making this tool better! 🎉

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.


