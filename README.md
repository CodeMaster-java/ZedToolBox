<div align="center">

# 🧰 Zed Toolbox

**The Ultimate Singleplayer Cheat Menu for Project Zomboid**
*Fast item spawning • Smart categorization • Intuitive interface • Multi-language support*

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/CodeMaster-java/ZedToolbox/releases)
[![Platform](https://img.shields.io/badge/platform-Project%20Zomboid-green.svg)](https://store.steampowered.com/app/108600/Project_Zomboid/)
[![Build](https://img.shields.io/badge/build-41+-orange.svg)](https://projectzomboid.com/blog/)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE.md)
[![Language](https://img.shields.io/badge/language-Lua-blue.svg)](https://lua.org/)
[![Downloads](https://img.shields.io/badge/downloads-10k+-brightgreen.svg)](#)

---

**📸 Screenshots** • **🎬 Demo Video** • **📖 Documentation** • **[🏪 Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3623287081)**

</div>

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [🎯 Overview](#-overview)
- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [🕹️ Usage Guide](#️-usage-guide)
- [⭐ Favorites & Presets](#-favorites--presets)
- [🛠️ Configuration](#️-configuration)
- [🌍 Localization](#-localization)
- [📁 Project Structure](#-project-structure)
- [🤝 Contributing](#-contributing)
- [🙌 Credits](#-credits)
- [🧠 Advanced / Developers](#-advanced--developers)

## 🚀 Quick Start

**New to Zed Toolbox? Get started in 3 minutes:**

1. **� Subscribe**: [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3623287081) or manual install
2. **🎮 Enable**: Activate in Mods menu
3. **⌨️ Play**: Press `Insert` in-game to open menu

> 💡 **Pro Tip**: Double-click any item for instant spawning!

---

## 🎯 Overview

**Zed Toolbox** is a comprehensive cheat menu designed specifically for Project Zomboid singleplayer sessions. Built with performance and user experience in mind, it provides instant access to all game items while maintaining a clean, intuitive interface.

### 🎮 At a Glance

| **Feature** | **Details** |
|:---|:---|
| **🎯 Target Audience** | Sandbox players, modders, content creators |
| **🕹️ Game Mode** | Singleplayer only (auto-disables in multiplayer) |
| **⌨️ Default Hotkey** | `Insert` (fully customizable) |
| **🌐 Languages** | 6+ languages with easy expansion |
| **📦 Game Version** | Project Zomboid Build 41+ |
| **🔧 Dependencies** | None - plug & play |

### 🎯 Perfect For

- **🏗️ Base builders** needing quick material access
- **🧪 Mod developers** testing new content
- **📹 Content creators** setting up scenarios
- **🎮 Casual players** enjoying sandbox mode
- **🔍 Bug testers** reproducing issues

> ⚠️ **Multiplayer Protection**: Automatically detects and disables in multiplayer environments to maintain fair play.

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

### 🛡️ Survival Utilities
- **God Mode toggle**: Keep health, stats, and injuries fully topped up
- **Hit Kill option**: Drop any zombie or NPC with a single strike
- **Speed multiplier**: Dial in sprint and movement speed on the fly
- **Persistent settings**: Utilities remember their state between sessions

### 🏅 Skill Mastery
- **Instant leveling**: Raise or lower any perk to a target rank in one click
- **Bulk actions**: Max or reset every skill simultaneously for rapid testing
- **Safe XP sync**: Ensures perk boosts and XP stay aligned with the new level
- **Live feedback**: Status bar confirms successful updates or highlights issues

### 🎨 Polished Interface
- **Drag-and-drop panels**: Intuitive window management
- **Visual feedback**: Success/error indicators and highlighted selections
- **Responsive design**: Optimized for different screen sizes
- **Compact tab selector**: Dropdown tabs scale gracefully as features grow

### ⚙️ Config Hub
- **Hotkey picker**: Change the toggle key without leaving the game
- **Live language switch**: Reloads translations instantly
- **Persistent settings**: Configuration stored per save slot

### 🌍 Internationalization Ready
- **Multi-language support**: English, Portuguese (Brazil), Spanish, German, French, Russian
- **In-game language switcher**: Select your language in the Config tab
- **Easy extension**: Drop additional translation files under `media/lua/shared/Translate`

### 🔧 Robust Logging
- **Exception tracking**: `ZedToolboxLogger` captures all errors
- **Timestamped logs**: Detailed error files in `logs/error-<context>-<timestamp>.txt`
- **Debug support**: Comprehensive logging for troubleshooting

## 📦 Installation

### 🛠️ Automatic Installation (Recommended)

1. **Steam Workshop** 
   - Visit: [Zed Toolbox on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3623287081)
   - Click **Subscribe**
   - Launch Project Zomboid
   - Enable **Zed Toolbox** in Mods menu

### 📥 Manual Installation

1. **Download & Extract**
   - Download latest release from [GitHub Releases](https://github.com/CodeMaster-java/ZedToolbox/releases)
   - Extract to: `<ProjectZomboid>/mods/ZedToolBox/`
   
   ```
   📁 Zomboid/mods/ZedToolBox/
   ├── 📄 mod.info
   ├── 📖 README.md
   └── 📁 media/lua/...
   ```

2. **Verify Installation**
   - ✅ `mod.info` in root directory
   - ✅ Complete `media/lua/` structure
   - ✅ All translation files present

3. **Enable Mod**
   - Launch Project Zomboid
   - Navigate to **Mods** menu
   - ☑️ Enable **Zed Toolbox**
   - Start/continue your save

### 🔧 System Requirements

| **Requirement** | **Specification** |
|:---|:---|
| **Game** | Project Zomboid Build 41.78.16+ |
| **Mode** | Singleplayer only |
| **Platform** | Windows, Linux, macOS |
| **RAM** | Additional ~5MB |
| **Storage** | ~2MB mod files |
| **Dependencies** | None |

### ❗ Troubleshooting

<details>
<summary><strong>🚨 Common Issues</strong></summary>

- **Mod not appearing**: Verify folder structure matches exactly
- **Menu won't open**: Check for conflicting mods using `Insert` key
- **Missing translations**: Ensure all language files are extracted
- **Performance issues**: Close menu when not in use

</details>

## 🕹️ Usage Guide

### 🎮 Basic Operation

1. **🚀 Launch**: Start or continue a singleplayer save
2. **⌨️ Open Menu**: Press **`Insert`** (or your custom hotkey)
3. **🔍 Find Items**: Browse categories or use the search bar
4. **⚙️ Configure**: Set quantity (1-100) and destination
5. **➕ Add Items**: Click **Add** or double-click for instant spawning

### 📦 Spawn Destinations

| **Destination** | **Description** | **Use Case** |
|:---|:---|:---|
| **🎒 Inventory** | Adds directly to player inventory | Quick personal access |
| **🌍 Ground** | Drops at current location | Building, organizing, sharing |

### ⚡ Pro Tips & Shortcuts

<div align="left">

> 🔥 **Double-Click Magic**: Double-click any item for instant spawning with current settings
> 
> 🎯 **Smart Search**: Search by display name OR internal BaseID for precise results  
> 
> ⭐ **Batch Operations**: Use presets to spawn entire loadouts instantly
>
> 🔄 **Quick Refresh**: Added a new item mod? Use catalog refresh in Config
>
> 💡 **Hotkey Freedom**: Change the toggle key anytime in Config tab

</div>

### 🎪 Category System

Items are automatically organized into intuitive categories:

- **⚔️ Weapons**: Melee, firearms, ammunition
- **🎒 Bags**: Backpacks, containers, storage
- **🍖 Food**: Consumables, ingredients, drinks  
- **🏥 Medical**: Medicine, bandages, health items
- **🔧 Tools**: Building materials, crafting components
- **📦 Miscellaneous**: Everything else

### 🔍 Advanced Search Features

- **Real-time filtering**: Results update as you type
- **BaseID support**: Search internal item IDs for mod compatibility
- **Case-insensitive**: Works regardless of capitalization
- **Partial matching**: Find items with incomplete names

### 🏅 Skill Management

1. Switch to the **Skills** tab inside Zed Toolbox
2. Pick a perk from the dropdown and choose your desired level (0-10)
3. Use **Apply Level**, **Increase**, or **Decrease** for granular control
4. Hit **Max Selected**/**Reset Selected** for quick adjustments, or **Max All**/**Reset All** to modify every skill at once
5. Watch the status message for confirmation; the tab automatically refreshes to show the current level

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

## 🛠️ Configuration

### ⌨️ Customizing Hotkeys

<div align="left">

**Default**: `Insert`

**To Change**:
1. Open Zed Toolbox menu
2. Navigate to **Config** tab
3. Click **Pick Key** button
4. Press your desired key
5. Click **Set Key** to save

**Supported Keys**: Any single key (letters, numbers, function keys, etc.)

</div>

### 🌐 Language Settings

**Available Languages**: English, Portuguese (Brazil), Spanish, German, French, Russian

**To Switch Language**:
1. Go to **Config** tab
2. Select language from dropdown
3. Click **Apply** for instant change
4. All interface text updates immediately

### 🔄 Advanced Settings

<details>
<summary><strong>⚙️ Catalog Management</strong></summary>

**Refresh Item Catalog** after installing new mods:
```lua
-- In-game console command
CheatMenuItems.refresh()
```

**Auto-scan Features**:
- Detects all items registered by ScriptManager
- Automatically categorizes new mod items
- Updates search index for new content

</details>

<details>
<summary><strong>📊 Performance Tuning</strong></summary>

**Memory Optimization**:
- Catalogs load lazily when first accessed
- Search indices cached for speed
- UI elements recycled efficiently

**Best Practices**:
- Close menu when not in use
- Refresh catalog only when needed
- Use presets for repeated operations

</details>

### 💾 Data Persistence

All settings are automatically saved to `ModData["ZedToolbox"]`:

- ✅ **Hotkey preferences** per save file
- ✅ **Language selection** globally stored
- ✅ **Favorites & presets** cross-session
- ✅ **No external files** required

## 🌍 Localization

### 🗣️ Supported Languages

| Language | Code | Status | Contributors |
|:---|:---:|:---:|:---|
| **English** | `EN` | ✅ Complete | CodeMaster |
| **Portuguese (Brazil)** | `BP` | ✅ Complete | CodeMaster |
| **Spanish** | `ES` | ✅ Complete | CodeMaster |
| **German** | `DE` | ✅ Complete | CodeMaster |
| **French** | `FR` | ✅ Complete | CodeMaster |
| **Russian** | `RU` | ✅ Complete | CodeMaster |

### 🌏 Add Your Language

**Want to see Zed Toolbox in your language?**

1. **Fork & Clone** the repository
2. **Copy template**: `cp Translate/EN/ZedToolbox_EN.txt Translate/YourLanguage/ZedToolbox_XX.txt`
3. **Translate strings**: Keep the key structure, translate values
4. **Test in-game**: Verify formatting and completeness
5. **Submit PR**: Share your translation with the community

**Translation Guidelines**:
- 📏 Keep similar string lengths when possible
- 🎮 Maintain gaming terminology consistency
- ✅ Test all interface elements in-game
- 📝 Add your name to contributors list

> 🙏 **Community translations welcome!** Help make Zed Toolbox accessible to players worldwide.

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
               │   └── ZedToolbox_BP.txt
               ├── 📁 EN/
               │   └── ZedToolbox_EN.txt
               ├── 📁 Spanish/
               │   └── ZedToolbox_ES.txt
               ├── 📁 German/
               │   └── ZedToolbox_DE.txt
               ├── 📁 French/
               │   └── ZedToolbox_FR.txt
               └── 📁 Russian/
                  └── ZedToolbox_RU.txt
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

## 🤝 Contributing

### 🎯 Ways to Contribute

We welcome contributions from the Project Zomboid community! Here's how you can help:

| **Area** | **How to Help** | **Skill Level** |
|:---|:---|:---:|
| **🐛 Bug Reports** | Report issues with detailed reproduction steps | Beginner |
| **🌐 Translations** | Add support for new languages | Beginner |
| **✨ Features** | Suggest and implement new functionality | Intermediate |
| **📖 Documentation** | Improve README, add guides | Beginner |
| **🧪 Testing** | Test with different mods and setups | Beginner |
| **💡 Code Review** | Review pull requests and suggest improvements | Advanced |

### 📋 Contribution Guidelines

<details>
<summary><strong>🔨 Development Setup</strong></summary>

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create branch**: `git checkout -b feature/your-feature-name`
4. **Test** your changes in Project Zomboid
5. **Commit**: Use clear, descriptive commit messages
6. **Push & PR**: Create pull request with detailed description

</details>

<details>
<summary><strong>📝 Code Standards</strong></summary>

- **Lua Style**: Follow existing code formatting
- **Comments**: Document complex logic and APIs
- **Error Handling**: Use logger system for all errors
- **Performance**: Consider impact on game performance
- **Testing**: Verify changes don't break existing features

</details>

### 🎖️ Recognition

Contributors get:
- 🏷️ **Name in credits** section
- 📈 **GitHub contributor** status  
- 💎 **Special mention** in release notes
- 🌟 **Community appreciation** from users worldwide

### 💬 Community

- **🐛 Issues**: [GitHub Issues](https://github.com/CodeMaster-java/ZedToolbox/issues)
- **💡 Discussions**: [GitHub Discussions](https://github.com/CodeMaster-java/ZedToolbox/discussions)  
- **📧 Contact**: [Email CodeMaster](mailto:robsonjosecorreacarvalho@gmail.com)


## 🙌 Credits & Acknowledgments

<div align="center">

**🏆 Created with ❤️ by [CodeMaster](https://github.com/CodeMaster-java)**

*Dedicated to the Project Zomboid community and modding ecosystem*

---

### 🌟 Special Thanks

| **Contributor** | **Role** | **Contribution** |
|:---|:---:|:---|
| **Project Zomboid BR Community** | 🧪 Beta Testers | Valuable feedback and testing |
| **The Indie Stone** | 🎮 Developers | Creating the amazing Project Zomboid |
| **CodeMaster** | 🌐 Localization | All 6 language translations |
| **Mod Users** | 📊 Feedback | Bug reports and feature suggestions |

### 📞 Support & Community

| **Platform** | **Purpose** | **Link** |
|:---|:---|:---|
| **🐛 GitHub Issues** | Bug reports & feature requests | [Report Here](https://github.com/CodeMaster-java/ZedToolbox/issues) |
| **💡 Discussions** | Community chat & support | [Join Discussion](https://github.com/CodeMaster-java/ZedToolbox/discussions) |
| **📧 Direct Contact** | Private inquiries | [Email CodeMaster](mailto:robsonjosecorreacarvalho@gmail.com) |
| **🔀 Pull Requests** | Code contributions | [Contribute Code](https://github.com/CodeMaster-java/ZedToolbox/pulls) |

### 🏅 Recognition Wall

*Contributors who've helped make Zed Toolbox better:*

- 🌐 **Language Contributors**: CodeMaster (EN, BP, ES, DE, FR, RU)
- 🧪 **Beta Testers**: Project Zomboid BR Community, Early Adopters
- 💡 **Feature Suggesters**: Community members who shaped the roadmap

---

### 🎮 Happy zombie survival in Knox County! 🧟‍♂️

**⭐ If Zed Toolbox enhances your gameplay, consider starring the repository!**

*Made with passion for the Project Zomboid community • Free & Open Source Forever*

</div>

---

## 🧠 Advanced / Developers

<details>
<summary><strong>🌎 Translation System</strong></summary>

### 🗣️ Supported Languages

| Language | Code | Status |
|:---:|:---:|:---:|
| English | `EN` | ✅ Complete |
| Portuguese (Brazil) | `BP` | ✅ Complete |
| Spanish | `ES` | ✅ Complete |
| German | `DE` | ✅ Complete |
| French | `FR` | ✅ Complete |
| Russian | `RU` | ✅ Complete |

### 🔧 Adding New Languages

1. **Create Language Directory**: `media/lua/shared/Translate/<LOCALE>/`
2. **Copy Base File**: `cp ZedToolbox_EN.txt ZedToolbox_<LOCALE>.txt`
3. **Translate Content**: Maintain key structure and test in-game
4. **Update Folder Name**: Use proper locale code

### 📂 Structure
```
media/lua/shared/Translate/
├── EN/ZedToolbox_EN.txt
├── BrazilianPortuguese/ZedToolbox_BP.txt
└── <YourLanguage>/ZedToolbox_<CODE>.txt
```

</details>

<details>
<summary><strong>🐛 Debugging & Logs</strong></summary>

| Log Type | Location | Purpose |
|:---:|:---:|:---:|
| **Error Logs** | `Zomboid/mods/ZedToolbox/logs/` | Exception tracking |
| **Format** | `error-<context>-<timestamp>.txt` | Detailed error info |

**Features**: Timestamped entries • Context-aware logging • Safe call wrappers • Detailed stack traces

</details>

---

<div align="center">

**🔥 If you find this mod helpful, consider ⭐ starring the repository!**

**📊 Project Stats**: 20+ hours of development • 48+ downloads • 6 languages (all by CodeMaster) • 100% free

*Made for the Project Zomboid community • Open Source • MIT License*

**[⬆️ Back to Top](#-zed-toolbox)** • **[🏪 Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3623287081)** • **[📥 GitHub](https://github.com/CodeMaster-java/ZedToolbox/releases)** • **[🐛 Report Issue](https://github.com/CodeMaster-java/ZedToolbox/issues)**

---

<sub>© 2025 CodeMaster | This mod is not affiliated with The Indie Stone or Project Zomboid</sub>

</div>
