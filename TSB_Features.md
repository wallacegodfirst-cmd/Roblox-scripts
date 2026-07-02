# TSB - Tech Builder (Prem) and Tech Builder Plus

Two scripts for The Strongest Battlegrounds. Client-side / input-based. TSB validates combat
server-side, so nothing is guaranteed god-mode; the reliable parts are movement, aim, visuals,
anti-move dodging, and inputs sent through the game's own remotes.

## New GUI
- A new UI is being added (theme/library provided separately). This doc will be updated when it lands.

## New features (this update)
- Uppercut and Downslam now fire the REAL game remote (Character.Communicate: LeftClick = M1,
  Record Jump = jump) instead of key inputs that never landed.
- Auto Uppercut / Auto Downslam - throws the M1 chain then the launcher; stops instantly on toggle off.
- Anime body-wrapping ki-flame auras (13 colors + Rainbow + Size slider).
- Sticky Aimlock that aims at the head and holds one target.
- Fly plays a looped flight animation while active.
- Anti-move auto-dodge matched by real animation IDs (ranged moves = teleport dodge).
- Jump-On-Counter: smoothly lands on the enemy's head and says "EZ BOY" (no longer hits spawners).
- Trash Can: grab every trash can and throw at a target / All, with a Stop button.
- Streak Notifier reads the in-game killstreak tag.
- Fixed the Volt "out of local registers (>200)" compile crash.

## Prem - Tech Builder (the combo builder)
Build and run combos with correct TSB timing.
- Fight tab: one-click LOCK + RUN COMBO, M1 Reach, combo speed, auto-block, auto-evade, lock-on.
- Builder: hand-build combos (M1, dashes, uppercut, downslam, jump, skills 1-4, ultimate, waits).
- Character: pick your character + ready-made bread-and-butter combos.
- Presets: universal ready-made techs.
- Saved: save / load your own combos.
- Settings: combo speed, M1 ping profile, run mode, targeting, chase, smart-combat, hitbox.
- Combat / Record: targeting tools, auto-evade, input diagnostics, record your own combo.

## Plus - Tech Builder Plus (the full hub)
Everything in Prem PLUS these tabs:
- Fight - the combo builder Fight page (one-click lock + combo).
- Player - WalkSpeed, Fly (+ flight animation), Noclip, Infinite Jump, Jump Power, Auto Uppercut,
  Auto Downslam, Anti-Ragdoll, Anti-Void, Invisibility, No Animations, Upside Down, No Cooldowns,
  Aimlock (+ range), Streak Notifier.
- Auras - anime ki-flame aura, 13 presets + Rainbow + Size slider.
- Keybinds - Anime Teleport, Ghost Mode, HRP Freeze, Gojo (Repulse / Erase / Attract).
- Teleports - nearest / picked player, Sky, Spawn, save-slots (anti-send-back).
- Exploits - Auto Uppercut / Downslam, Anti-Ragdoll, Anti-Void, anti-move auto-dodge
  (Table Flip, Serious Punch, Omni Punch, Garou Ult, Incinerate, Death Blow, Death Counter),
  Ultimate Alert, Lock-On-only, Jump-On-Counter (EZ BOY).
- Teleports / Trash - grab every trash can and throw at a target / All + Stop.
- Utility - DEX Explorer, FPS Booster, Scan Remotes, custom display name, custom idle/walk
  animations, Hotbar rename (PlayerGui.Hotbar).

Note: Auto-Block was removed by request.
