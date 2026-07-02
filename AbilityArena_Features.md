# Valutix Hub - Ability Arena

Client-side hub for Ability Arena. Everything is local/input-based (visuals are seen by you;
combat drives the game's own inputs). UI: Fluriore (falls back to Rayfield if Fluriore fails to load).

## Recent changes
- Switched the whole GUI from Rayfield to Fluriore, with a Rayfield fallback so it always loads.
- Renamed tabs: Home / Fight / Skills / Teleport / Movement / Auras / Farm / Misc, each with its own icon.
- Fixed empty Farm and Misc tabs (a missing color-picker adapter was halting the build).
- Fixed the overlapping window title.
- Fixed the red aura sphere that appeared on spawn (Fluriore fires callbacks on creation; the VFX preset was applying the default aura on load).

## Tabs and features

### Home
- Welcome, status, best-combo tips, credits.

### Fight
Survival:
- Anti-Ragdoll (hard)
- Anti-Push (knockback)
- Anti Void / Water (instant TP back)
- Remove Water Border (makes Anti Water hold)
- Anti Kill Bricks (remove them)
- Save Health (low HP -> fly to sky, heal, drop back) + trigger HP % + sky height

Hitbox:
- M1 Hitbox Expander (+ size) - your M1 reaches farther
- Ability Hitbox Expander (pulses bigger on E) (+ size)
- Expand Whole Body (max reach)

Auto combat:
- Auto M1 (click spam)
- Auto Ability (+ range)
- Cast E / Q / R / T
- Dash Behind On Hit (M1 -> snap behind + dash) (+ range)
- Auto Dash (spam dash) (+ dash key + speed)

Aim:
- Camera Lock (nearest) (+ range)
- Ability Aim Assist (face enemy on skill cast) (+ range + lead/prediction)

### Skills
- Grab Delay
- Return to map spawn after grab
- Get Ability Again
- Refresh Ability List

### Teleport
- TP To Target (in front) / TP Behind Target / TP Behind Nearest Player
- Refresh Player List
- TP To Ability Pads (lobby)
- Click Teleport [V]
- Set / TP to / Clear Safe Spawn (saved position)

### Movement
- Fly (WASD + Space/Ctrl) (+ speed)
- Noclip
- Speed Hack (+ walk speed)
- Infinite Jump
- Spin Bot
- Anti-Fling

### Auras / ESP
ESP:
- Player ESP, Color By HP, Tracers, ESP Boxes (2D), Show Ability on ESP, Max Distance
- Enemy Highlight (+ color)
- Full Bright

Spectate:
- View Player / Stop Viewing

Game auras:
- Add Aura / Remove Aura / Refresh Aura List (wear in-game aura effects)

Aura / VFX Maker (build your own):
- Apply My Aura + one-click Presets (Fire, Ice, Lightning, Galaxy, Shadow, Holy, Toxic, Rainbow, Void, Sakura, Nuke)
- Core: shape, color 1, color 2 (gradient), rainbow, size, transparency
- Particles: texture, rate, speed, spread, size
- Extras: light glow + brightness, spinning rings + count + spin speed, beams / pillars, trail
- Save / Copy Preset

### Farm
- Auto Play (fight nearest enemy automatically) (+ search range)
- Auto Farm Target (+ target player picker) + Refresh Player List

### Misc
- Anti-AFK
- Instant Respawn
- Rejoin Server / Server Hop
- Dump Player Data (console) / Spy M1 Packets (debug)
- Unload Valutix Hub
