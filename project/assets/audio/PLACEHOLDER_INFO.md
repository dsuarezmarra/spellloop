# Placeholder Audio Files

The audio system is designed to handle missing audio files gracefully.
When audio files are missing:

1. AudioManager will log warnings but continue running
2. play_sfx() calls will fail silently
3. play_music() calls will be ignored

To add real audio:
1. Place OGG files in the appropriate subdirectories
2. Name them according to the documentation
3. Restart the game to load the new audio

The game will work without audio files, but obviously without sound.

## Quick Audio Setup for Testing

For quick testing, you can:

1. **Download free sounds from:**
   - Freesound.org
   - OpenGameArt.org
   - Zapsplat.com (requires free account)

2. **Generate simple sounds with Audacity:**
   - File → Generate → Tone (for basic beeps)
   - Record your own voice for placeholder sounds
   - Use built-in generators for noise/effects

3. **Convert to OGG format:**
   - Use Audacity: File → Export → Export as OGG
   - Use online converters
   - Use FFmpeg: `ffmpeg -i input.wav output.ogg`

4. **Place files in correct folders:**
   - music/ for background music
   - sfx/ for sound effects
   - Name them exactly as listed in the README files

The game will automatically detect and load new audio files on restart.