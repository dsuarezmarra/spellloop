# Footsteps Audio Matrix

| Biome | Biome Key | Surface: Ground (default) | Surface: Path |
|---|---|---|---|
| **Grassland** / Forest | `grass` | `sfx_footstep_grass_ground_*.mp3` | `sfx_footstep_grass_path_*.mp3` |
| **Desert** | `sand` | `sfx_footstep_sand_ground_*.mp3` | `sfx_footstep_sand_path_*.mp3` |
| **Snow** | `snow` | `sfx_footstep_snow_ground_*.mp3` | `sfx_footstep_snow_path_*.mp3` |
| **Lava** / Volcano | `lava` | `sfx_footstep_lava_ground_*.mp3` | `sfx_footstep_lava_path_*.mp3` |
| **Arcane Wastes** | `arcane` | `sfx_footstep_arcane_ground_*.mp3` | `sfx_footstep_arcane_path_*.mp3` |
| **Death** / Void | `void` | `sfx_footstep_void_ground_*.mp3` | `sfx_footstep_void_path_*.mp3` |

## Code Implementation
- **File**: `scripts/entities/SpellloopPlayer.gd`
- **Logic**:
  1. Checks `ArenaManager.is_on_path(pos)`
  2. Checks `ArenaManager.get_biome_at_position(pos)`
  3. Constructs ID: `sfx_footstep_{biome}_{surface}`
  4. Calls `AudioManager.play(id)` (random pitch/variation)

## Fallbacks
If a specific ID is missing, `AudioManager` logs a warning (debug only) but doesn't crash.
Legacy IDs (like `sfx_footstep_grass`) are mapped to `_ground` variants in `audio_manifest.json` for compatibility.
