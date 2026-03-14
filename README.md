# 🐊 Croc Notes

A powerful, offline-first modular journaling app for Windows desktop (and Android planned) with rich text editing, timers, and system tray integration. Organize your thoughts like never before!

![Croc Notes Banner](https://github.com/Arthritisboy/Croc-Notes/blob/master/assets/icon/app_icon.png)

## ✨ Features

### 📝 Rich Text Editing

- Full-featured rich text editor with toolbar (bold, italic, underline, colors, fonts)
- Image insertion
- HTML-style formatting with real-time preview
- Copy-paste images directly from clipboard

### 📊 Modular Journal System

- **Categories & Tabs**: Organize notes with customizable colored categories and tabs
- **Three-Grid Layout**:
  - Left: Checklist with checkbox states (✓, ✗, ⬜)
  - Right: Rich text notepad
  - Bottom: Rich text notepad with image support
- **Pinned Tabs**: Pin important tabs to the top for quick access

### ⏰ Timer System

- Create timer items with custom names
- Set durations (hours, minutes, seconds)
- Choose custom alarm sounds or use default alarm.mp3
- Timer states: Running ▶️, Paused ⏸️, Completed ✅
- Visual countdown display
- System tray integration - app pops up when timer completes
- Loop alarms until dismissed

### 🎨 Customization

- Color picker with hex input for categories and tabs
- Drag-and-drop category reordering
- Search categories and tabs with fuzzy matching
- Collapsible toolbars in notepads

### 🖥️ Desktop Features

- **System Tray Integration**: Minimize to tray, continue running in background
- **Custom Window Controls**: Minimize, maximize/restore, and exit with options
- **Acrylic Effect**: Modern Windows 11 blur effect
- **Multi-monitor Support**: Remembers position and state

### 🔄 Data Management

- **Offline First**: SQLite database with file-based image storage
- **Auto-save**: All changes saved instantly
- **Backup & Restore**: Export/import your entire journal as ZIP
- **Portable**: Data stored next to executable for easy backup

### 🔍 Search & Organization

- Live fuzzy search across categories and tabs
- Filter by pinned tabs only
- Collapsible category tree view

## 📸 Screenshots

### Main Interface

![Main Interface](https://github.com/Arthritisboy/Croc-Notes/blob/master/readme_pics/main_interface.png)
_Three-grid layout with categories sidebar_


### Timer System

![Timer System](https://github.com/Arthritisboy/Croc-Notes/blob/master/readme_pics/timer.png)
_Timer items with countdown and alarm setup_


### Settings
![Settings](https://github.com/Arthritisboy/Croc-Notes/blob/master/readme_pics/settings.png)
_Automatic Windows Startup and Import/Export database


## 🚀 Installation

### Windows (Portable ZIP)

1. Download the latest `CrocNotes.zip` from [Releases](https://github.com/Arthritisboy/Croc-Notes/releases)
2. Extract to any folder
3. Run `croc_notes.exe`

### Build from Source

```bash
# Clone the repository
git clone https://github.com/Arthritisboy/croc-notes.git
cd croc-notes

# Get dependencies
flutter pub get

# Run in development mode
flutter run -d windows

# Build release version
flutter build windows --release
```

### 🎮 How to Use
Getting Started
Create your first category using the ➕ button

Add tabs to your category

Start writing in the notepads

Create checklist items or timers

Keyboard Shortcuts
Shortcut	Action
Ctrl+V	Paste text or images
Ctrl+B	Bold text
Ctrl+I	Italic text
Ctrl+U	Underline text
Ctrl+Z	Undo
Ctrl+Y	Redo
Timer Controls
Click checkbox to start timer

Click again (X) to pause

Click again (⬜) to reset

Double-click timer to edit properties


### 🛠️ Built With
Flutter - UI framework

SQLite - Local database

flutter_quill - Rich text editor

window_manager - Desktop window management

tray_manager - System tray integration

audioplayers - Alarm sounds

super_clipboard - Clipboard image paste


🔧 Configuration
Default Alarm Sound
Place your alarm.mp3 in assets/sounds/ before building.


📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
Icons from FontAwesome and Material Icons

Inspired by AHOY note-taking software
