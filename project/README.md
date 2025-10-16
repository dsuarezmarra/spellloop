# 📖 Spellloop - Documentation Index

## Quick Links

### Getting Started
- **[CURRENT_STATUS_AND_NEXT_STEPS](docs/GUIDES/CURRENT_STATUS_AND_NEXT_STEPS.md)** - Current project status and what's next

### Systems Documentation
- **[Chest & Popup System](docs/SYSTEMS/POPUP_DEBUG_FIXES.md)** - How the treasure chest and item selection works
- **[Item System](docs/SYSTEMS/FIX_POPUP_BUTTONS_SUMMARY.md)** - Item mechanics and implementation

### Guides & References
- **[Testing Checklist](docs/GUIDES/TESTING_CHECKLIST.md)** - How to test the game properly
- **[Solution Explained](docs/GUIDES/SOLUTION_EXPLAINED.md)** - Technical explanations
- **[Visual Summary](docs/GUIDES/VISUAL_SUMMARY.md)** - Diagrams and visual guides

### Archived Documentation
Old technical documents and solutions are in [docs/ARCHIVED](docs/ARCHIVED/) for reference.

---

## Project Structure

```
project/
├── scripts/
│   ├── core/           # Core systems (managers, game state)
│   ├── entities/       # Player, enemies, projectiles
│   ├── magic/          # Spell and magic systems
│   ├── ui/             # UI components
│   ├── utils/          # Utility functions
│   ├── enemies/        # Enemy definitions
│   ├── bosses/         # Boss definitions
│   ├── items/          # Item definitions
│   ├── effects/        # Visual effects
│   ├── spawn_table.gd  # Enemy spawn configuration
│   └── DEPRECATED/     # Old code (kept for reference)
│
├── scenes/
│   ├── SpellloopMain.tscn (Main game scene)
│   ├── characters/
│   ├── enemies/
│   ├── effects/
│   ├── bosses/
│   ├── ui/
│   └── test/ (for testing)
│
├── assets/
│   ├── audio/
│   ├── data/
│   └── sprites/
│
└── docs/
    ├── SYSTEMS/     (System documentation)
    ├── GUIDES/      (How-to guides and checklists)
    └── ARCHIVED/    (Historical documentation)
```

---

## Development Guidelines

1. **Before making changes:** Read relevant docs in `/docs/SYSTEMS/`
2. **Adding new features:** Check `/docs/GUIDES/` for patterns
3. **Debugging:** See `CURRENT_STATUS_AND_NEXT_STEPS.md`
4. **Testing:** Follow `TESTING_CHECKLIST.md`

---

## Key Systems

- ✅ **Infinite World** - Chunk-based procedural generation
- ✅ **Combat** - Player spells vs enemies
- ✅ **Experience** - Level progression
- ✅ **Treasure Chests** - Item rewards
- ✅ **Item System** - Stat bonuses
- 🔧 **Audio** - Music and SFX
- 📊 **UI** - Menus and HUD

---

**Last Updated:** 2025-01-16  
**Status:** Actively Developed ✅
