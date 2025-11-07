# Installation Requirements

## ⚠️ PREREQUISITE: Daktela Must Be Installed

**Before running this script, the Daktela desktop application must be installed on your macOS system.**

---

## Why This Is Required

This script registers Daktela as the default handler for `tel:` and `callto:` URL schemes. macOS needs to know:

1. **What application** to launch when you click these links
2. **Where to find** the application on your system  
3. **The Bundle ID** (unique identifier) of the application

Without Daktela installed, there's nothing to register! 📱

---

## Installation Steps

### 1. Install Daktela

Download and install the Daktela desktop app from:
**https://www.daktela.com/**

Install it to one of these locations:
- `/Applications/Daktela.app` (recommended)
- `/Applications/Daktela Desktop.app`
- `~/Applications/Daktela.app` (user-specific)

### 2. Launch Daktela At Least Once

```bash
open -a "Daktela Desktop"
```

This registers the app with macOS Launch Services and Spotlight.

### 3. Run This Script

```bash
./daktela-callto-register-v2.sh
```

---

## What Happens If Daktela Is Not Installed?

The script will show helpful error messages:

### Scenario 1: Not Found in Common Paths

```
[!] ⚠️  WARNING: Daktela app not found in common locations.
[!] 
[!] This script requires Daktela to be installed.
[!] If it's already installed, you can specify the bundle ID explicitly:
[!]   BUNDLE_ID=com.daktela.v6 ./daktela-callto-register-v2.sh
[!] 
[*] Continuing to search via Spotlight...
```

**What this means:** The script couldn't find Daktela in `/Applications/` but will keep searching.

**What to do:** 
- If Daktela is installed elsewhere, wait (Spotlight will find it)
- If not installed, install Daktela first
- Or specify `BUNDLE_ID` explicitly if you know it

---

### Scenario 2: Completely Not Found

```
[!] Unable to resolve Daktela bundle ID.
[!] 
[!] ⚠️  PREREQUISITE: Daktela app must be installed on this system.
[!] 
[!] Solutions:
[!]   1. Install Daktela desktop app from https://www.daktela.com/
[!]   2. Launch the Daktela app at least once (registers with macOS)
[!]   3. If already installed, set BUNDLE_ID=com.your.bundle ./script.sh
[!]   4. Or set APP_NAME="Your App Name" ./script.sh
[!] 
[!] To find your bundle ID:
[!]   osascript -e 'id of app "Daktela"'
```

**What this means:** The script tried everything (AppleScript, Spotlight, direct search) but couldn't find Daktela.

**What to do:**
1. **Install Daktela** from https://www.daktela.com/
2. **Launch it at least once** so macOS knows it exists
3. **Run the script again**

---

## Workarounds (If Daktela Is Actually Installed)

If Daktela IS installed but the script can't find it, try:

### Option 1: Specify Bundle ID Explicitly

```bash
BUNDLE_ID=com.daktela.v6 ./daktela-callto-register-v2.sh
```

### Option 2: Specify App Name

```bash
APP_NAME="Daktela Desktop" ./daktela-callto-register-v2.sh
```

### Option 3: Find Your Bundle ID

```bash
# Method 1: AppleScript
osascript -e 'id of app "Daktela"'

# Method 2: Spotlight
mdfind 'kMDItemKind == "Application"' | grep -i daktela | head -1 | xargs mdls -name kMDItemCFBundleIdentifier

# Method 3: Direct check
defaults read /Applications/Daktela.app/Contents/Info.plist CFBundleIdentifier
```

---

## System Requirements

### Required
- ✅ **macOS 10.10+** (tested on 10.15+)
- ✅ **Daktela desktop app** installed
- ✅ **Python 3** (pre-installed on macOS 10.15+)

### Optional
- 🔧 **duti** - For cleaner Launch Services manipulation
  ```bash
  brew install duti
  ```

---

## Verification

After installation and running the script, verify it works:

### Test tel: scheme
```bash
open tel:123456789
```

### Test callto: scheme
```bash
open callto:user@example.com
```

Both should launch Daktela! 🎉

---

## Troubleshooting

### "Daktela app not found"

**Problem:** Script can't locate Daktela.

**Solutions:**
1. Install Daktela from https://www.daktela.com/
2. Ensure it's in `/Applications/` or `~/Applications/`
3. Launch the app at least once
4. Rebuild Spotlight index:
   ```bash
   sudo mdutil -E /
   ```

---

### "Launch the Daktela app at least once"

**Problem:** App is installed but not registered with macOS.

**Solution:** Simply open the app once:
```bash
open -a "Daktela Desktop"
```

Then close it and run the script again.

---

### Script finds wrong version

**Problem:** Multiple Daktela versions installed, script picks wrong one.

**Solution:** Specify the bundle ID explicitly:
```bash
# List all Daktela apps
mdfind 'kMDItemKind == "Application"' | grep -i daktela

# Pick the right one and get its bundle ID
mdls -name kMDItemCFBundleIdentifier /Applications/Daktela.app

# Use it explicitly
BUNDLE_ID=com.daktela.correct.version ./daktela-callto-register-v2.sh
```

---

## FAQ

### Q: Can I run this script before installing Daktela?
**A:** No, you must install Daktela first. The script needs to register an actual application.

### Q: Do I need admin/sudo privileges?
**A:** No! This script operates at user-scope only.

### Q: What if Spotlight is disabled?
**A:** Use the `BUNDLE_ID` environment variable to specify the bundle ID explicitly.

### Q: Can I uninstall Daktela after running this script?
**A:** The URL scheme registration will remain, but the links won't work since there's no app to launch. You should unregister first.

### Q: How do I unregister?
**A:** Point the schemes to a different app (like FaceTime for tel:):
```bash
duti -s com.apple.FaceTime tel all
duti -s com.apple.FaceTime callto all
```

---

## Summary

✅ **Install Daktela** from https://www.daktela.com/  
✅ **Launch it once** to register with macOS  
✅ **Run the script** to set URL handlers  
✅ **Test with** `open tel:123456789`  

That's it! 🎉

---

**For more help, see:**
- `README.md` - Project overview
- `QUICK_START.md` - Usage guide
- `TROUBLESHOOTING.md` - Common issues

