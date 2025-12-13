<div align="center">

# 🧰 Zed Toolbox

**Powerful singleplayer cheat menu for Project Zomboid**  
*Fast item spawning • Curated presets • Smooth UI experience*

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Project%20Zomboid-green.svg)
![Build](https://img.shields.io/badge/build-41+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)

---

</div>

## 📋 Table of Contents

- [🎯 Overview](#-overview)
- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [🕹️ Usage](#️-usage)
- [⭐ Favorites & Presets](#-favorites--presets)
- [🌎 Translation](#-translation)
- [🛠️ Configuration](#️-configuration)
- [📁 Project Structure](#-project-structure)
- [🙌 Credits](#-credits)

## 🎯 Overview

| **Platform** | **Mode** | **Hotkey** | **Version** |
|:---:|:---:|:---:|:---:|
| Project Zomboid (Build 41+) | Singleplayer Only | Insert | 1.0.0 |

> ⚠️ **Note**: Automatically disables in multiplayer mode

## ✨ Features

### 🎪 Smart Catalog System
- **Intelligent scanning**: Automatically scans all items registered by `ScriptManager`
- **Smart categorization**: Organized by type (Weapons, Ammo, Bags, Food, Medical, Miscellaneous)
- **Alphabetical sorting**: Easy navigation through large item lists

### 🔍 Advanced Search
- **Instant filtering**: Search by display name or `BaseID`
- **Real-time results**: Find items quickly with dynamic filtering
- **Multi-criteria support**: Flexible search patterns

### ⭐ Persistent Favorites
- **Save combinations**: Store item + quantity + destination settings
- **One-click access**: Recover favorite configurations instantly
- **Cross-session persistence**: Uses `ModData` for reliable storage

### 📦 Configurable Presets
- **Complete item lists**: Create full loadouts for automatic spawning
- **Quick setup**: Perfect for starter kits, loadouts, or rapid testing
- **Bulk operations**: Spawn entire preset collections at once

### 🎯 Flexible Spawner
- **Dual destinations**: Add directly to inventory or drop on ground
- **Quantity validation**: Safe range (1–100) prevents accidental crashes
- **Smart error handling**: Comprehensive validation and feedback

### 🎨 Polished Interface
- **Drag-and-drop panels**: Intuitive window management
- **Visual feedback**: Success/error indicators and highlighted selections
- **Responsive design**: Optimized for different screen sizes

### 🌍 Internationalization Ready
- **Multi-language support**: English (EN) and Brazilian Portuguese (PT-BR)
- **Easy extension**: Add new languages by creating translation files
- **Dynamic loading**: Automatic locale detection

### 🔧 Robust Logging
- **Exception tracking**: `ZedToolboxLogger` captures all errors
- **Timestamped logs**: Detailed error files in `logs/error-<context>-<timestamp>.txt`
- **Debug support**: Comprehensive logging for troubleshooting

## 📦 Installation

### Manual Installation

1. **Download & Extract**
   ```
   📁 Zomboid/mods/ZedToolBox/
   ├── mod.info
   └── media/lua/...
   ```

2. **Verify Structure**
   - Ensure `mod.info` is in the root directory
   - Maintain the complete `media/lua/...` structure

3. **Activate Mod**
   - Launch Project Zomboid
   - Navigate to **Mods** menu
   - Enable **Zed Toolbox** before loading your save

### Requirements

| Component | Requirement |
|:---:|:---:|
| **Game Version** | Project Zomboid Build 41+ |
| **Game Mode** | Singleplayer only |
| **Dependencies** | None |

## 🕹️ Usage

### Quick Start Guide

1. **Launch Game**
   - Start or continue a singleplayer save

2. **Open Menu**
   - Press **`Insert`** to toggle the cheat menu

3. **Navigate Items**
   - Browse categories on the left panel
   - Use search bar for instant filtering
   - Select desired item from the list

4. **Configure Spawn**
   - Set quantity (1-100)
   - Choose destination:
     - 📦 **Inventory**: Add directly to player inventory
     - 🌍 **Ground**: Drop at player's location

5. **Spawn Items**
   - Click **Spawn** button, or
   - Double-click item in the list for instant spawn

### 🔥 Pro Tips

> 💡 **Smart Loading**: Menu only loads when local player (index 0) is ready, preventing loading screen errors
> 
> ⚡ **Quick Access**: Double-click any item for instant spawn with current settings
> 
> 🎯 **Batch Operations**: Use presets to spawn multiple items at once

## ⭐ Favorites & Presets

### 💝 Managing Favorites

<details>
<summary><strong>➕ Adding Favorites</strong></summary>

1. Select an item from the catalog
2. Configure quantity and destination
3. Click **Add Favorite**
4. Your configuration is saved automatically

</details>

<details>
<summary><strong>🚀 Using Favorites</strong></summary>

1. Choose from favorites dropdown
2. Click **Spawn Favorite**
3. Item spawns with saved settings

</details>

### 📋 Working with Presets

<details>
<summary><strong>🔨 Creating Presets</strong></summary>

1. Enter a preset name
2. Add items to your list
3. Click **Save Preset**
4. Preset is stored permanently

</details>

<details>
<summary><strong>⚡ Using Presets</strong></summary>

- **Apply**: Fill form fields with preset data
- **Spawn All**: Instantly spawn all preset items

</details>

### 💾 Data Persistence

All favorites and presets are stored in `ModData["ZedToolbox"]`, ensuring:
- ✅ Cross-session persistence
- ✅ Multiple save compatibility
- ✅ No external file dependencies

## 🌎 Translation

### 🗣️ Supported Languages

| Language | Code | Status |
|:---:|:---:|:---:|
| English | `EN` | ✅ Complete |
| Brazilian Portuguese | `BP` | ✅ Complete |

### 🔧 Adding New Languages

1. **Create Language Directory**
   ```
   media/lua/shared/Translate/<LOCALE>/
   ```

2. **Copy Base File**
   ```bash
   cp ZedToolbox_EN.txt ZedToolbox_<LOCALE>.txt
   ```

3. **Translate Content**
   - Translate all text keys
   - Maintain key structure
   - Test in-game

4. **Update Folder Name**
   ```
   media/lua/shared/Translate/<LOCALE>/
   ```

### 📂 Translation Structure

```
media/lua/shared/Translate/
├── EN/
│   └── ZedToolbox_EN.txt
├── BrazilianPortuguese/
│   └── ZedToolbox_BP.txt
└── <YourLanguage>/
    └── ZedToolbox_<CODE>.txt
```

## 🛠️ Configuration

### ⌨️ Hotkey Customization

**Default**: `Insert` key

**To change**:
1. Edit `CheatMenuMain.Config.toggleKey` in [`CheatMenuMain.lua`](media/lua/client/CheatMenuMain.lua)
2. Use any `Keyboard.KEY_*` constant
3. Save and restart the game

```lua
-- Example: Change to F1
CheatMenuMain.Config.toggleKey = Keyboard.KEY_F1
```

### 🔄 Catalog Management

**Refresh catalog** after installing item mods:
```lua
-- In-game console
CheatMenuItems.refresh()
```

### 🐛 Debugging & Logs

| Log Type | Location | Purpose |
|:---:|:---:|:---:|
| **Error Logs** | `Zomboid/mods/ZedToolbox/logs/` | Exception tracking |
| **Format** | `error-<context>-<timestamp>.txt` | Detailed error info |
| **Usage** | Troubleshooting & support | Debug assistance |

**Log Features**:
- 🕒 Timestamped entries
- 📍 Context-aware logging
- 🛡️ Safe call wrappers
- 📝 Detailed stack traces

## 📁 Project Structure

```
ZedToolBox/
├── 📄 mod.info                          # Mod metadata
├── 📖 README.md                         # Documentation
└── 📁 media/
    └── 📁 lua/
        ├── 📁 client/                   # Client-side scripts
        │   ├── 🎮 CheatMenuMain.lua     # Toggle & key bindings
        │   ├── 🖥️ CheatMenuUI.lua       # Complete UI panel
        │   └── 🚀 CheatMenuSpawner.lua  # Spawn logic & validation
        └── 📁 shared/                   # Shared utilities
            ├── 📦 CheatMenuItems.lua    # Item catalog & categorization
            ├── 📝 CheatMenuLogger.lua   # Resilient log wrapper
            ├── 🔍 ZedToolboxLogger.lua  # File logging system
            ├── 🌐 CheatMenuText.lua     # Translation helper
            └── 📁 Translate/            # Language files
                ├── 📁 BrazilianPortuguese/
                │   └── 🇧🇷 ZedToolbox_BP.txt
                └── 📁 EN/
                    └── 🇺🇸 ZedToolbox_EN.txt
```

### 🧩 Core Components

| Component | Responsibility |
|:---:|:---:|
| **CheatMenuMain** | Hotkey handling & menu toggle |
| **CheatMenuUI** | Complete interface rendering |
| **CheatMenuSpawner** | Item spawning & validation |
| **CheatMenuItems** | Catalog management & categorization |
| **Logger System** | Error tracking & file output |
| **Translation** | Multi-language support |

## 🙌 Credits

<div align="center">

**Created with ❤️ by CodeMaster (Robson)**

*Special thanks to the Project Zomboid BR community for valuable feedback*

---

### 📞 Support & Contributions

| Type | Link |
|:---:|:---:|
| 🐛 **Issues** | [Report Problems](https://github.com/yourusername/ZedToolbox/issues) |
| 💡 **Features** | [Request Features](https://github.com/yourusername/ZedToolbox/issues) |
| 🔀 **Pull Requests** | [Contribute Code](https://github.com/yourusername/ZedToolbox/pulls) |
| 🌍 **Translations** | [Add Languages](https://github.com/yourusername/ZedToolbox/pulls) |

### 🎮 Happy zombie slaying in Knox County!

</div>

---

<div align="center">

**If you find this mod helpful, consider ⭐ starring the repository!**

*Made for the Project Zomboid community • Free & Open Source*

</div>
