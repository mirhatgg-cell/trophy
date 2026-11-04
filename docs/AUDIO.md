# Audio implementation and asset boundary

Ten original PCM WAV cues are included under `assets/audio/`. They are composed deterministically by `python3 tools/generate_audio.py`; no recordings or third-party music are used.

The place contains **working event routing**, not embedded uploaded audio: preparation, calm, danger, movement, impact, elimination, final survivor, curator victory, survivor victory and line clear. Per-match phase messages are delivered only to that match’s clients. Built-in Roblox sound effects are used for local impact/line feedback. Position, rolloff and playback-speed variation are configured in the client. The original score does not yet play automatically.

Roblox does not allow a `.rbxlx` to embed a local WAV as an immediately usable uploaded SoundId. Upload these ten files to the owner/group of the intended experience using Studio’s Asset Manager / Creator Dashboard Audio. Grant the experience access. Do not insert another creator’s ID without permission.

Set the actual returned IDs in `src/Catalog.lua` (or in Studio, ReplicatedStorage → Catalog):

```lua
C.AudioAssets = {
 preparation = 'rbxassetid://YOUR_UPLOADED_PREPARATION_ID',
 calm = 'rbxassetid://YOUR_UPLOADED_CALM_ID',
 danger = 'rbxassetid://YOUR_UPLOADED_DANGER_ID',
 movement = 'rbxassetid://YOUR_UPLOADED_MOVEMENT_ID',
 impact = 'rbxassetid://YOUR_UPLOADED_IMPACT_ID',
 elimination = 'rbxassetid://YOUR_UPLOADED_ELIMINATION_ID',
 final = 'rbxassetid://YOUR_UPLOADED_FINAL_ID',
 curator_victory = 'rbxassetid://YOUR_UPLOADED_CURATOR_VICTORY_ID',
 survivor_victory = 'rbxassetid://YOUR_UPLOADED_SURVIVOR_VICTORY_ID',
 line = 'rbxassetid://YOUR_UPLOADED_LINE_ID',
}
```

The strings above are documentation placeholders, not values shipped in the game. Rebuild the file after editing source. The user/experience audio upload permission is an external prerequisite; this environment has no Roblox account credentials or Studio upload tool.

Current mix: score volume 0.25, built-in impact 0.65, short notifications 0.35, impact rolloff 8–180 Studs. Spatial reverberation zones, independently authored soundscapes for all fifty interiors and full layered adaptive orchestration are not yet implemented. The ten cues constitute a shared musical palette.
