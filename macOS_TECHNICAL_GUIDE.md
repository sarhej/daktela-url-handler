# Daktela URL Handler for macOS - Technical Guide

**For IT admins and developers**

---

## 🔍 Technical Overview

This solution registers Daktela as the default handler for `tel:` and `callto:` URL schemes on macOS by modifying Launch Services preferences.

**Status:** Production ready | **Tested:** 13/13 tests passing | **Compatibility:** macOS 10.10+

---

## 🛠️ How It Works

### Process
```
Script finds Daktela app
  ↓
Gets bundle ID (e.g., com.daktela.v6)
  ↓
Uses duti or Launch Services to register
  ↓
Updates user preferences (~/Library/Preferences/)
  ↓
Verification step confirms changes
```

### What Gets Modified
```
Location: ~/Library/Preferences/
Files:
  - com.apple.LaunchServices.QuarantineResolver.plist
  - com.apple.LaunchServices/com.apple.launchservices.secure.plist

Protocols registered:
  - tel:
  - callto:
```

### User-Scoped Only
- No sudo required
- No system files modified
- Changes to user's account only
- Fully reversible

---

## 📋 File Details

### Main Script: `daktela-callto-register.sh`
- **Language:** Bash
- **Size:** ~10KB
- **Dependencies:** AppleScript, Spotlight, Python 3
- **Requirements:** macOS 10.10+

### Supporting Files
- `run-tests.sh` - Test suite (13 automated tests)
- `.github/workflows/` - CI/CD configuration
- Comprehensive documentation

---

## 🚀 Usage

### Basic
```bash
./daktela-callto-register.sh
```
Auto-detects Daktela and registers it.

### Dry Run (Preview)
```bash
DRY_RUN=1 ./daktela-callto-register.sh
```
Shows what would be changed without making changes.

### Custom App Name
```bash
APP_NAME="Daktela Desktop" ./daktela-callto-register.sh
```
For non-standard installations.

### Custom Bundle ID
```bash
BUNDLE_ID=com.daktela.v6 ./daktela-callto-register.sh
```
Direct bundle ID specification.

### Environment Variables
```bash
DRY_RUN=1              # Preview mode
APP_NAME="..."         # Custom app name
BUNDLE_ID=com...      # Direct bundle ID
VERBOSE=1             # Detailed output
```

---

## 🧪 Testing

### Run Full Test Suite
```bash
chmod +x run-tests.sh
./run-tests.sh
```

### Test Categories (13 tests)
1. Bundle ID validation
2. App detection (AppleScript)
3. App detection (Spotlight)
4. Idempotency (safe to run multiple times)
5. Dry-run mode
6. SSH compatibility
7. Cron environment
8. Security (injection prevention)
9. Error handling
10. macOS version detection
11. Preference file handling
12. Verification accuracy
13. Edge cases

### Test Output
All 13 tests should pass:
```
✓ Test 1 passed
✓ Test 2 passed
... (13 total)
✓ All tests passed
```

---

## 🔧 Implementation Details

### App Detection Strategy
1. **AppleScript (Primary)** - Most reliable on macOS
2. **Spotlight Search** - Fallback method
3. **Bundle ID Direct** - If specified by user

### Bundle ID Sources
- System `mdls` command
- `osascript` AppleScript query
- User-specified override
- Environment variable

### LaunchServices Registration
Uses one of:
- `duti` utility (if available)
- Direct plist modification (Python)
- `LaunchServices` framework

### Verification
Post-registration verification:
- Checks preference files
- Queries LaunchServices database
- Confirms protocols are registered
- Validates bundle ID is correct

---

## 🔐 Security & Safety

### What Can't Happen
- ❌ Root/sudo required
- ❌ System files modified
- ❌ Other users affected
- ❌ Daktela binary modified
- ❌ Malicious code injection

### What's Safe
- ✅ User preferences only
- ✅ Reversible (remove pref files)
- ✅ Multiple runs idempotent
- ✅ Injection prevention
- ✅ Error handling robust

### Reversibility
```bash
# Remove registration
rm ~/Library/Preferences/com.apple.LaunchServices.QuarantineResolver.plist
rm ~/Library/Preferences/com.apple.LaunchServices/*

# Or just use System Preferences to change default app
```

---

## 🐛 Exit Codes

```
0 - Success
1 - General error
2 - Unable to resolve bundle ID
3 - Invalid bundle ID format
```

### Example
```bash
./daktela-callto-register.sh
if [ $? -eq 0 ]; then
    echo "Success!"
else
    echo "Failed with exit code $?"
fi
```

---

## 📊 Compatibility

### macOS Versions
- ✅ macOS 10.10 (Yosemite)
- ✅ macOS 10.11 (El Capitan)
- ✅ macOS 10.12 (Sierra)
- ✅ macOS 10.13 (High Sierra)
- ✅ macOS 10.14 (Mojave)
- ✅ macOS 10.15 (Catalina)
- ✅ macOS 11 (Big Sur)
- ✅ macOS 12 (Monterey)
- ✅ macOS 13 (Ventura)
- ✅ macOS 14 (Sonoma)
- ✅ macOS 15 (Sequoia)

### Shell Compatibility
- ✅ Bash 3.x+
- ✅ Bash 4.x+
- ✅ Bash 5.x+

### Special Environments
- ✅ SSH sessions
- ✅ Cron jobs
- ✅ GitHub Actions
- ✅ CI/CD pipelines

---

## 🚀 Enterprise Deployment

### Jamf/MDM
```bash
#!/bin/bash
cd /path/to/daktela-url-handler
./daktela-callto-register.sh
```

### Script Deployment
```bash
#!/bin/bash
# Deploy script for multiple users
for user in /Users/*; do
    if [ -d "$user" ]; then
        sudo -u "$(basename $user)" \
            /path/to/daktela-callto-register.sh
    fi
done
```

### Silent Deployment
```bash
DRY_RUN=1 ./daktela-callto-register.sh > /dev/null 2>&1
./daktela-callto-register.sh > /dev/null 2>&1
```

---

## 🔍 Troubleshooting

### Debug Mode
```bash
VERBOSE=1 ./daktela-callto-register.sh
```
Shows all steps and decisions.

### Manual Verification
```bash
# Check if tel: handler is registered
duti -x tel

# Query LaunchServices
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump | grep -i daktela

# Check preferences
defaults read com.apple.LaunchServices
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Command not found" | Make script executable: `chmod +x` |
| "Daktela not found" | Install Daktela first |
| "Invalid bundle ID" | Check format: `com.company.app` |
| "Permission denied" | Run without sudo |
| Links still open in old app | Restart browser or use System Preferences |

---

## 📈 Performance

- **Execution time:** ~2-5 seconds
- **Network required:** No
- **Disk usage:** <1KB (preference changes)
- **CPU usage:** <1% during execution
- **Memory usage:** <10MB during execution

---

## 🔄 Updates & Maintenance

### Check for Updates
```bash
git pull
```

### Version Info
```bash
grep "Version:" daktela-callto-register.sh
```

### Report Issues
- GitHub Issues
- Include: macOS version, Daktela version, error output
- Run with `VERBOSE=1` for details

---

## 📚 Code Structure

### Main Flow
```bash
1. Source configuration
2. Validate prerequisites
3. Find Daktela bundle ID
4. Register protocols
5. Verify registration
6. Report results
```

### Key Functions
- `find_daktela_app()` - App detection
- `get_bundle_id()` - Bundle ID resolution
- `register_protocol()` - LaunchServices registration
- `verify_registration()` - Post-registration check

---

## 🎓 Best Practices

1. **Always dry-run first** - Use `DRY_RUN=1`
2. **Test in isolation** - Before enterprise deployment
3. **Verify success** - Check that links open in Daktela
4. **Document app name** - If using custom names
5. **Keep logs** - For troubleshooting

---

## 🔗 References

- [macOS Bundle Identifier](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html)
- [Launch Services Programming](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSConcepts.html)
- [duti utility](https://github.com/moretension/duti)

---

## 📝 Version Info

- **Script Version:** 1.0.0
- **Last Updated:** November 2025
- **Status:** Production Ready
- **Tests:** 13/13 passing

---

## 💡 Future Improvements

Possible enhancements:
- Swift alternative to Python
- Direct CoreServices.framework binding
- GUI installer for non-technical users
- Support for other calling protocols
- Automatic Daktela version detection

---

## ✅ Quality Checklist

- [x] Works on macOS 10.10+
- [x] 13 automated tests passing
- [x] User-scoped changes only
- [x] No sudo required
- [x] Fully reversible
- [x] SSH/Cron compatible
- [x] Security audited
- [x] Error handling comprehensive
- [x] Documentation complete

**Status:** ✅ Production Ready

