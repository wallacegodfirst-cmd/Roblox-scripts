╔══════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                       D R E A M   H U B                                    ║
║                    ——  FULL UPDATE LOG  ——                                 ║
║                                                                            ║
║       Prior Extinction  ·  Jujutsu Shenanigans  ·  Ability Arena           ║
║                                                                            ║
║              press RightShift  ·  or tap the Dream logo                    ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════╝

    Legend
    ─────────────────────────────────────────────────────────────────────
      +  new feature            ~  fixed / reworked        !  important note
      ▸  detail / sub-point     ★  a setting you control   ·  existing recap
    ─────────────────────────────────────────────────────────────────────


╔════════════════════════════════════════════════════════════════════════╗
║  TABLE OF CONTENTS                                                        ║
╚════════════════════════════════════════════════════════════════════════╝

    1 · PRIOR EXTINCTION
        1.1  Spawn & Death
        1.2  Infinite Stamina
        1.3  Infinite Food & Growth
        1.4  Infinite Water / Oxygen
        1.5  Target Tab
        1.6  Auto Farm — Fossils & Gems
        1.7  Pro Food (one-button growth)
        1.8  Movement & Combat
        1.9  Protection & Survival
        1.10 Visuals & ESP
        1.11 Interface
        1.12 Tiers, Loaders & the Speed Finder

    2 · JUJUTSU SHENANIGANS
        2.1  Teleports
        2.2  Items & Trash
        2.3  Combat & Autos
        2.4  Interface
        2.5  Free Build

    3 · ABILITY ARENA
        3.1  Auto Respawn (new)
        3.2  Auto Heal (new)
        3.3  Auto Dodge — per-player (new)
        3.4  God Mode & Combat Pro
        3.5  Tiers

    4 · ACROSS ALL HUBS

    5 · VERSION HISTORY (this pass, in order)

    6 · FAQ & TIPS

    7 · QUICK REFERENCE



╔════════════════════════════════════════════════════════════════════════╗
║  1 · PRIOR EXTINCTION                    Plus · Premium · No-Food         ║
╚════════════════════════════════════════════════════════════════════════╝

────────────────────────────────────────────────────────────────────────────
  1.1 · SPAWN & DEATH
────────────────────────────────────────────────────────────────────────────
~ THE DEATH-SPAWN LOOP is handled. If you spawn outside the map and die on
  repeat — and it happens even with NO script running — that is a corrupted
  save: you saved your dino while outside the map, so the game itself keeps
  respawning you into the void. No client script can un-write what the server
  saved, but the hub breaks the loop for you.
  ▸ After every spawn, for a short window, it checks whether you have real
    ground under you.
  ▸ A HEALTHY spawn is left 100% alone — no popup, no nudge, no camera change.
    (Earlier builds mistook tree cover overhead for "the map above you" and
    lifted you on normal forest spawns. That false-trigger is fixed.)
  ▸ A BAD spawn (under the map / falling through the void / floating over open
    ocean) is the only time it acts, and it brings you back onto real, solid
    land — never onto the water surface.
  ▸ When the game's own "Unstuck" countdown is on screen, the hub goes fully
    hands-off and lets that finish (any movement cancels that timer, so it
    stays still on purpose).
  ! Once it saves you, RE-SAVE your dino somewhere safe. That fixes the bad
    save permanently and the loop stops for good.

+ DEATH BUG FIX toggle  (Survival ▸ Protection)
  ▸ Turns the whole spawn rescue on/off.
  ▸ Auto-mutes itself during any hub teleport (map / biome / corpse / fossil)
    so it can never interfere with a teleport you asked for.

~ SPAWN SAFETY GRACE. For a few seconds after every spawn, fall-damage immunity
  is held and teleport features are blocked, so nothing can fling you into the
  void the instant you load in.

────────────────────────────────────────────────────────────────────────────
  1.2 · INFINITE STAMINA
────────────────────────────────────────────────────────────────────────────
~ NO MORE SLOW. NO MORE SNAP-BACK. This one went through several iterations and
  has settled on the clean answer: INF Stamina keeps you going by keeping the
  stat side topped up — and it does NOT touch your movement at all.
  ▸ Because nothing overrides your speed or your position, the game's movement
    checks have nothing to react to. The old rubber-banding / "it keeps sending
    me back" / "16 speed snaps me" problems all trace back to movement
    overrides — those are gone.
~ WELLBEING is pinned in the RIGHT place now. A handful of background stats
  quietly speed up how fast stamina drains (comfort, activity, nutrition,
  immunity — and toxins, which hurt you as they rise). Those live in their own
  data channel, apart from your main character data. Earlier versions were
  topping up a channel that frequently wasn't there, so the effort did nothing.
  It now targets the correct channel:
  ▸ holds the helpful stats up and toxins down, and
  ▸ keeps their "buffer" windows open so they never begin decaying in the first
    place — which is what stopped exhaustion from ever setting in.
! INF Stam is intentionally movement-free. If you want extra SPEED on top,
  that's what Speed Hack is for.

────────────────────────────────────────────────────────────────────────────
  1.3 · INFINITE FOOD & GROWTH
────────────────────────────────────────────────────────────────────────────
~ YOU CAN EAT AGAIN. Forcing the food bar to full made the game think you were
  stuffed — which hides the eat prompt and blocks your E key. INF Food now only
  keeps the bar off the floor, leaving headroom so the prompt shows and manual
  eating works all the way up.
~ E-PROTECTION. While you hold E — and for a few seconds after you let go — the
  hub keeps its hands entirely off your food, so a manual bite is never
  interrupted or overwritten mid-eat.
~ DIET-AWARE. INF Food reads your dino's diet and only counts food that
  actually matches it. Eating the wrong food tanks hidden wellbeing stats, and
  that was the sneaky reason INF Stam used to "break" whenever INF Food was on.
  Matching the diet keeps both healthy.
~ MAP-WIDE. It keeps you fed and growing whether you're standing on food or
  not, so you can grow without walking the map.
★ GROWTH SPEED slider ("INF Food grow speed", 1–10). Growth is driven
  independently of the visible bar level, so higher = faster growth.
! On-screen INF Food messages are intentionally short — "Active." once it's
  running, or "Eat any food once to activate." while it's still warming up.
  Just enough to know the state, nothing more.

  New this pass (Plus):
  + Auto Play, Pro Food, Corpse TP Food.
  + Fossil Collect Delay slider (see 1.6).
  + Ecosystem Teleport that lists the biomes loaded around you.

────────────────────────────────────────────────────────────────────────────
  1.4 · INFINITE WATER / OXYGEN
────────────────────────────────────────────────────────────────────────────
~ INF WATER NO LONGER BLOCKS EATING. It used to press E on its own several
  times a second to "drink"; that key spam was cancelling your manual
  hold-to-eat. Removed — water now tops up quietly with no key presses at all.
· INF Oxygen holds your on-land breathing state, so being underwater doesn't
  drain your air.
· Anti-Drown lifts you to the surface when needed.
  ★ Anti-Drown Rise slider — how fast it lifts you (lower is smoother on weaker
    devices).

────────────────────────────────────────────────────────────────────────────
  1.5 · TARGET TAB              (type a username → act on that player)
────────────────────────────────────────────────────────────────────────────
~ IT ALWAYS LOADS NOW. The tab used to disappear entirely under certain
  loaders; that gate is gone, so the Target tab is always present.
~ TYPING A NAME WORKS. The name box registers what you type immediately — the
  old behaviour only saved on Enter, so typing a name and hitting Load right
  away checked an empty box and said "not found". Fixed.
~ THEIR DINO ACTUALLY LOADS. Other players' dinos aren't labelled with their
  username the way your own is, so the old lookup couldn't find them. It now
  identifies a player's dino by every reliable signal available, and — once
  they've been seen — pulls their area in so a far-away target still loads
  without you walking over there.
~ PROFILE READOUT — User, Dino, Stage, Gender, Health, Distance and a live
  Status line, refreshed every second using the same reader the ESP uses. The
  Target profile can never show less than ESP already does.
~ VIEW / SPECTATE FIXED. It did nothing after you'd died once (it was holding a
  stale camera). It now takes a fresh camera every frame and follows the
  target's dino from behind-and-above, framed to their size — an Elder and a
  hatchling both sit nicely in frame. Press again to stop; the camera hands
  straight back to you (also if the target vanishes).
~ ACTIONS wired to the live model: Teleport to Player, Track (marker +
  distance), Attack Once, and Auto Farm Player (keeps hitting them, TPs to them
  if they run — ★ Farm Range and ★ Hits/sec sliders).
! If a profile still reads "--", the game simply hasn't sent that player's dino
  to your client yet (they're too far). Get closer or use ESP and it fills in.

────────────────────────────────────────────────────────────────────────────
  1.6 · AUTO FARM — FOSSILS & GEMS
────────────────────────────────────────────────────────────────────────────
~ AUTO FARM FOSSIL is instant again — it teleports straight onto each fossil,
  holds long enough to collect, then moves to the next, so it hits EVERY fossil
  instead of skipping most of them.
~ ALL FOSSIL SIZES are matched now (it used to only catch the small ones, which
  is why it "missed most").
★ FOSSIL COLLECT DELAY slider — set the pace between fossils so it collects at
  a calm, steady rate instead of blinking node to node.
~ GEMS keep their steadier approach — a gem takes longer to collect, so the
  calmer path is the reliable one there.
~ FOSSIL vs GEM no longer get confused — fossil mode won't wander onto gems, and
  gem mode won't grab fossils.
~ A live counter shows how many fossils / gems you've collected while farming.
· Teleport-to-nearest-gemstone button, and the farm returns you to where you
  started when you turn it off.

────────────────────────────────────────────────────────────────────────────
  1.7 · PRO FOOD  (one-button growth farmer)
────────────────────────────────────────────────────────────────────────────
~ CIRCLE MOVEMENT FIXED — both directions:
  ▸ ON  — you now genuinely trace a circle to grow. The old version only walked
    you diagonally in a straight line, so you never actually circled.
  ▸ OFF — turning it off stops you instantly. The old version could leave you
    "walking on your own" because a movement key never got released.
~ "I MOVE LIKE PRO FOOD SOMETIMES" — solved. Confirming a corpse on the
  corpse-TP popup used to silently switch Pro Food ON (and start the circling).
  It no longer does that; Pro Food starts ONLY from its own Growth-tab toggle.
· What it does: TP to a safe corpse with no dinos nearby → eat until full →
  circle to grow → move to the next corpse → stop at the age you pick.
  ★ Stop-at-age dropdown.

────────────────────────────────────────────────────────────────────────────
  1.8 · MOVEMENT & COMBAT
────────────────────────────────────────────────────────────────────────────
· Fly (with mobile ▲ / ▼), Speed Hack, Infinite Jump, Noclip.
· Float — holds you steady in the air.
· Turn Hack with an adjustable turn speed.
· Aimbot / Silent Aim / Lock On, Hitbox expander, Always Damage.
· God-tier PvP helpers land the game's real swings so hits register.

────────────────────────────────────────────────────────────────────────────
  1.9 · PROTECTION & SURVIVAL
────────────────────────────────────────────────────────────────────────────
· Anti-Drown, Walk on Water, Anti-Fall.
· Bone protectors (head / neck / leg / tail / torso) — and while any is on,
  your health is kept topped so a big hit is refilled instead of dropping you.
· Anti-Bleed / Anti-Fracture clear the status effects that would otherwise force
  you to sleep them off.
· Save Dino, Rejoin / Server Hop, Safe Teleport.

────────────────────────────────────────────────────────────────────────────
  1.10 · VISUALS & ESP
────────────────────────────────────────────────────────────────────────────
· Creature + Player ESP with species, stage, health, stamina and distance.
· Plant / Fish / Gem-and-Fossil ESP.
· Full Bright, No Night, INF Light, INF Zoom, water clarity, tree removal.
~ ESP is throttled and capped so it stays smooth — a heavy scan can no longer
  lag you out or take the menu down, and it falls back quietly on any error.

────────────────────────────────────────────────────────────────────────────
  1.11 · INTERFACE
────────────────────────────────────────────────────────────────────────────
+ DREAM LOGO BUTTON — the floating open/close button is now the Dream logo in
  clean black & white. Until the image loads it shows a white "DREAM" so it's
  never a blank circle.
  ▸ On ALL devices now (was mobile-only): tap to open/close the menu, drag to
    move it out of the way. PC can still use RightShift.
~ Mobile fly ▲ / ▼ buttons stay on touch devices only.
· Skins tab, colour / font / background settings, keybind rebinding, config save.

────────────────────────────────────────────────────────────────────────────
  1.12 · TIERS, LOADERS & THE SPEED FINDER
────────────────────────────────────────────────────────────────────────────
+ TWO PAID LINKS, each with its own loader:
  ▸ Plus     — Target tab + Auto Farm Player and the full core hub.
  ▸ Premium  — everything in Plus, plus the Premium-only extras.
  ▸ (Note: an earlier Plus link accidentally unlocked Premium too — that's
    corrected; Plus is genuinely Plus now.)
~ Every loader validates the download and retries across mirrors, so a bad
  executor cache can't quietly hand you the wrong file — and it says so plainly
  if it does.
+ PE SPEED FINDER (separate script) — a small HUD showing your live speed. Tap
  Shift to record a number (it copies to your clipboard so you can send it), and
  it auto-flags any snap-back with the exact speed you were doing when it hit.
  Great for dialing things in on any server.



╔════════════════════════════════════════════════════════════════════════╗
║  2 · JUJUTSU SHENANIGANS                          Free · Full            ║
╚════════════════════════════════════════════════════════════════════════╝

────────────────────────────────────────────────────────────────────────────
  2.1 · TELEPORTS
────────────────────────────────────────────────────────────────────────────
~ TELEPORTS REBUILT. Every teleport in the hub — named locations, players,
  saved slots, Target, Auto Farm — now travels to the destination and STICKS,
  instead of getting bounced back.
  ▸ BUILDING AVOIDANCE — if something solid sits between you and the target, it
    routes up and over rather than grinding into the wall, then comes down onto
    the spot.
  ▸ CLEAN LANDINGS — an earlier build had a bug that tripped at the end of every
    trip, so you didn't land cleanly and could be left unable to pass through
    things you should. Fixed: landings are exact and everything returns to
    normal afterward.
  ▸ NO FIGHTING — rapid back-to-back teleports (sword spam, chained blinks) no
    longer battle each other; the newest one always wins.
! Teleports / Target / Auto Farm currently carry an in-app note:
  "🏗️ In fixing + kind of works". That means the new method is live but still
  being hardened — leave the note on until it's marked done.

────────────────────────────────────────────────────────────────────────────
  2.2 · ITEMS & TRASH
────────────────────────────────────────────────────────────────────────────
~ TRASH THROW now genuinely PICKS UP the trash first, confirms it's in your
  hand (retrying if the first grab didn't take), then throws it at your target.
  If there's no loose trash around, it clicks the nearest trash can to get some.
  No more "throwing" with empty hands.
~ ITEM GRAB is more reliable — it verifies the pickup actually landed instead of
  assuming it did.
· Item ESP with clean distance pills; Auto Grab with a filter and a live list.

────────────────────────────────────────────────────────────────────────────
  2.3 · COMBAT & AUTOS
────────────────────────────────────────────────────────────────────────────
· M1 Black Flash + Auto Black Flash, Auto Earthquake (holds the charge for you),
  Gojo TP-back, Auto Rika down-slam, Auto Slam / Uppercut / Air, Domain Adapt.
· Auto Farm, Auto Train, Auto Parkour, Auto QTE.
· Anti Ragdoll / Stun / Domain / Counter, Auto Counter.
· Full ESP: chams, names, health, distance, boxes, tracers.
· Force Reset with no respawn shake.

────────────────────────────────────────────────────────────────────────────
  2.4 · INTERFACE
────────────────────────────────────────────────────────────────────────────
~ LOGO FIXED. The floating logo button was showing as a blank purple circle
  when the image failed to load. It's now a finished-looking badge from the very
  first frame — gradient, ring and "DREAM" text — with the real logo fading in
  on top only once it has actually loaded. No blank circle in any case.
· Draggable minimize button; background colour / image, fonts, sound pack.

────────────────────────────────────────────────────────────────────────────
  2.5 · FREE BUILD
────────────────────────────────────────────────────────────────────────────
+ JJS FREE — available directly, and behind a link gate (complete the link, then
  get the script). Red & black theme, trimmed but loaded feature set. Auto
  Uppercut / Down Slam and Auto Air are included; a few advanced autos are
  Full-only.



╔════════════════════════════════════════════════════════════════════════╗
║  3 · ABILITY ARENA                       Free · Plus · Premium           ║
╚════════════════════════════════════════════════════════════════════════╝

────────────────────────────────────────────────────────────────────────────
  3.1 · AUTO RESPAWN   (Plus + Premium)   — NEW
────────────────────────────────────────────────────────────────────────────
+ The instant you die and respawn, it deploys you straight back into the fight —
  no sitting in the lobby.
  ▸ Clean on/off toggle; turning it off drops the auto-deploy immediately.
  ▸ Included in BOTH paid tiers.

────────────────────────────────────────────────────────────────────────────
  3.2 · AUTO HEAL   (Plus ONLY)   — NEW
────────────────────────────────────────────────────────────────────────────
+ One button restores you to full health and puts you back exactly where you
  were standing.
  ! It will NOT work while you're in PvP / combat — you get a clear notice
    telling you to get out of combat and try again, instead of it silently
    doing nothing.
  ▸ Plus-tier only — Premium does NOT include Auto Heal, by design.
  ▸ Notifications are deliberately vague about how it works.

────────────────────────────────────────────────────────────────────────────
  3.3 · AUTO DODGE — PER-PLAYER   — NEW
────────────────────────────────────────────────────────────────────────────
+ DODGE PLAYER dropdown — choose WHO Auto Dodge reacts to:
  ▸ "All"            → dodge any attacker (default).
  ▸ a specific name  → dodge ONLY that player, ignore everyone else.
+ "Refresh Dodge List" button, and the list updates itself as players join /
  leave.
~ The filter is applied at the source, so a non-selected player's attack won't
  even trigger a dodge.

────────────────────────────────────────────────────────────────────────────
  3.4 · GOD MODE & COMBAT PRO
────────────────────────────────────────────────────────────────────────────
· GOD MODE (Plus): a lobby-state trick that TPs you into the fight untouchable.
  Trade-off of the trick itself: you can't M1 in that state, so pair it with
  abilities.
· Combat Pro: Legit Auto Play, Instant 1v1 Win (front / back), stronger Aura M1.
· Save Health (fly up, heal, drop back), M1 Warp, Auto Ability (E / Q / R / T).
~ Fling / click features no longer blocked by invisible fullscreen frames.

────────────────────────────────────────────────────────────────────────────
  3.5 · TIERS
────────────────────────────────────────────────────────────────────────────
  ▸ Free     — the core hub.
  ▸ Plus     — + God Mode, Auto Heal, and the rest.
  ▸ Premium  — everything in Plus EXCEPT Auto Heal, plus Premium extras.
  ▸ Auto Respawn and per-player Auto Dodge are in both paid tiers.



╔════════════════════════════════════════════════════════════════════════╗
║  4 · ACROSS ALL HUBS                                                     ║
╚════════════════════════════════════════════════════════════════════════╝
~ QUIET, SAFE NOTIFICATIONS. On-screen messages across every hub were trimmed so
  they tell you the STATE of a feature without spelling out how it works — this
  keeps the good stuff from being easy to copy or patch.
~ STABILITY. Heavy scans (ESP, item lists) are throttled and hard-capped so they
  can't lag you out or take the menu down; anything that fails falls back quietly
  instead of crashing the script.
~ HARDENED LOADERS. Every script comes through a loader that validates the
  download, retries across mirrors, and tells you clearly if your executor hands
  back a corrupted copy — so you never end up running someone else's garbage by
  accident.
~ RESPAWN-PROOF. Features re-apply themselves after you die / respawn instead of
  silently switching off.



╔════════════════════════════════════════════════════════════════════════╗
║  5 · VERSION HISTORY  (this pass, most recent first)                     ║
╚════════════════════════════════════════════════════════════════════════╝

  ▸ AA — Auto Heal moved to Plus-only; Auto Dodge gains a per-player dropdown.
  ▸ AA — Auto Respawn added to both paid tiers.
  ▸ PE — Infinite Stamina reworked to the movement-free, wellbeing-correct
         approach (the current "no slow, no snap" version).
  ▸ PE — Dream logo button (black & white) on all devices; INF Food toasts
         shortened.
  ▸ PE — Death Bug Fix toggle; spawn rescue made Unstuck-aware and land-only.
  ▸ PE — Target tab: name box, other-players' dino lookup, live View camera.
  ▸ PE — Food eating unblocked (bar kept low, E protected); INF Water E-spam
         removed.
  ▸ PE — Spawn rescue first version (void / under-map / ocean recovery).
  ▸ JJS — Teleports rebuilt with building avoidance; landing bug fixed.
  ▸ JJS — Trash: real pick-up + confirm + throw, with trash-can fallback.
  ▸ JJS — Logo fixed (no more blank circle).
  ▸ PE — Auto Fossil instant TP; Pro Food circle fixed; Target tab ungated.
  ▸ ALL — notification wording tightened across the board.

  (Older history is preserved in the repository commit log.)



╔════════════════════════════════════════════════════════════════════════╗
║  6 · FAQ & TIPS                                                          ║
╚════════════════════════════════════════════════════════════════════════╝

  Q · I still spawn outside the map and die.
  A · That's a corrupted save from before. Let the rescue (or the game's Unstuck
      timer) put you back on land, then RE-SAVE your dino somewhere safe. The
      loop stops after that.

  Q · INF Stam felt slow before — is it fixed?
  A · Yes. It no longer touches your movement at all, so there's nothing to slow
      or snap you. Want extra speed on top? Turn on Speed Hack.

  Q · INF Food is on but I can't press E to eat.
  A · Update to the latest build. Food is now kept LOW (not full), so the eat
      prompt and your E-hold both work; and while you hold E the hub leaves your
      food alone.

  Q · Target says "dino not loaded / not visible".
  A · The game hasn't sent that player's dino to you yet because they're too far.
      Get closer, or use ESP to spot them, and the profile fills in.

  Q · A JJS teleport shows "In fixing + kind of works".
  A · That's expected — the new teleport method is live but still being
      hardened. It travels and lands; the note comes off once it's fully signed
      off.

  Q · Which Ability Arena tier has what?
  A · Auto Respawn — both paid tiers. Auto Heal — Plus only. Per-player Auto
      Dodge — both paid tiers.

  Tips
  ▸ On Prior Extinction, tap the Dream logo (or RightShift) to open the menu.
  ▸ Use the Speed Finder if you want to see your live speed and log snap-backs.
  ▸ Keep INF Food's diet-matching in mind — eating the wrong food is what used
    to knock stamina around; matching your diet keeps everything smooth.



╔════════════════════════════════════════════════════════════════════════╗
║  7 · QUICK REFERENCE — WHAT GOT FIXED THIS PASS                          ║
╚════════════════════════════════════════════════════════════════════════╝

  PRIOR EXTINCTION
    death-spawn loop  ·  INF Stam slow / snap-back  ·  eating & E blocked  ·
    INF Water E-spam  ·  Target tab load + name box + dino lookup + View  ·
    Auto Fossil (instant, all sizes)  ·  Pro Food circle  ·  Dream logo  ·
    Death Bug Fix toggle  ·  Speed Finder tool

  JUJUTSU SHENANIGANS
    teleports (all)  ·  building avoidance  ·  clean landings  ·
    trash pick-up + throw + can fallback  ·  logo

  ABILITY ARENA
    Auto Respawn (both tiers)  ·  Auto Heal (Plus only)  ·
    per-player Auto Dodge


                ──  press RightShift, or tap the Dream logo  ──
                              enjoy.  —  Dream Hub
