DREAM HUB - UPDATE LOG

===================================================================
JJS TELEPORT FIXED + PE STAM/FOOD/TARGET PASS  (latest)
===================================================================

JUJUTSU SHENANIGANS
~ TELEPORT FIXED for real: the flight engine was erroring at the end of
  every leg (a leftover from the noclip refactor), so the landing never
  ran and your collision never restored. Fixed — flights land exactly on
  target and collisions always come back. The position lock also idles
  during the flight now, so low-FPS clients don't get their flight
  velocity zeroed mid-air.

PRIOR EXTINCTION
~ TARGET: "user not in game" fixed — the textbox only saved on Enter,
  so typing a name and clicking Load straight away checked an EMPTY
  string. Load now reads the live textbox value directly.
~ INF WATER no longer blocks eating — it pressed E every 0.6s and the
  synthetic key-release kept cancelling your manual hold-to-eat ("the
  E thing is spamming"). The Sip remote alone fills water now; E is
  never touched.
~ INF STAM truly no-slow, no-glitch: a WalkSpeed keeper learns your
  dino's real sprint speed and reverts the server's exhaustion clamp
  every frame — pure WalkSpeed, zero velocity writes, so nothing can
  rubber-band. The velocity drive stays available behind the optional
  "Run Speed Drive" toggle.
~ TARGET TAB ALWAYS LOADS — the Plus gate made the whole tab vanish
  when the tier flag wasn't set (that's why "Target doesn't load").
  The tab and everything in it (View, Track, Teleport, Attack, Auto
  Farm Player) now builds for every loader.
~ INF STAM NO LONGER TOUCHES YOUR MOVEMENT. The velocity drive was
  fighting PE's server-side movement anti-cheat = the rubberbanding /
  "all the bugs". Plain INF Stam now ONLY keeps the bar full. The
  speed drive still exists as an optional "Run Speed Drive" toggle
  (off by default) for those who want it.
~ INF FOOD — BETTER, STRONGER, ALWAYS GROWS: the food bar is now
  pinned to 100% while INF Food is on (max passive growth), and the
  Bite spam finally obeys the "INF Food grow speed" slider — each
  captured Bite remote fires 1-10x per pass (slider), on a faster
  0.1s loop, capped so it can't lag. Note: the game may hide the
  hold-E eat prompt while the bar reads full — growth comes from the
  Bite spam, so you don't need E anymore.

ABILITY ARENA
~ Auto Heal notifications reworded: they no longer reveal how the
  heal works — just "won't work in PvP", "not available yet", and
  "Healed — full HP".

===================================================================
DEEP VERIFY PASS + TRASH THROW + AA PREMIUM  (latest)
===================================================================

JUJUTSU SHENANIGANS
~ Throw Trash At User actually picks the trash up now — and clicks it.
  The grab fires the trash's ClickDetector AND lands a real mouse click
  on it (plus touch / prompt / E), then VERIFIES you're holding it and
  retries up to 3 times. If there's no loose trash it finds the nearest
  TRASH CAN, clicks the can to get trash out, and grabs that. The throw
  itself was clicking screen corner (0,0) = threw nothing — it now
  clicks screen center, the same fix Auto Farm's M1 needed.
~ Deep verify pass over the whole hub (6 parallel reviewers + trace
  checks). Confirmed + fixed:
  - Overlapping teleports (e.g. Rika sword spam) corrupted the noclip
    save/restore — the old flight re-solidified you mid-flight of the
    new one, or left you permanently noclipped. One shared save-list
    now; only the current teleport's landing restores collisions.
  - The position-lock could fight the velocity flight on low-FPS
    clients (re-pin + velocity zero every frame). Lock is now off
    during flight — the flight self-corrects every frame — and
    re-engages at the exact target on landing.
  - The Target module's item search was silently calling a function
    from another module (always failed, fallback masked it). Resolved
    inline now.
  - Teleport engine, UI wiring, logo button, labels, Target module,
    auto farm loop and all loaders traced clean.
~ Notes updated to "🏗️ In fixing + kind of works" on Teleports, Target
  and Auto Farm.

ABILITY ARENA
+ AUTO HEAL (Plus + Premium): one button — hops you to the lobby,
  instantly re-deploys, and puts you back on the exact spot you were
  standing, with full health. Shows a clear notification that it WON'T
  WORK IN PVP (the game blocks the lobby hop while you're in combat)
  instead of silently doing nothing.
+ PREMIUM build added (AbilityArena_PREMIUM.lua) — everything in Plus,
  plus Premium-only features as they land.

PRIOR EXTINCTION
~ Deep verify pass (Target tab, INF Stam drive, Pro Food circle, fossil
  farm, loaders — all traced clean end-to-end). One bug found + fixed:
  the farm counter counted every collected fossil/gem TWICE (the
  notification bar showed double). Collection itself was fine.

===================================================================
JJS VELOCITY TELEPORT + LOGO, PE INF STAM NO-SLOW
===================================================================

JUJUTSU SHENANIGANS
~ TELEPORT REBUILT on the velocity method: instead of writing CFrames,
  you are pushed to the target with plain physics velocity every frame —
  the server just watches you move, so there is nothing for it to
  reject. Your own collision is off during the flight (restored after),
  and when a building blocks the straight line you fly UP 400 studs
  first, then dive to the target. Exact landing at the end. Applies to
  every teleport (locations, players, slots, Target, Auto Farm) — one
  engine.
~ 🏗️ "In fixing" notes added while the new method is tested: on the
  Teleports tab, the Target tab (teleports) and Auto Farm (teleport).
~ LOGO FIXED: the floating button was a blank purple circle when the
  logo image failed to load. It is now a proper gradient badge with a
  white ring and DREAM across it from the first frame, and the real
  logo image fades in on top only once it has actually loaded.

PRIOR EXTINCTION (Plus)
~ INF Stam is NO LONGER SLOW on big dinos. Capping the drive at the
  12-15 slider band made anything whose real sprint is faster than 15
  feel sluggish. The drive now uses the slider OR your dino's own
  sprint WalkSpeed, whichever is higher — the game granted that speed,
  so the server accepts it, and the position reporting keeps it from
  snapping. The learned sprint resets whenever your dino changes, so a
  rex's speed never leaks onto a hatchling.

===================================================================
TARGET TAB REWORK + SPEED DECIMALS + PRO FOOD CIRCLE
===================================================================

PRIOR EXTINCTION
~ TARGET TAB REWORKED (was: nothing worked). The root cause: in the
  Fluent menu every profile row was silently a dead stub, so Load ran
  but nothing could ever display. Profile rows are real now in both
  menus and show User, Dino, Stage, Gender, Health, Distance and a
  Status line, refreshed live every second. Load tells you when the
  player is found but their dino isn't streamed in yet (the profile
  fills in as soon as it is), and there's an Unload button.
~ View Player actually works now. Setting the camera subject did
  nothing because PE's camera scripts fight it back — viewing now takes
  the camera over completely and follows their dino from behind-above
  every frame, scaled to the dino's size. Press again to stop; the
  camera hands straight back to your dino (also on target loss).
~ Run Speed slider now has DECIMALS (0.1 steps) across the 12-15 band,
  so you can dial in the exact best speed (e.g. 14.7).
+ NEW: PE_SpeedFinder.lua (separate script) — shows your LIVE speed on
  a HUD; press SHIFT to record the current number (log copies to your
  clipboard so you can paste it back to support). Snapbacks are logged
  AUTOMATICALLY with the speed you were running when the server yanked
  you, so the tolerated max finds itself.
~ Pro Food circle fixed both ways. ON: the old W+D key-hold only walked
  you diagonally in a straight line — the circle is now a rotating-
  heading walk (slow speed, reported on the game's own move remote) so
  you genuinely go in a circle. OFF: the fake key-holds could stick and
  keep you walking forever — turning Pro Food off now hard-stops the
  circle immediately (keys released unconditionally + velocity zeroed).

===================================================================
GLIDE ROUTING + SPEED BAND + FOSSIL INSTANT TP
===================================================================

JUJUTSU SHENANIGANS
~ Glide teleports now route AROUND buildings. A straight glide into a
  building ground you along the wall — the glide now raycasts the path
  first and, if something solid is in the way, bends the route like a
  real player would move: via a known location from the Teleports tab
  list (those coordinates double as safe waypoints), or a left/right
  sidestep, or up-and-over at rising heights, with a high cruise + drop
  as the last resort. Works for every teleport in the hub (one engine).

PRIOR EXTINCTION
+ TWO BUILDS, TWO LINKS: PE Plus (PE_Plus_Loader.lua) and PE Premium
  (PE_Premium_Loader.lua). Plus = Target tab + Auto Farm Player;
  Premium = everything in Plus plus the Premium-only features.
~ INF Stam speed no longer sends you back. Two causes fixed: (1) 16 was
  still above what the server tolerates, so the Run Speed slider is now
  the safe 12-15 band (14 default; old saved values outside the band are
  reset to 14) and the drive never goes a stud above the slider; (2) while
  it drives you it now reports your position ~10x/s through the game's
  own move remote (the same CFrame channel the teleports use), so the
  server's copy of you follows along instead of yanking you back.
~ Auto Farm Fossil is INSTANT again — teleport, not glide. It snaps you
  straight onto each fossil and beats the rubber-band by feeding the
  server the goal on its own move remote for ~1.2s (re-asserting only if
  you get shoved), so there is no slow walk between fossils. Gems keep
  the glide (their long channel doesn't care and it's proven to stick).

===================================================================
TELEPORT + INF STAM FIX PASS
===================================================================

JUJUTSU SHENANIGANS
~ Every teleport now uses the GLIDE method (default). One instant snap
  read as impossible speed and got you set back — so regular teleports,
  Teleport to Player, Nearest/Up/Spawn, saved slots, Auto Grab item TP,
  and the Target teleport all now walk you to the spot in small
  believable hops and fire the anti-cheat "legit teleport" pass on every
  hop, so it sticks. All of these route through one engine, so the fix
  covers every teleport in the hub at once.
  · Fixed the hidden bug where the position-lock snapped you straight to
    the end of the glide (it now follows the glide instead of fighting it).
  · Method is Glide by default; Instant / Auto still selectable in code.

PRIOR EXTINCTION
~ INF Stamina no longer makes you slow. Pinning WalkSpeed did nothing
  (the server reverts it), so exhaustion kept holding you at walk speed.
  It now drives your real run speed while you move — same proven method as
  Speed Hack, just at your running speed, never below the game's own
  sprint. New "Run Speed" slider under INF Stamina (Survival tab).
~ Auto Farm Fossil now teleports to EVERY fossil. The instant snap was
  getting rubber-banded, so you never actually landed on the fossil and it
  got skipped — it now glides onto each one (anti-snapback) and waits to
  arrive before collecting, so every fossil gets picked up. Applies to the
  No-Food build too.

===================================================================
JUJUTSU SHENANIGANS - FREE  (finally out after a long wait)
===================================================================

+ NEW GAME ADDED: Jujutsu Shenanigans (Dream Hub Free). After a long time in
  the works, the Free build is finally here, and it is loaded.

+ Features (15+ and more inside):
  - M1 Black Flash: on your M1 it presses 3 for you = the flash.
  - Auto Black Flash: presses 3 on the Black Flash windup automatically.
  - Auto Earthquake (Free): it never presses 3 on its own. You press 3,
    and it holds 3 for you for the full charge (Quake Hold slider, 2s
    default), then releases the shockwave. The key is re-asserted the
    whole time so lifting your finger early can not drop the charge.
  - Gojo TP Back: Q Dash or After N M1s, locks the back then R, R and teleport.
  - Auto Rika Down Slam near a player or dummy.
  - Auto Slam / Uppercut, Auto Air, Auto Domain Adapt.
  - Feint M1 and Feint Abilities.
  - Teleport: named locations, teleport to any player, save and go slots,
    up / spawn / nearest, anti-cheat bypass so it sticks in public servers.
  - Force Reset with no respawn and no camera shake.
  - Movement: Fly, Speed, Infinite Jump, No Dash Cooldown, Auto Parkour.
  - Auto Farm, Auto Grab items, Auto Train, Drink Low HP.
  - Target profile lookup, Bring Item To User, Throw Trash At User.
  - Anti Ragdoll, Anti Stun, Anti Domain, Anti Counter, Auto Counter.
  - Full ESP: chams, names, health, distance, boxes, tracers.
  - Settings: background color, background image, text font and color, and a
    Sound pack (Keyboard, Goku Scream, Jesus, 67, Money) plus custom sound id.

~ Fixes:
  - Load kick fixed: the anti-cheat is no longer disabled at load.
  - Teleport now sticks in public servers.
  - M1 detection: the game sinks the M1 click, so M1 is now detected by the
    game remote instead. It fires even when the click is consumed.
  - Earthquake trigger fires on your key press (not release), so there is
    no lag between pressing 3 and the hold starting.
  - M1 Black Flash is now its own toggle (not only a Mode dropdown entry).
    The dropdown could silently fail to turn it on; the toggle always does.
  - Auto Black Flash now uses the same universal M1 detection as M1 BF, so
    it fires on every character's M1 windup instead of only a few known
    animations.
  - Teleport rebuilt as a zero-lag bypass: the anti-cheat remotes are
    destroyed (dummies left so nothing crashes) and the anti/detect
    scripts disabled, so a single instant teleport sticks with no
    rubberband and no per-frame stepping lag. Re-applied after respawn.
    The old TP Step / TP Method controls were removed (no longer needed).
  - The external menu library is now loaded defensively: if that
    third-party source is broken it fails silently to the built-in menu
    instead of printing a ":1:" compile error.
  - Method hints removed from labels and source.

note: next update will bring Paid / Plus Jujutsu Shenanigans. just wait.

===================================================================
PRIOR EXTINCTION - PLUS
===================================================================

~ Fixes (this update):
  - INF Food is now diet-aware. It reads your dino's diet (herbivore,
    carnivore or omnivore) and only eats the food that matches. Eating the
    wrong food was tanking the hidden Comfort stat, which the game turns
    into a big stamina drain — that is why INF Stamina "broke" whenever
    INF Food was on. It also scans the whole map and eats the right food
    from anywhere, so you keep growing without moving.
  - INF Stamina now also pins the Wellbeing stats (Comfort, Activity,
    nutrition, immunity; Toxins to zero) that gate the stamina drain, so
    it holds even with INF Food on. It stays fully separate from any speed
    boost — real sprint speed only, no glitching. Use Speed Hack for extra
    speed.
  - INF Food keeps the bar up whether you eat or not, and never pins it to
    max, so the eat prompt stays visible and you can still hold E to eat.
  - Every place that touched a food prompt now restores its hold time and
    range afterward, and the gem/fossil farm no longer sends an E release
    that cancelled a manual eat.

+ New:
  - Auto Play.
  - Pro Food.
  - Corpse TP Food.
  - Fossil Collect Delay slider so Auto Farm Fossil collects at a calm pace.
  - Ecosystem Teleport lists the biomes loaded around you.

~ Fixes:
  - Auto Farm Fossil now matches Fossil, FossilS, FossilM and FossilL parts
    under workspace.SpawnedFossils (was only FossilS, so it skipped most).
  - Auto fossil collects slow, not fast.

===================================================================
ABILITY ARENA  (Free / Plus)
===================================================================

+ New:
  - Combat Pro: Legit Auto Play, Auto Dodge, Instant 1v1 Win (front or back),
    stronger Aura M1.
  - God Mode is Plus only; teleports you onto a Map spawn from the lobby. A
    bottom-right notice shows only when you are not already in the lobby.
  - Separate Plus build.

~ Fixes:
  - Fling and click features no longer blocked by invisible fullscreen frames.
  - Removed Fling Punch, One Punch, and the M1 hitbox expander.
  - Method hints removed from the toggle names.
