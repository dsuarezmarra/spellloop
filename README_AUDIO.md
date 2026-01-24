# Spellloop Audio System

## Status: COMPLETE

**234 SFX assets** generated and ready for use.

## Quick Start

```gdscript
# Play a sound effect
AudioManager.play("sfx_player_hurt")

# Play with volume offset
AudioManager.play("sfx_fire_cast", -3.0)
```

## Available Sound Groups

| Category | Sounds |
|----------|--------|
| **Gameplay** | sfx_player_hurt, sfx_player_death, sfx_player_heal, sfx_player_revive, sfx_shield_absorb, sfx_shield_break, sfx_turret_lock, sfx_barrier_hit |
| **Status** | sfx_status_burn_loop, sfx_status_poison_loop, sfx_status_freeze_loop, sfx_status_curse_loop |
| **Weapons** | sfx_ice_cast/hit, sfx_fire_cast/hit, sfx_lightning_cast/hit, sfx_arcane_cast/hit, sfx_shadow_cast/hit, sfx_nature_cast/hit, sfx_void_cast/hit |
| **Fusions** | sfx_fusion_steam_cannon, sfx_fusion_frozen_thunder, sfx_fusion_blizzard, sfx_fusion_volcano, sfx_fusion_eclipse, etc. (44 total) |
| **UI** | sfx_ui_click, sfx_ui_hover, sfx_ui_confirm, sfx_ui_cancel, sfx_ui_error, sfx_slot_spin_loop, sfx_slot_stop, sfx_rarity_common, sfx_rarity_legendary |
| **Coins** | sfx_streak (8 variations - C to high-C scale) |
| **Enemies** | sfx_enemy_spawn, sfx_elite_spawn, sfx_boss_alarm, sfx_hit_flesh/bone/armor/ghost/slime, sfx_death_flesh/bone/armor/ghost/slime |

## File Locations

- Audio files: `project/audio/sfx/...` (MP3 format)
- Runtime manifest: `project/audio_manifest.json`
- AudioManager: `project/scripts/core/AudioManager.gd`
- AudioLoader: `project/scripts/core/audio_loader.gd`

## Regeneration

To regenerate audio:
```bash
python tools/audio_generator.py      # Generate SFX
python tools/generate_manifest.py    # Update manifest
```
