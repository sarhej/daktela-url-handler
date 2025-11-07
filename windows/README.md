# Daktela URL Handler for Windows

> Automatically register [Daktela](https://www.daktela.com/) as the default handler for `tel:` and `callto:` URL schemes on Windows.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%2B-blue.svg)](https://www.microsoft.com/windows/)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/)

---

## 🎯 What This Does

When you click phone links like `tel:123456789` or `callto:user@example.com` anywhere in Windows (email, browser, documents), they'll automatically open in Daktela.

**Before:** Phone links don't open or open in wrong app 📱  
**After:** Phone links open in Daktela 🎉

---

## ⚡ Quick Start

### Prerequisites

1. **Windows 10 or later**
2. **Daktela installed** from [daktela.com](https://www.daktela.com/)
3. **PowerShell 5.1+** (built into Windows)
4. **Administrator privileges**

### Installation

```powershell
# 1. Download the script
# (Or clone the repository)

# 2. Open PowerShell as Administrator
# Right-click PowerShell → "Run as Administrator"

# 3. Allow script execution (one-time setup)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 4. Navigate to script directory
cd path\to\script

# 5. Run the script
.\Register-DaktelaURLHandler.ps1
```

### Verify It Works

Click these links in any application:
- `tel:123456789`
- `callto:user@example.com`

Both should now open in Daktela! 🎉

---

## 📖 Usage

### Basic Usage (Auto-detect)

```powershell
.\Register-DaktelaURLHandler.ps1
```

The script will automatically find Daktela and register it.

### Specify Daktela Path

If auto-detection fails or you have a custom installation:

```powershell
.\Register-DaktelaURLHandler.ps1 -DaktelaPath "C:\Program Files\Daktela\Daktela.exe"
```

### Dry Run (Preview Changes)

See what would change without making actual changes:

```powershell
.\Register-DaktelaURLHandler.ps1 -DryRun
```

### Get Help

```powershell
Get-Help .\Register-DaktelaURLHandler.ps1 -Full
```

---

## 🔧 How It Works

The script modifies the Windows Registry to register Daktela as the default handler for telephone URL schemes. It:

1. **Searches** for Daktela in common installation locations
2. **Validates** that Daktela.exe exists
3. **Registers** URL schemes in `HKCU:\Software\Classes`
4. **Verifies** the registration was successful

**User-scope only!** Changes are made in `HKEY_CURRENT_USER`, not system-wide.

---

## ✨ Features

- ✅ **Automatic detection** - Finds Daktela without manual configuration
- ✅ **Safe** - User-scope only, no system-wide changes
- ✅ **Verifiable** - Shows current and new handlers
- ✅ **Dry-run mode** - Preview changes before applying
- ✅ **Well-documented** - Extensive inline documentation
- ✅ **Error handling** - Clear error messages with solutions

---

## 🔍 Search Locations

The script searches these locations in order:

1. `C:\Program Files\Daktela\Daktela.exe`
2. `C:\Program Files (x86)\Daktela\Daktela.exe`
3. `%LOCALAPPDATA%\Programs\Daktela\Daktela.exe`
4. `C:\Program Files\Daktela Desktop\Daktela.exe`
5. Recursive search in Program Files
6. Recursive search in `%LOCALAPPDATA%\Programs`

---

## ❓ Troubleshooting

### "This script requires Administrator privileges"

**Solution:** Run PowerShell as Administrator

1. Press `Win + X`
2. Select "Windows PowerShell (Admin)" or "Terminal (Admin)"
3. Navigate to script directory
4. Run script again

### "Running scripts is disabled on this system"

**Solution:** Enable script execution

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then run the script again.

### "Unable to find Daktela installation"

**Solutions:**

1. **Install Daktela** from https://www.daktela.com/
2. **Specify path explicitly:**
   ```powershell
   .\Register-DaktelaURLHandler.ps1 -DaktelaPath "C:\Your\Path\Daktela.exe"
   ```
3. **Find Daktela manually:**
   ```powershell
   Get-ChildItem "C:\Program Files" -Filter "Daktela.exe" -Recurse -ErrorAction SilentlyContinue
   ```

### Changes Don't Take Effect

**Solution:** Restart your browser or applications, or:

```powershell
# Refresh Windows shell associations
ie4uinit.exe -show
```

### Revert to Default

To unregister Daktela, delete the registry keys:

```powershell
Remove-Item -Path "HKCU:\Software\Classes\tel" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\callto" -Recurse -Force
```

Or register a different application.

---

## 🔒 Security & Privacy

- **User-scope only** - No system-wide changes
- **No network calls** - Everything runs locally
- **No data collection** - Script doesn't send any data
- **Open source** - Full transparency, audit the code
- **Registry backup recommended** - Create restore point first

**Note:** Requires Administrator privileges to write to registry, but changes are user-scoped.

---

## 📋 Requirements

- **Windows 10+** (tested on Windows 10 & 11)
- **PowerShell 5.1+** (built-in)
- **Daktela** installed and accessible
- **Administrator privileges** (for registry changes)

To check your PowerShell version:
```powershell
$PSVersionTable.PSVersion
```

---

## 🧪 Testing

### Manual Testing

```powershell
# 1. Run in dry-run mode
.\Register-DaktelaURLHandler.ps1 -DryRun

# 2. Check current handlers
Get-ItemProperty -Path "HKCU:\Software\Classes\tel\shell\open\command"
Get-ItemProperty -Path "HKCU:\Software\Classes\callto\shell\open\command"

# 3. Test the URL schemes
Start-Process "tel:123456789"
Start-Process "callto:user@example.com"
```

### Automated Testing

For automated testing on Windows:

```powershell
# Test script syntax
Test-ScriptFileInfo -Path .\Register-DaktelaURLHandler.ps1

# PSScriptAnalyzer (install first)
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
Invoke-ScriptAnalyzer -Path .\Register-DaktelaURLHandler.ps1
```

---

## 🤝 Contributing

Contributions welcome! Since this is a Windows-specific script:

1. Test on **Windows 10** and **Windows 11**
2. Verify with different PowerShell versions
3. Test with various Daktela installation paths
4. Ensure error messages are helpful

See [CONTRIBUTING.md](../CONTRIBUTING.md) for general guidelines.

---

## 📝 License

MIT License - see [LICENSE](../LICENSE) file for details.

---

## 🆘 Support

Having issues?

1. **Run in dry-run mode** to see what would happen: `.\Register-DaktelaURLHandler.ps1 -DryRun`
2. **Check PowerShell version**: `$PSVersionTable.PSVersion` (need 5.1+)
3. **Verify admin privileges**: Script will fail if not running as Administrator
4. **Check Daktela installation**: Make sure Daktela.exe exists
5. **Open an issue** on GitHub with error message and `$PSVersionTable` output

---

## 🔗 Related

- [macOS version](../README.md) - For macOS users
- [Daktela](https://www.daktela.com/) - Official Daktela website

---

**Made with ❤️ for Windows productivity** | [Report Bug](../../issues) | [Request Feature](../../issues)

