# Installation Guide 📦

This guide will help you install and set up Clipo on your macOS system.

## 📋 System Requirements

- **macOS 14.0** (Sonoma) or later
- **Apple Silicon** (M1/M2/M3) or Intel Mac
- **50 MB** of available disk space

## 🚀 Installation Methods

### Method 1: Direct Download (Recommended)

1. **Download** the latest version from [GitHub Releases](https://github.com/Velyzo/Clipo/releases)
2. **Locate** the downloaded `.app` file in your Downloads folder
3. **Move** Clipo.app to your `/Applications` folder
4. **Right-click** on Clipo.app and select "Open"
5. **Click "Open"** in the security dialog that appears

> **Note**: You may see a security warning since the app is not from the App Store. This is normal for direct downloads.

### Method 2: App Store (Coming Soon)

Clipo will be available on the Mac App Store soon! Stay tuned for updates.

## ⚙️ Initial Setup

### 1. Launch Clipo
- Open Clipo from your Applications folder
- The app will appear in your menu bar (look for the clipboard icon)

### 2. Grant Permissions
Clipo needs certain permissions to function properly:

#### Accessibility Access
1. Go to **System Preferences** > **Security & Privacy** > **Privacy**
2. Select **Accessibility** from the left sidebar
3. Click the **lock icon** and enter your password
4. Check the box next to **Clipo**

#### Screen Recording (if prompted)
1. Go to **System Preferences** > **Security & Privacy** > **Privacy**
2. Select **Screen Recording** from the left sidebar
3. Check the box next to **Clipo**

### 3. Configure Preferences
- Click the Clipo icon in your menu bar
- Select **Preferences** to customize:
  - Keyboard shortcuts
  - Maximum history items
  - Startup behavior
  - Menu bar appearance

## 🔧 Troubleshooting

### App Won't Open
If you see "Clipo can't be opened because it's from an unidentified developer":

1. **Control-click** the app icon
2. Select **Open** from the shortcut menu
3. Click **Open** in the dialog

### Menu Bar Icon Missing
1. **Quit** Clipo completely
2. **Relaunch** from Applications folder
3. Check **System Preferences** > **Users & Groups** > **Login Items**

### Clipboard Not Working
1. Ensure **Accessibility** permissions are granted
2. **Restart** Clipo
3. Try copying some text to test

### Performance Issues
1. **Reduce** clipboard history limit in Preferences
2. **Restart** your Mac if issues persist
3. **Reinstall** Clipo if problems continue

## 🗑️ Uninstallation

To completely remove Clipo:

1. **Quit** Clipo from the menu bar
2. **Delete** Clipo.app from Applications folder
3. **Remove** preferences (optional):
   ```bash
   rm -rf ~/Library/Preferences/com.velyzo.Clipo.plist
   rm -rf ~/Library/Application\ Support/Clipo
   ```

## 🔄 Updating

### Manual Updates
1. **Download** the latest version from GitHub Releases
2. **Quit** the current version of Clipo
3. **Replace** the old app with the new one in Applications
4. **Launch** the updated version

### Automatic Updates (Coming Soon)
Future versions will include automatic update checking and installation.

## 🛡️ Security & Privacy

Clipo takes your privacy seriously:

- **All clipboard data** stays on your Mac
- **No data** is sent to external servers
- **No tracking** or analytics
- **Local storage** only

## 💡 Tips & Tricks

### Keyboard Shortcuts
- **⌘ + Shift + V**: Open clipboard history
- **⌘ + Shift + C**: Show favorites
- **Escape**: Close clipboard window

### Pro Tips
- **Pin frequently used items** to Favorites
- **Edit clipboard items** before pasting
- **Use search** to find specific clipboard entries
- **Organize with categories** for better workflow

## 🆘 Getting Help

If you encounter any issues:

1. **Check** this installation guide
2. **Visit** our [Issues page](https://github.com/Velyzo/Clipo/issues)
3. **Search** existing issues before creating a new one
4. **Contact** support at support@clipo.app

## 🔗 Useful Links

- **GitHub Repository**: https://github.com/Velyzo/Clipo
- **Latest Releases**: https://github.com/Velyzo/Clipo/releases
- **Bug Reports**: https://github.com/Velyzo/Clipo/issues/new?template=bug_report.md
- **Feature Requests**: https://github.com/Velyzo/Clipo/issues/new?template=feature_request.md

---

**Happy clipping!** 🎉

If you find Clipo useful, please consider ⭐ starring the repository on GitHub!
