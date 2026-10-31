# JJS — TBO Feature Research (movesets, move numbers, how each auto-tech works)

Game basics: **M1** melee · **1-4** skills · **Q** dash · **F** block · **R** special · **G** awaken.
Dealing damage fills the awakening bar; G triggers awakened form (heals + new moveset).

## Character data behind the TBO features

### Todo — "Switcher" (Boogie Woogie)
- Base kit: **Swift Kick** (spinning kick), **Brute Force** (heavy punch), Pebble Throw; **R = Boogie Woogie**.
- **Boogie Woogie (R):** aim at target within **60 studs** → clap → instantly swap places/orientations.
  Under **25 studs the swap is UNBLOCKABLE**. Can also swap with throwables/banana peels/TNT (faster clap, half cooldown).
- **Perfect Swap:** M1 timed exactly WITH the clap → **no cooldown, only 3% awakening**.
- **Fakeout:** M1 just BEFORE the clap → full awakening refund.
- Defensive tech: look away before a swap so the enemy's queued attack whiffs.
- → `Auto Swap Players` = auto-R at chosen target (Closest/Furthest/Random) inside 60 (ideally 25) studs.
- → `Auto Perfect Swap` = fire R, then auto-M1 on the clap frame (fixed anim timing = automatable).
- → `Todo Bring (Swift Kick)` = swap to the target then instantly Swift Kick them (brings the fight to you).

### Nanami — "Salaryman" (Ratio 7:3)
- **R:** marks target with a bar in tenths; a circle sweeps it — press R again EXACTLY on the red **7:3 line**
  → forcibly creates a weak point for **4.5s**.
- **Move 1:** moving meter on the enemy; re-press on 7:3 = **Black Flash** hit + knockback (else 10 dmg stun).
- **Move 2:** ground slam; re-press 2 at the right moment → rubble eruption.
- **Move 3:** Ratio Barrage. **Move 4:** dash — press 4 on EVERY 7:3 tick.
- Awakening: **Overtime** (heal 25, harder M1s, silent block).
- → `Auto Ratio` = read the on-screen ratio meter GUI and auto-press at the 7:3 mark (pure client-side GUI read = very automatable).

### Yuki — "Star Rage" (Garuda)
- Shikigami **Garuda** orbits the player. Moves incl. **Garuda Rebound**, **Garuda Stab**, Rising Rage, Mass Breaker.
- **Rebound tech:** perfect-blocking Garuda makes it REBOUND to the user; it can be parried back at the enemy.
- Air combo: Rising Rage → Garuda Rebound → jump → Mass Breaker.
- → `Auto Garuda Rebound` = detect the incoming Garuda projectile and auto-perfect-block/parry on the exact frame.

### Naoya — "Head of the Hei" (Projection Sorcery, 24 FPS)
- **Freeze Frame passive:** last hit of your M1 combo fills ~**40%** of the enemy's Projection Meter; full = frozen
  **3s**; hits during freeze deal **TRIPLE damage**.
- **R Projection Sorcery:** costs 5% awakening, teleports; vs a FROZEN target adds a 9-dmg punch.
- **Projection Breaker (move 1):** back-step → forward kick.
- → `Auto Naoya Tech` = track M1 chain to always land the combo ender, and on target-freeze auto-R + burst combo (triple damage window).

### Toji
- **Heavenly Ambush:** jump + dash elbow, 25 dmg.
- → `Auto Ambush` = auto-fire it when the target is in range / airborne.

### Megumi — "Ten Shadows" / Mahoraga
- Awakened + press **4** (40% bar) = summon **Mahoraga**. **R** cycles Attack/Defense/Special wheels.
- **Earthquake:** punch the ground (shockwave), press AGAIN during the glow → second UNBLOCKABLE shockwave.
- **World Slash** (Special wheel, 40 dmg), Divine Pummel, Ground Pitch, Takedown.
- → `Auto Earth Quake` = double-fire with the glow timing (Dream Hub already has AutoQuake).

### Gojo — "Honored One" / "Limitless"
- Base: **1 Lapse Blue** (pull), **2 Reversal Red** (ranged knockback), **3 Rapid Punches** (17.25 unblockable), Twofold Kick, **R Teleport**.
- → `Auto Reversal Red Teleport` = Red's knockback used as movement (Dream Hub has ReversalRedApi).
- → `Move TP Method: Red` = use Red's displacement on the TARGET to shove them where you want.

### The Vessel (Itadori/Sukuna)
- Ult (Sukuna): **R** = grab + throw with a black flash. 80 HP, strong awakening.

### QTE / Clash minigame
- The newer updates added **Beam Clashing** (clash mini-game); minigames are voted via pressure plates.
- → `Auto QTE Minigame Click` = find the clash/mash GUI when it appears and auto-click at `Click Delay` speed (pure client-side).

## What Dream Hub ALREADY has (no work needed)
Auto Blackflash, Auto Yuta Blackflash (anim 89582140026963, "2" twice), Auto Earthquake, Reversal Red,
Auto Parkour, Auto Ult, Auto Counter, Anti-Domain, Auto Domain Adapt, Ambush/Naoya groundwork (anims referenced).

## Implementable WITHOUT SimpleSpy captures (GUI/key timing only)
1. **Auto QTE Click** (clash GUI + VIM clicks + delay slider)
2. **Auto Ratio** (read Nanami's meter GUI, press on 7:3)
3. **Auto Swap Players / Auto Perfect Swap / Todo Bring** (R at target + timed M1 + Swift Kick)
4. **M1 Farm** (TP-behind + M1 loop vs picked target — same engine as existing farm)
5. **Target panel** (player search, Moveset/Status/Health readout, View)

## Needs a SimpleSpy capture (remote args unknown)
- **Inf Range** (fire skill remotes with the target position)
- **Move TP** (Red displacement remote on target)
- **Blackhole Lock** (Hollow Purple / blackhole aim lock)
- **Auto Todo Blackflash**, **Auto Yuta Teleport Kill Backflash**, **Auto ShutUp** (exact remotes/anims per move)

Sources: games.gg JJS character guide, JJS Fandom wiki (Switcher/Techs/Star Rage/Salaryman/Ten Shadows/Mahoraga),
Item Level Gaming Naoya guide, noleep Star Rage combos, sportskeeda Switcher guide.
