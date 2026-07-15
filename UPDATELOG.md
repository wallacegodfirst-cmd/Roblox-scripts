DREAM HUB - UPDATE LOG

===================================================================
TELEPORT + INF STAM FIX PASS  (latest)
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
