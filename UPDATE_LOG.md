# DREAM HUB — UPDATE LOG

---

## COMING NEXT UPDATE

- JJS Premium and Plus plans
- Boxing beta (Premium)
- INF Stamina fix (Prior Extinction)
- Teleport fix (Jujutsu Shenanigans)

---

# PRIOR EXTINCTION

## New features

### Combat / PvP
- Silent Aim + Lock On + Turn Hack
- Always Damage
- Hitbox Expander (+ Show Hitbox)
- No Grab Weight Limit
- Track Player + Auto Farm Player
- Target system: type ANY player's name — see their dino/profile, teleport, view, farm them

### Movement
- Fly, Float, Speed Hack, Noclip
- Anti-Snapback Teleports
- Safe Teleport

### Survival
- INF Food + INF Water + Carnivore Meat TP
- Anti Drown + Walk on Water
- Anti Head / Anti Bleed / Bone Protection (anti-injury)
- Anti Fall + Auto Heal Blood
- Death Bug Fix (spawn rescue) — now drops you next to a RANDOM PLAYER
- No Sleep Screen, Auto Clean, AFK Eat, Pro Food
- Save Dino + Progress Restore (replays your spawn payload)

### Auto Farm / Bot
- Auto Farm Fossil + Auto Farm Gemstone + Teleport Farm
- Auto Play Bot — plays the game for you: flees predators, roams, sleeps to heal, announces what it's doing

### Teleports
- Biome teleport (every loaded biome) + teleport to spawn/origin
- Corpse teleport that lands on real ground

### Visuals
- ESP: creatures + players, corpses, plants, fish, gems + fossils
- Minimap Radar — see players anywhere + your death point
- Full Bright, No Night, No Darkness Underwater, Water Transparency, No Clouds, INF Light
- Remove Trees (big FPS boost, edible plants kept), Wet textures

### Misc
- Skins tab, Anti-AFK, Unlock FOV, INF Zoom, Unlock Mouse + Camera
- Keybinds for 25+ features, UI scale, config saving

### Live chat + staff (new this update)
- Live chat with every hub user across all 3 games (avatar, name, role badge, plan, game)
- Emoji shortcodes (:skull: :fire: :100: + 20 more)
- Staff roles: OWNER / DEV / HEAD MOD / GAME MOD — in chat, above heads, on the menu profile
- 62 staff commands (?cmds shows all): ?warn ?mute ?noemoji ?del ?announce ?dm ?slowmode ?lockchat
  ?badword ?settitle ?tp ?rtp ?fly ?bright and more
- Warning tracker (?warns) — who has warnings, the reasons, who warned them
- Staff can delete any chat message (x button)
- AI mod — scans chat, blocks + auto-reports rule breaks to Discord with the message as evidence
- Admin tab: load user (incl. yourself), warn popup, teleport to user, view player, fly, copy
  username/UserId/profile, report to Discord with proof image link
- Rules tab (15 rules + punishments), bug reports with proof from the menu
- Mod overhead titles only hub users can see
- Dashboard menu + spinner loading screen

## Fixes
- FIXED: Hitbox Expander now works on EVERY dino — the loop scanned only a couple folders and skipped
  dinos in CharacterIgnore.LeftCharacters; it now uses the full model list (nearest-first) and triggers
  the game's own hitbox builder for dinos that have no Hitbox part yet
- FIXED: clicking did NO damage while Anti Fractured was on — the injury protection was eating your own
  attack remotes (crush/blunt/bite keywords). Attacks always pass through now; protection unchanged
- FIXED: teleports "glided" you across the map — you now snap instantly; the server still sees a
  believable path so there's no send-back
- FIXED: second attack (M2) dealt no damage while INF Stam was on
- FIXED: auto farm was feeding you to death
- FIXED: corpse teleport put you on top of the corpse / floating in the air
- FIXED: spawn rescue fought the game's own Unstuck timer and yanked you on normal spawns
- FIXED: Discord reports never arrived on executors that block discord.com (proxy retry added)
- FIXED: admin teleport only worked in this game — now generic with a dino fallback

## Reworked
- All teleports: instant snap + anti-fall protection on landing
- Warns: popup card on the target's screen instead of game chat
- Overhead title: clean rainbow text, no box, no emoji, finds your dino model, per-role text
- Menu: dashboard layout, hover effects, gradient ENTER HUB, refreshed update log
- Warn text box + add-admins box removed from Admin (custom warns = ?warn in chat)

## Not working
- INF Stamina — NOT WORKING, getting fixed. Don't use it. (The game re-corrects sprint speed
  server-side; the note is in the hub too.)

---

# ABILITY ARENA

## New features

### Fight
- God Mode + Save Health (low HP → fly to sky, heal, drop back)
- Anti-Ragdoll (hard), Anti-Push (knockback), Anti Kill Bricks
- Anti Void / Water (instant TP back) + Remove Water Border
- Instant 1v1 Win
- Legit Auto Play + Auto Dodge + Auto Respawn
- M1 Warp + Warp Back After Swing + Aura M1
- Dash Behind On Hit + Auto Dash + Spin Bot + Anti-Fling
- Auto Heal

### Skills
- Auto Ability + Cast E / Q / R / T
- Ability Aim Assist + Strong Aim + Aim on M1 + Camera Lock
- Get Ability Again / refresh ability list

### Teleport
- TP To Target (in front) + TP Behind Target + TP Behind Nearest Player
- TP To Ability Pads (lobby)
- Safe Spawn: set / teleport / clear
- Click Teleport [V]
- Return to map spawn after grab
- View Player / Stop Viewing

### Movement
- Fly (WASD + Space/Ctrl), Noclip, Speed Hack, Infinite Jump

### Auras
- Apply My Aura, add/remove any aura, Core Shape, Rainbow (animated), Particles, Light Glow,
  save/copy presets

### Visuals
- Player ESP (color by HP), Tracers, 2D ESP Boxes, Show Ability on ESP, Enemy Highlight, Full Bright

### Misc
- Rejoin Server + Server Hop, Dump Player Data, Anti-AFK, Unload hub

### Live chat + staff (new this update)
- Same full system as Prior Extinction: live chat with roles + emoji, 62 staff commands, warning
  tracker, message delete, AI mod with Discord auto-reports, admin tab, rules tab, bug reports with
  proof, mod overhead titles, dashboard menu + loading screen

## Fixes
- FIXED: input boxes showed "TextBox / This is a TextBox / Write your input there" — labels now show
  your text and the hardcoded placeholder is rewritten after each box is created
- FIXED: Discord reports blocked by executors (proxy retry)
- FIXED: Send Warn did nothing — warns now pop on the target's screen through the relay

## Reworked
- Warn text box removed from Admin (Send Warn = standard warning; custom = ?warn in chat)
- Menu polish: hover effects, centered gradient ENTER HUB, refreshed update log

## Not working
- Nothing specific to this game right now

---

# JUJUTSU SHENANIGANS

## New features

### Combat
- M1 Black Flash + Auto Black Flash + Yuta Black Flash (+ mobile BF button + debug overlay)
- Feint M1 + Feint Abilities
- Aim Assist + Side Dash Assist (Q) + Back Dash Assist (E)
- Dash Block / M1 Block / Abilities Block
- Camera Follow

### Character tech
- Gojo TP Back + Reversal Red
- Auto Rika Down Slam + Rika Love Sword
- Crow Ult + Crow Lock On
- Head of Hei Ult
- Goku M1 + Goku Dodge
- Hollow Nuke

### Auto / defense
- Auto Counter (+ Locked Only) + Anti Counter
- Anti-Stun, Anti-Ragdoll, Anti-Domain, Anti Black Hole
- Auto Mahito Grab Escape + Mahoraga Safe TP
- Auto Evasive + Auto Yuta Black Flash + Auto Ult + Auto Air
- Auto Adapt + Auto Domain Adapt
- Auto Earthquake (+ debug)
- Auto Kill Emote
- Auto Skills: skill 1-4, Special R, Awakening G

### Target / player
- Target system with teleport/view
- Player settings page

### Live chat + staff (new this update)
- Same full system as Prior Extinction: live chat with roles + emoji, 62 staff commands, warning
  tracker, message delete, AI mod with Discord auto-reports, admin tab, rules tab, bug reports with
  proof, mod overhead titles, dashboard menu + loading screen

## Fixes
- FIXED: input boxes showed library defaults — labels + placeholders now show your text
- FIXED: Discord reports blocked by executors (proxy retry)
- FIXED: Send Warn did nothing — warns now pop on the target's screen through the relay

## Reworked
- Warn text box removed from Admin (Send Warn = standard warning; custom = ?warn in chat)
- Menu polish: hover effects, centered gradient ENTER HUB, refreshed update log

## Not working
- Teleport — NOT WORKING, getting fixed. The fix ships in the next update.

---

## Honest limits (all scripts)
- Scripts cannot capture a real screenshot — the exact chat message is the report evidence
- Chat, warns, mutes and titles only reach people running the hub (relay, not a Roblox feature)
- Live chat refreshes about every 4 seconds
- Roblox does not expose anyone's Discord account — nothing can link the two
