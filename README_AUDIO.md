# Audio Assets Report
    
## Status
- **Total Sounds**: 0 groups (0 files)
- **Missing**: 363
- **Format Issues**: 0

## Setup
1. Ensure `.env` has valid keys.
2. Run `python tools/audio_generator.py` to fill missing gaps.
3. Run `python tools/validate_audio.py` to verify.

## Godot Usage
```gdscript
AudioManager.play("sfx_player_hurt")
AudioManager.play_music("music_boss_loop")
```
