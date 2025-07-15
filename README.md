# ENDER MAGNOLIA: Stat Modification Mod

A comprehensive stat and accessibility mod for **ENDER MAGNOLIA: Bloom in the Mist** that adds god mode, movement enhancements, and progression shortcuts.

## ⚠️ Developer Note

**This was my first Lua scripting mod!** While it works perfectly and is actively maintained, the code reflects my early learning phase with UE4SS and Lua. I've since developed cleaner coding practices in my newer mods, but I'm keeping this one as-is since it functions well and serves the community. Consider this a functional "learning archive" alongside my more polished recent work.

## 🎮 About

This mod provides accessibility features and progression shortcuts for players who want to:

- Skip grinding and instantly max out character progression
- Enable god mode for exploration and accessibility
- Experience enhanced movement with infinite jumps and speed boosts
- Access creative exploration tools like no-clip mode

## ✨ Key Features

### 🔥 One-Button Accessibility (Hotkeys)
- **F7** - Ultimate God Mode (immortality + infinite jumps + instant dash)
- **F8** - Speed Boost (comprehensive +2000 movement speed)
- **F9** - Exploration No-Clip (free camera mode for exploration)

### 📊 Stat Modifications
- **Level Setting** - Set any character level (persistent)
- **Health Control** - Set max HP, infinite health mode with auto-restore
- **Currency** - Add unlimited materials, scrap, and skill fragments
- **Movement** - Customize jump count (triple jump, flying mode, etc.)
- **Dash Enhancement** - Instant dash charging for fluid movement

### 🎯 Challenge Run Support
- Glass Cannon builds (high damage, 1 HP)
- Level 1 only runs with infinite health
- Enhanced platforming with custom jump counts
- Single jump challenges for increased difficulty

## 🛠️ Installation

### Requirements
- **UE4SS** (Unreal Engine 4 Scripting System): [Download Latest Release](https://github.com/UE4SS-RE/RE-UE4SS/releases)
- **ENDER MAGNOLIA: Bloom in the Mist** (Fully Released Version)

### Setup Steps

1. **Install UE4SS**
   ```
   Extract ALL files from UE4SS zip to:
   [Steam Path]\steamapps\common\ENDER MAGNOLIA\EnderMagnolia\Binaries\Win64\
   ```

2. **Install the Mod**
   ```
   Place the mod folder in:
   ...\Win64\ue4ss\Mods\EnderMagnoliaStatMod\
   ```

3. **Enable the Mod**
   ```
   Edit ...\Win64\ue4ss\Mods\mods.txt
   Add line: EnderMagnoliaStatMod : 1
   ```

4. **Launch & Use**
   - Start the game
   - Press `F10` to open UE4SS console (double-tap for larger window)
   - Type `stat_mod_help` for full command list

## 🎮 Quick Start

**For immediate accessibility:**
- Press **F7** for ultimate god mode (immortality + unlimited movement)
- Press **F8** for maximum movement speed  
- Press **F9** to explore with no-clip mode

**For progression shortcuts:**
```
set_level 100          # Max level instantly
add_materials 999999   # Unlimited upgrade materials
add_scrap 999999       # Unlimited rare currency
add_fragments 999999   # Unlimited skill fragments
```

## 📋 Console Commands

| Command | Description | Persistence |
|---------|-------------|-------------|
| `stat_mod_help` | Show all available commands | - |
| `set_level <num>` | Set character level | ✅ Permanent |
| `set_hp <num>` | Set maximum HP | ❌ Session only |
| `set_hp_robust <num>` | Set HP via data table (more stable) | ❌ Session only |
| `infinite_hp <num>` | Enable auto-health restoration | ❌ Session only |
| `infinite_hp_off` | Disable infinite health | ❌ Session only |
| `set_jump_count <num>` | Set maximum jumps (e.g., 3 = triple jump) | ❌ Session only |
| `set_dash_charge <num>` | Set dash charge time (0.1 = instant) | ❌ Session only |
| `add_materials <num>` | Add upgrade materials | ✅ Permanent |
| `add_scrap <num>` | Add rare currency | ✅ Permanent |
| `add_fragments <num>` | Add skill fragments | ✅ Permanent |
| `god_mode` | Ultimate god mode | ❌ Session only |
| `speed_boost` | Comprehensive movement speed boost | ❌ Session only |
| `freecam` | Toggle exploration no-clip mode | ❌ Session only |

## 🚨 Important Notes

- **Save your game** after using permanent commands (level, currencies)
- **Avoid** the built-in `clear` command in UE4SS console (causes crashes)
- **No-clip mode** may cause death when disabled - use with caution
- **No game files are modified** - completely safe to install/remove

## 🎯 Challenge Ideas

- **Level 1 God Run**: Stay level 1, use `infinite_hp 999999` for survivability
- **Glass Cannon**: High level + `infinite_hp 1` for one-hit death challenge  
- **Flying Explorer**: `set_jump_count 999` + god mode for creative exploration
- **Platforming Master**: `set_jump_count 1` for single-jump difficulty increase

## 🔧 Troubleshooting

**Mod not working?**
1. Verify mod is enabled in `mods.txt`
2. Check UE4SS files are in correct `Win64` folder (not main game folder)
3. Look for "EnderMagnoliaStatMod" in `UE4SS.log` to confirm loading

**Console won't open?**
- Ensure `UE4SS.dll` and `dwmapi.dll` are in the `Win64` directory
- Try pressing F10 twice quickly for larger console window

## 📖 Detailed Documentation

For comprehensive installation instructions, advanced features, and complete troubleshooting guide, see [`stat_mod_docs.txt`](stat_mod_docs.txt).

**Happy modding!** 🌸

---
*Created with UE4SS and Lua • No game files modified • Community-driven accessibility* 