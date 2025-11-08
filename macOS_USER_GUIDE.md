# Daktela URL Handler for macOS - User Guide

**Simple instructions for end users**

---

## 🎯 What This Does

When you click phone links like `tel:123456789` or `callto:user@email.com`, they will open in Daktela instead of FaceTime.

---

## ⚡ Quick Start (2 Minutes)

### Prerequisites
1. **Install Daktela** from [daktela.com](https://www.daktela.com/)
2. **Launch it once** (so macOS registers it)

### Installation
```bash
# 1. Download and go to script folder
cd daktela-url-handler

# 2. Make script executable
chmod +x daktela-callto-register.sh

# 3. Run it
./daktela-callto-register.sh
```

**That's it!** ✅

### Test It Works
Click these links or run in terminal:
```bash
open tel:123456789
open callto:user@example.com
```

Both should open in Daktela now! 🎉

---

## 📋 Usage Options

### Basic (Auto-detect Daktela)
```bash
./daktela-callto-register.sh
```

### Preview Changes (No Changes Made)
```bash
DRY_RUN=1 ./daktela-callto-register.sh
```

### Custom App Name
```bash
APP_NAME="Daktela Desktop" ./daktela-callto-register.sh
```

### Custom Bundle ID
```bash
BUNDLE_ID=com.daktela.v6 ./daktela-callto-register.sh
```

---

## ❓ FAQ

**Q: Do I need admin?**
A: No! Changes are user-scoped only.

**Q: Is it safe?**
A: Yes! It just tells macOS to use Daktela for phone links. Completely reversible.

**Q: What if I get an error?**
A: Most likely Daktela isn't installed. Install it first, launch it once, then run the script again.

**Q: How do I undo it?**
A: Your IT admin can remove the preference. Just ask them.

**Q: Does it work with different Daktela names?**
A: Yes! Use `APP_NAME="Your App Name"` if your installation has a different name.

**Q: What's a bundle ID?**
A: A unique identifier for macOS apps. Usually you don't need to specify it.

---

## 🧪 Testing

### Test Page Links
- `tel:+1234567890` - International format
- `tel:123456789` - Simple format
- `callto:user@example.com` - Email format
- `callto:sip:user@sip.example.com` - SIP format

### How to Test
1. Open Terminal
2. Copy/paste a link command:
   ```bash
   open tel:123456789
   ```
3. Press Enter
4. Daktela should open

---

## ✅ What Should Happen

### After Installation ✅
```
Click tel: link → Daktela opens
Click callto: link → Daktela opens
```

### If Nothing Happens
1. Make sure Daktela is installed
2. Make sure you ran the script
3. Try restart macOS
4. Run the script again

---

## 🔧 Troubleshooting

### Error: "Permission Denied"
```bash
chmod +x daktela-callto-register.sh
./daktela-callto-register.sh
```

### Error: "Daktela not found"
1. Install Daktela from [daktela.com](https://www.daktela.com/)
2. Open Daktela at least once
3. Run the script again

### Error: "Invalid bundle ID format"
Make sure your bundle ID follows pattern: `com.company.app`

### Links still open in FaceTime
1. Run script again
2. Restart your browser
3. Check System Preferences → Default Apps (on newer macOS)

---

## 📁 What You Get

Files included:
- `daktela-callto-register.sh` - The registration script
- `README.md` - Full documentation

That's all you need!

---

## 🚀 You're Done!

After installation, all phone and callto links will open in Daktela automatically. No need to do anything else - it just works!

Enjoy using Daktela! 📞

