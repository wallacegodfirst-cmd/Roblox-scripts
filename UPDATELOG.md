DREAM HUB - UPDATE LOG

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
  - Method hints removed from labels and source.

note: next update will bring Paid / Plus Jujutsu Shenanigans. just wait.

===================================================================
PRIOR EXTINCTION - PLUS
===================================================================

~ Fixes (this update):
  - INF Stamina is now separate from any speed boost. It only keeps the
    stamina bar full and stops the drain — the old sprint speed-keeper
    that glitched movement and "prevented progress" is gone. Use Speed
    Hack if you want extra speed.
  - INF Food no longer glues the food bar to max, which was hiding the
    eat prompt so you could not hold E to eat. It now uses the original
    herb method: it fires the eat for you to keep food high while leaving
    the prompt available, so you can hold E to eat any time.
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
