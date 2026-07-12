DREAM HUB - UPDATE LOG

===================================================================
JUJUTSU SHENANIGANS  (DreamHub_JJS / Free + Plus + VIP)   build B54
===================================================================

+ New:
  - Black Flash engine rebuilt to the clean anim-driven version: presses 3 the
    instant a Black Flash windup animation plays, instant key press, no delay.
  - M1 BF now runs the Black Flash engine AND fires on your click. Default is
    every click (BF After = 1).
  - Auto Earthquake is fully automatic: near a player or dummy it presses 3,
    holds it 2 seconds, then releases. Quake Hold and Quake Range sliders.
  - Gojo TP Back is configurable: Q Dash or After N M1s, with a Back Lock Time.
    It locks the target's back for a moment, then presses R, R and teleports.
  - Auto Rika Down Slam: near a player or dummy it down slams them.
  - Settings: Background Color, Background Image ID, Text Font, Text Color,
    Sound with a Click Sound picker (Keyboard, Goku Scream, Jesus, 67, Money)
    and a Custom Sound ID box.
  - Tab icons matched to the Ability Arena set so every tab is distinct.

~ Fixes:
  - Teleport reworked to the anti-cheat bypass method: blocks the set-back
    remote only during a teleport and never removes the anti-cheat scripts, so
    it no longer times you out. Teleport now sticks in public servers.
  - Load kick fixed: the anti-cheat is no longer disabled at load, which was
    causing a server-side 267 kick a few seconds after loading.
  - M1 BF click detection: the game sinks the M1 click so it was not being
    caught. Now a per-frame mouse poll catches the click even when the game
    consumes it.
  - Force Reset kills you without a respawn and without the camera shake.
  - Method hints removed from the labels and source so the tricks are not
    exposed.

===================================================================
ABILITY ARENA  (AbilityArena_CozyHub Free / AbilityArena_PLUS)
===================================================================

+ New:
  - Combat Pro: Legit Auto Play (holds W, dashes back on an enemy M1, then
    fights), Auto Dodge (detects enemy M1s by arm velocity and animation, then
    teleports you left or right), Instant 1v1 Win (front or back combo), and a
    stronger Aura M1.
  - God Mode is now Plus only. It teleports you onto a Map spawn from the lobby
    so you can not be hurt. A bottom-right notice shows only when you are not
    already in the lobby.
  - Separate Plus build (AbilityArena_PLUS) that adds God Mode on top of Free.

~ Fixes:
  - Fling and the click features no longer silently blocked by invisible full
    screen frames; the menu-hit check now only counts real visible panels.
  - Removed Fling Punch, One Punch, and the M1 hitbox expander.
  - Method hints removed from the toggle names.

===================================================================
PRIOR EXTINCTION  (PE_Plus_Loader / PE_NoFood_Loader)
===================================================================

+ New:
  - Fossil Collect Delay slider so Auto Farm Fossil collects at a calm pace
    instead of blinking node to node.
  - Ecosystem Teleport lists the biomes loaded around you and teleports to any.

~ Fixes:
  - Auto Farm Fossil now matches Fossil, FossilS, FossilM and FossilL parts
    under workspace.SpawnedFossils (it was only matching FossilS, so it skipped
    most fossils).
  - Auto fossil collects slow, not fast.
