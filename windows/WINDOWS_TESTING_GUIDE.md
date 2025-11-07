# Windows Testing Guide for macOS Developers

> How to test the Windows version of Daktela URL Handler when you only have a Mac

---

## 🎯 Goal

Test the PowerShell script on Windows without owning a Windows computer.

---

## 🆓 Option 1: Free Windows VM (RECOMMENDED)

### Download Free Windows VM from Microsoft

Microsoft provides **free Windows VMs** for developers:

1. **Go to:** https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/
2. **Download:** Windows 11 development environment
3. **Choose:** VirtualBox (free)
4. **Valid for:** 90 days (can be reset/extended)

**File size:** ~20GB (plan accordingly)

### Setup on macOS

```bash
# 1. Install VirtualBox (free)
brew install --cask virtualbox

# 2. Download Windows VM from Microsoft (link above)
# File will be: WinDev2xxxEval.VirtualBox.zip

# 3. Unzip and import
unzip WinDev*.zip
# Double-click the .ova file to import into VirtualBox

# 4. Start the VM
# Click "Start" in VirtualBox
# Default password: Passw0rd!
```

### Transfer Your Script to VM

**Option A: Shared Folder**
```bash
# In VirtualBox:
# Settings → Shared Folders → Add
# Folder Path: /Users/supersergio/projects/daktela/windows
# Mount in Windows as: \\VBOXSVR\daktela
```

**Option B: Git**
```bash
# In Windows VM:
# Install Git: https://git-scm.com/download/win
# Clone: git clone https://github.com/YOUR_USERNAME/daktela-url-handler.git
```

**Option C: Copy-Paste**
```
# Enable bidirectional clipboard in VirtualBox:
# Devices → Shared Clipboard → Bidirectional
# Then just copy-paste the script content
```

### Test the Script

In Windows VM:

```powershell
# 1. Open PowerShell as Administrator
# Win + X → "Windows PowerShell (Admin)"

# 2. Allow scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Navigate to script
cd C:\Users\User\daktela-url-handler\windows

# 4. Test dry-run first
.\Register-DaktelaURLHandler.ps1 -DryRun

# 5. Test actual registration (after installing Daktela)
.\Register-DaktelaURLHandler.ps1
```

---

## ☁️ Option 2: GitHub Codespaces (Cloud-based)

GitHub Codespaces allows Windows containers:

### Setup

```yaml
# Create .devcontainer/devcontainer.json in your repo
{
  "name": "Windows Testing",
  "image": "mcr.microsoft.com/windows/servercore:ltsc2022",
  "features": {
    "ghcr.io/devcontainers/features/powershell:1": {}
  }
}
```

### Limitations
- ⚠️ No GUI (testing URL schemes requires GUI)
- ✅ Good for syntax checking
- ✅ Good for PSScriptAnalyzer
- ❌ Can't test actual URL scheme registration

**Verdict:** Good for linting, not for full testing.

---

## 🍷 Option 3: Wine (Very Limited)

Wine can run some Windows apps on macOS:

```bash
# Install Wine
brew install --cask wine-stable

# Test PowerShell syntax (very limited)
wine pwsh.exe -File Register-DaktelaURLHandler.ps1 -DryRun
```

### Limitations
- ⚠️ Registry emulation incomplete
- ⚠️ PowerShell may not work properly
- ❌ Not reliable for testing
- ✅ Only for basic syntax checking

**Verdict:** Not recommended. Use VM instead.

---

## 🧑‍💻 Option 4: Ask Community to Test

If you can't set up Windows:

### Strategy

1. **Create detailed testing instructions**
2. **Open a GitHub issue**: "Windows Testing Needed"
3. **Provide test checklist**
4. **Ask community to report results**

### Example GitHub Issue

```markdown
### Windows Testing Needed

I've created a PowerShell script to register Daktela as URL handler on Windows.
**I don't have access to Windows** to test it myself.

Can someone with Windows help test?

**Requirements:**
- Windows 10 or 11
- Daktela installed
- Administrator privileges

**Test Steps:**
1. Download: [Register-DaktelaURLHandler.ps1](link)
2. Run in PowerShell (as Admin): `.\Register-DaktelaURLHandler.ps1 -DryRun`
3. Report output
4. If dry-run looks good, run: `.\Register-DaktelaURLHandler.ps1`
5. Test: Click `tel:123456789` in browser

**Expected:**
- Script finds Daktela automatically
- Registers tel: and callto: schemes
- Clicking phone links opens Daktela

Please share:
- ✅/❌ Did it work?
- PowerShell version: `$PSVersionTable.PSVersion`
- Any errors
- Screenshot if possible

Thank you! 🙏
```

**Verdict:** Viable but slower. Good backup plan.

---

## 🎓 Option 5: Azure/AWS Free Tier

Both offer free Windows VMs:

### Azure

```bash
# Azure Free Tier includes:
# - Windows VM for 12 months
# - 750 hours/month

# Setup:
1. Sign up: https://azure.microsoft.com/free/
2. Create Windows VM (B1s size = free tier)
3. RDP from macOS:
   brew install --cask microsoft-remote-desktop
4. Connect and test
```

### AWS EC2

```bash
# AWS Free Tier includes:
# - t2.micro Windows (750 hours/month for 12 months)

# Setup:
1. Sign up: https://aws.amazon.com/free/
2. Launch Windows EC2 instance
3. Download RDP file
4. Connect with Microsoft Remote Desktop
```

### Pros & Cons

**Pros:**
- ✅ Real Windows environment
- ✅ Accessible from anywhere
- ✅ Free tier available

**Cons:**
- ⚠️ Requires credit card
- ⚠️ Can incur charges if misconfigured
- ⚠️ Network latency
- ⚠️ Setup complexity

**Verdict:** Good if you're comfortable with cloud services.

---

## 📋 Testing Checklist

Once you have Windows access, test:

### Pre-Installation Tests

```powershell
# 1. Syntax check
Test-ScriptFileInfo -Path .\Register-DaktelaURLHandler.ps1

# 2. Static analysis
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Invoke-ScriptAnalyzer -Path .\Register-DaktelaURLHandler.ps1

# 3. Help documentation
Get-Help .\Register-DaktelaURLHandler.ps1
```

### Installation Tests

```powershell
# 1. Test without Daktela (should fail gracefully)
.\Register-DaktelaURLHandler.ps1 -DryRun

# 2. Install Daktela
# Download from: https://www.daktela.com/

# 3. Test auto-detection
.\Register-DaktelaURLHandler.ps1 -DryRun

# 4. Test actual registration
.\Register-DaktelaURLHandler.ps1

# 5. Verify registration
Get-ItemProperty -Path "HKCU:\Software\Classes\tel\shell\open\command"
Get-ItemProperty -Path "HKCU:\Software\Classes\callto\shell\open\command"
```

### Functional Tests

```powershell
# 1. Test tel: URL
Start-Process "tel:+1234567890"

# 2. Test callto: URL
Start-Process "callto:user@example.com"

# 3. Test in browser
# Click links in email or browser
```

### Edge Cases

```powershell
# 1. Custom installation path
.\Register-DaktelaURLHandler.ps1 -DaktelaPath "C:\Custom\Path\Daktela.exe"

# 2. Non-admin user (should fail with clear message)
# Test in non-elevated PowerShell

# 3. Already registered (should update)
.\Register-DaktelaURLHandler.ps1
.\Register-DaktelaURLHandler.ps1  # Run twice

# 4. Invalid path
.\Register-DaktelaURLHandler.ps1 -DaktelaPath "C:\DoesNotExist\Daktela.exe"
```

---

## 🚀 Recommended Testing Workflow

### Phase 1: Syntax & Linting (No Windows Needed)

```bash
# On macOS, validate PowerShell syntax online:
# https://www.poshcode.org/

# Or use VS Code with PowerShell extension:
code --install-extension ms-vscode.PowerShell
```

### Phase 2: VM Testing (1-2 hours)

```bash
# Day 1: Setup
1. Download VirtualBox (30 min)
2. Download Windows VM (1-2 hours depending on connection)
3. Import and start VM (15 min)

# Day 2: Testing
1. Install Daktela in VM (15 min)
2. Copy script to VM (5 min)
3. Run tests (30 min)
4. Document findings (30 min)
```

### Phase 3: Community Testing (Optional)

```bash
# After VM testing passes:
1. Publish to GitHub
2. Open "Testing Needed" issue
3. Get community feedback
4. Iterate based on feedback
```

---

## 💡 Pro Tips

### For VirtualBox Users

```bash
# 1. Take snapshots before testing
# Machine → Take Snapshot
# Name: "Before Daktela install"

# 2. If something breaks, restore
# Machine → Restore Snapshot

# 3. Install VirtualBox Guest Additions
# Devices → Insert Guest Additions CD
# Better performance & shared clipboard

# 4. Allocate enough resources
# Settings → System:
# - RAM: 4GB minimum
# - CPU: 2 cores
```

### For Faster Development

```bash
# 1. Use VS Code Remote
# Install: Remote - SSH extension
# Connect to Windows VM
# Edit files directly

# 2. Use PowerShell ISE in Windows
# Better debugging
# Built into Windows

# 3. Enable bidirectional clipboard
# Faster copy-paste between Mac and VM
```

---

## 🎯 Quick Decision Guide

**Choose VirtualBox VM if:**
- ✅ You want full control
- ✅ You can download 20GB
- ✅ You need comprehensive testing
- ✅ You'll test multiple times

**Choose Cloud VM if:**
- ✅ You're comfortable with cloud
- ✅ You have credits/free tier
- ✅ You need remote access
- ✅ You want lighter setup

**Choose Community Testing if:**
- ✅ You can't setup Windows
- ✅ You trust the community
- ✅ You're not in a hurry
- ✅ You want diverse test coverage

**Our Recommendation:** Start with **VirtualBox VM** (free, local, full control)

---

## 📊 Comparison Table

| Option | Cost | Setup Time | Test Quality | Reusability |
|--------|------|------------|--------------|-------------|
| **VirtualBox VM** | Free | 2-3 hours | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Azure/AWS** | Free tier | 1-2 hours | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **GitHub Codespaces** | Free tier | 30 min | ⭐⭐ | ⭐⭐⭐ |
| **Wine** | Free | 15 min | ⭐ | ⭐ |
| **Community** | Free | Varies | ⭐⭐⭐⭐ | ⭐⭐ |

---

## ✅ Next Steps

1. **Choose your testing method** (we recommend VirtualBox)
2. **Follow the setup instructions** above
3. **Run the test checklist**
4. **Document your findings**
5. **Iterate and improve**

---

## 🆘 Need Help?

- **VirtualBox issues:** https://www.virtualbox.org/wiki/Documentation
- **PowerShell help:** https://docs.microsoft.com/powershell/
- **Windows VM help:** https://developer.microsoft.com/windows/downloads/

---

**Good luck with Windows testing!** 🚀

You've got this! The VirtualBox method is straightforward and gives you a real Windows environment for testing.

