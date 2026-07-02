# 🔥 Update Log

Everything here is **client-side / input-based**. Auras and cosmetic swaps are visual to you only.
Combat features drive the game's own inputs/remotes, so they depend on your executor — and
The Strongest Battlegrounds is server-validated, so nothing is guaranteed god-mode.

---

## ⚔️ TSB Tech Builder (Base + PLUS)

**Two scripts now:**
- **Tech Builder** — the combo/tech builder (reworked).
- **Tech Builder PLUS** — the full builder **+** a whole feature hub.

### Combat / techs
- Fixed **Uppercut & Downslam** using TSB's **real `Communicate` remote** (M1 = `LeftClick`, jump = `Record Jump`) instead of key inputs that never landed.
- **Auto Uppercut / Auto Downslam** toggles (in Player **and** Exploits) — throws the M1 chain then the launcher automatically; stops **instantly** when you toggle off.
- Fixed the "keeps running like a noob" bug + bounded **Chase** so combos actually reach the enemy.
- New **Fight tab**: one-click **LOCK + RUN COMBO**, M1 Reach, combo speed, auto-block/evade.
- Fixed the Volt **"out of local registers (>200)"** compile crash.

### PLUS hub tabs
- **Player** — WalkSpeed, **Fly (with flight animation)**, Noclip, Infinite Jump, Jump Power, Invisibility, No-Anim, Upside Down, No-Cooldown, **sticky Aimlock (aims at the head)**, **Streak Notifier** (reads the killstreak tag).
- **Auras** — anime **body-wrapping ki-flame aura** + rising energy + glowing outline + ground ring, **13 colors + Rainbow + Size slider**.
- **Keybinds** — Anime Teleport, Ghost Mode, HRP Freeze, Gojo (Repulse / Erase / Attract).
- **Teleports** — to nearest/picked player, sky, spawn, save-slots (anti-send-back).
- **Exploits** — Anti-Ragdoll, **Anti-Void**, and **anti-move auto-dodge by real animation IDs** (Table Flip / Serious Punch / Omni / Garou Ult / Incinerate / Death Blow / Death Counter). Ranged moves = **teleport dodge**.
- **Counters** — Lock-On-target-only, Ultimate Alert, and **Jump-On-Counter** that smoothly **glides onto their head + says "EZ BOY"** (no longer triggers on freshly-spawned players).
- **Trash Can** — grab **every** trash can in the map and throw it at a target / All, with a **Stop** button.
- **Utility** — DEX, FPS Booster, Scan Remotes, custom display name, custom idle/walk anims, **Hotbar rename** (`PlayerGui.Hotbar`).
- **Auto-Block removed** (per request).

---

## ✨ Ability Arena — Valutix Hub

- **New UI: switched from Rayfield → Fluriore** (with a Rayfield fallback so it always loads).
- Renamed tabs: **Home / Fight / Skills / Teleport / Movement / Auras / Farm / Misc**, each with its own icon.
- Fixed **empty Farm & Misc tabs** and the **overlapping title**.
- **No more red aura sphere on spawn.**
- Full **Aura / VFX Maker** (presets, dual-color / rainbow, particles, light, rings, beams, trail) intact.

---

## 🔪 Defuse Division — Skin Changer

- Knife **model swap** now grips your hand correctly (`Camera.Arms.Handle`) for **every** model.
- **More models** in the dropdown (knives, weapons, skin meshes) + Pos / Rot / Scale sliders.
- New **"Customize Skin"** tab — take **any** weapon's skin (color / texture / material) and put it on a **knife or gun**.
