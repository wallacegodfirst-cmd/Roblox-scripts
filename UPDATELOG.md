╔══════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                        D R E A M   H U B                                   ║
║                     — FULL UPDATE LOG —                                     ║
║                                                                            ║
║        Prior Extinction · Jujutsu Shenanigans · Ability Arena              ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════╝

Legend:   + new feature      ~ fixed / reworked      ! important note
          ▸ detail           ★ tuning knob you control

════════════════════════════════════════════════════════════════════════════
  1 · PRIOR EXTINCTION            (Plus / Premium / No-Food)
════════════════════════════════════════════════════════════════════════════

────────────────────────────────────────────────────────────────────────────
  SPAWN & DEATH
────────────────────────────────────────────────────────────────────────────
~ THE DEATH-SPAWN LOOP is handled. If you spawn outside the map and die on
  repeat — even with NO script running — that is a corrupted save: you saved
  your dino while outside the map, so the game itself keeps respawning you in
  the void. The hub now steps in.
  ▸ For a window after every spawn it checks whether you actually have solid
    ground under you. A normal spawn is left completely alone — no popup, no
    movement, nothing.
  ▸ Only when you genuinely have no footing (under the map / in the void / over
    open ocean) does it act: it brings you back onto real land, and when the
    game's own "Unstuck" timer is counting down it steps back entirely and lets
    that finish (moving cancels that timer, so the hub stays still).
  ! After it saves you, RE-SAVE your dino somewhere safe. That repairs the bad
    save for good and the loop stops happening.
+ DEATH BUG FIX toggle (Survival ▸ Protection) — the spawn rescue is now
  on/off. It also mutes itself automatically during any hub teleport (map /
  biome / corpse / fossil), so it can never fight a teleport you asked for.
~ Spawn safety: fall-damage immunity and a teleport-block grace are held for a
  few seconds after every spawn, so nothing can throw you into the void the
  instant you load in.

────────────────────────────────────────────────────────────────────────────
  INFINITE STAMINA
────────────────────────────────────────────────────────────────────────────
~ NO MORE SLOW, NO MORE SNAP-BACK. This one went through several rounds and
  has landed on the clean approach: INF Stamina now keeps you going PURELY by
  keeping the stat data topped up — it does not touch your movement at all.
  ▸ Because nothing overrides your speed or position, the game's movement
    checks have nothing to react to. That was the whole cause of the old
    rubber-banding / "it keeps sending me back" — gone.
~ WELLBEING is now pinned in the RIGHT place. The stats that secretly speed up
  your stamina drain (comfort, activity, nutrition, immunity, toxins) live in
  their own data channel, separate from your main character data. Earlier
  versions were topping up a channel that often wasn't even there, so the pin
  did nothing. It now targets the correct channel and holds those stats up
  (and toxins down), plus keeps their "buffer" windows open so they never start
  decaying in the first place — which is what kept exhaustion from ever kicking
  in.
! If you want extra SPEED (not just no-slow), use Speed Hack — INF Stam is
  deliberately movement-free now.

────────────────────────────────────────────────────────────────────────────
  INFINITE FOOD  /  GROWTH
────────────────────────────────────────────────────────────────────────────
~ YOU CAN EAT AGAIN. Forcing the food bar to full made the game think you were
  stuffed, which hid the eat prompt and blocked your E key. INF Food now only
  keeps the bar off the floor, leaving plenty of headroom so the prompt stays
  and manual eating works all the way up.
~ E-PROTECTION. While you hold E — and for a few seconds after — the hub keeps
  its hands off your food entirely, so a manual bite is never interrupted or
  overwritten mid-eat.
~ INF WATER no longer blocks eating. It used to press E on its own every
  fraction of a second; that key spam was fighting your manual hold-to-eat.
  Removed — water now tops up quietly on its own with no key presses.
★ GROWTH SPEED. Growth is driven separately from the bar level and honours the
  "INF Food grow speed" slider (1–10). Higher = faster growth.
~ DIET-AWARE. INF Food reads your dino's diet and only counts the food that
  actually matches it, so you are not tanking hidden wellbeing stats by
  "eating" the wrong things — which is what used to quietly break INF Stam
  whenever INF Food was on.
! On-screen INF Food messages are intentionally short ("Active." / "Eat any
  food once to activate.") — just enough to tell you the state, nothing more.

────────────────────────────────────────────────────────────────────────────
  TARGET TAB          (type a username → act on that player)
────────────────────────────────────────────────────────────────────────────
~ THE TARGET TAB ALWAYS LOADS now. It used to vanish entirely under certain
  loaders; that gate is removed, so the tab and everything in it is always
  there.
~ TYPING A NAME WORKS. The name box now registers what you type immediately —
  before, if you typed a name and hit Load without pressing Enter first, it
  checked an empty box and said "not found". Fixed.
~ THEIR DINO ACTUALLY LOADS. Other players' dinos are not labelled with their
  username the way your own is, so the old lookup missed them. It now finds a
  player's dino by every reliable signal available and, when they've been seen
  before, pulls their area in so a far-away target still loads without you
  walking over there.
~ PROFILE READOUT: shows User, Dino, Stage, Gender, Health, Distance and a live
  Status line, refreshed every second, using the same reader the ESP uses — so
  the Target profile can never show less than ESP already does.
~ VIEW / SPECTATE fixed. It did nothing after you died once, because it was
  holding onto a stale camera. It now grabs a fresh camera every frame and
  follows the target's dino from behind-and-above, framed to their size. Press
  again to stop; the camera hands straight back to you (also on target loss).
~ TP / TRACK / ATTACK / AUTO FARM PLAYER: all wired to the live model, so they
  work the moment the target's dino is loaded in.
! If a profile still reads "--", the game simply hasn't sent that player's dino
  to you yet (they're too far). Get closer or use ESP and it fills in.

────────────────────────────────────────────────────────────────────────────
  AUTO FARM  (Fossils / Gems)
────────────────────────────────────────────────────────────────────────────
~ AUTO FARM FOSSIL is instant again — it teleports straight onto each fossil
  and holds long enough to collect before moving on, so it hits EVERY fossil
  instead of skipping most.
  ▸ It now matches all fossil sizes (was only catching the small ones).
★ FOSSIL COLLECT DELAY slider — set the pace between fossils so it collects
  calmly instead of blinking node to node.
~ GEMS keep their steadier approach (their collect takes longer, so the calmer
  path is more reliable there).
~ FOSSIL vs GEM is no longer confused — fossil mode won't wander onto gems and
  vice-versa.

────────────────────────────────────────────────────────────────────────────
  PRO FOOD  (one-button growth farmer)
────────────────────────────────────────────────────────────────────────────
~ CIRCLE MOVEMENT FIXED both ways:
  ▸ ON  — you now genuinely trace a circle to grow (the old version only walked
    you diagonally in a straight line).
  ▸ OFF — turning it off stops you instantly. The old version could leave you
    stuck "walking on your own" because a movement key never got released.
~ "I MOVE LIKE PRO FOOD SOMETIMES" — solved. Confirming a corpse on the
  corpse-TP popup used to silently switch Pro Food ON (and start the circling).
  It no longer does; Pro Food only ever starts from its own Growth-tab toggle.

────────────────────────────────────────────────────────────────────────────
  INTERFACE
────────────────────────────────────────────────────────────────────────────
+ DREAM LOGO BUTTON — the floating open/close button is now the Dream logo in
  clean black & white (with a white "DREAM" fallback until the image loads, so
  it's never a blank circle). It's on ALL devices now, not just mobile: tap it
  to open/close the menu, drag it to move it out of the way. PC can still use
  RightShift.
~ Mobile fly ▲ / ▼ buttons stay on touch devices only.

────────────────────────────────────────────────────────────────────────────
  TIERS & LOADERS
────────────────────────────────────────────────────────────────────────────
+ TWO PAID LINKS: PE Plus and PE Premium, each with its own loader.
  ▸ Plus     = Target tab + Auto Farm Player and the full core hub.
  ▸ Premium  = everything in Plus, plus the Premium-only extras.
~ Loaders validate every download and retry across mirrors, so a bad executor
  cache can't hand you the wrong file — and they tell you plainly if it does.

────────────────────────────────────────────────────────────────────────────
  BONUS TOOL
────────────────────────────────────────────────────────────────────────────
+ PE SPEED FINDER (separate script) — a small HUD that shows your live speed.
  Tap Shift to record a number (it copies to your clipboard so you can paste it
  back), and it flags any snap-back automatically with the speed you were doing
  when it happened. Handy for tuning on any server.


════════════════════════════════════════════════════════════════════════════
  2 · JUJUTSU SHENANIGANS         (Free / Full)
════════════════════════════════════════════════════════════════════════════

────────────────────────────────────────────────────────────────────────────
  TELEPORTS
────────────────────────────────────────────────────────────────────────────
~ TELEPORTS REBUILT and fixed. Every teleport in the hub — named locations,
  players, saved slots, Target, Auto Farm — now travels smoothly to the
  destination and sticks, instead of getting bounced back.
  ▸ BUILDING AVOIDANCE: if something solid is between you and the target, it
    routes up and over instead of grinding into the wall, then comes down on
    the spot.
  ▸ Fixed a crash at the end of every trip that (in an earlier build) stopped
    you landing cleanly and could leave you unable to walk through things you
    should. Landings are exact now and everything returns to normal after.
  ▸ Rapid back-to-back teleports (e.g. sword spam) no longer fight each other —
    the newest one always wins.
! Teleports / Target / Auto Farm carry an in-app "🏗️ In fixing + kind of works"
  note while this new method gets battle-tested. Leave it on; it means the
  feature is live but still being hardened.

────────────────────────────────────────────────────────────────────────────
  ITEMS & TRASH
────────────────────────────────────────────────────────────────────────────
~ TRASH THROW now actually PICKS UP the trash first, confirms you're holding it
  (retrying if needed), then throws it at your target — and if there's no loose
  trash around, it clicks the nearest trash can to get some. No more "throwing"
  with empty hands.
~ Item grab is more reliable — it verifies the pickup landed instead of assuming
  it did.

────────────────────────────────────────────────────────────────────────────
  INTERFACE
────────────────────────────────────────────────────────────────────────────
~ LOGO FIXED. The floating logo button was showing as a blank purple circle
  when the image failed to load. It's now a finished-looking badge from the
  first frame — gradient, ring, and "DREAM" text — with the real logo fading in
  on top only once it has actually loaded. No more blank circle, ever.

────────────────────────────────────────────────────────────────────────────
  FREE BUILD
────────────────────────────────────────────────────────────────────────────
+ JJS FREE is available both directly and behind a link gate (complete the link,
  then get the script). Red & black theme, trimmed but loaded feature set.


════════════════════════════════════════════════════════════════════════════
  3 · ABILITY ARENA               (Free / Plus / Premium)
════════════════════════════════════════════════════════════════════════════

────────────────────────────────────────────────────────────────────────────
  NEW FEATURES
────────────────────────────────────────────────────────────────────────────
+ AUTO RESPAWN  (Plus + Premium) — the instant you die and respawn, it deploys
  you straight back into the fight. No sitting in the lobby. Clean on/off
  toggle; turning it off drops the auto-deploy immediately.
+ AUTO HEAL  (Plus ONLY) — one button restores you to full health and puts you
  back exactly where you were standing.
  ! It will NOT work while you're in PvP/combat — you'll get a clear notice
    telling you to get out of combat and try again, rather than it silently
    doing nothing.
  ▸ Premium does not include Auto Heal by design.

────────────────────────────────────────────────────────────────────────────
  AUTO DODGE
────────────────────────────────────────────────────────────────────────────
+ DODGE PLAYER dropdown — choose WHO Auto Dodge reacts to:
  ▸ "All"           → dodge any attacker (default).
  ▸ a specific name → dodge ONLY that player, ignore everyone else.
+ "Refresh Dodge List" button, and the list also updates itself as players join
  and leave.
~ The filter is applied at the source, so a non-selected player's attack won't
  even trigger a dodge.

────────────────────────────────────────────────────────────────────────────
  EXISTING (recap)
────────────────────────────────────────────────────────────────────────────
· God Mode (Plus): lobby-state trick that TPs you into the fight untouchable.
· Combat Pro: Legit Auto Play, Instant 1v1 Win (front/back), stronger Aura M1.
· Save Health, M1 Warp, Auto Ability (E / Q / R / T casting).
~ Cleaner notifications throughout — enough to know what's happening, not enough
  to give the method away.


════════════════════════════════════════════════════════════════════════════
  4 · ACROSS ALL HUBS
════════════════════════════════════════════════════════════════════════════
~ QUIET, SAFE NOTIFICATIONS. On-screen messages across the hubs were trimmed so
  they tell you the state of a feature without spelling out how it works — this
  keeps the good stuff from being easy to copy or patch.
~ STABILITY. Heavy scans (ESP, item lists) are throttled and capped so they
  can't lag you out or take the menu down; failures fall back quietly instead of
  crashing.
~ EVERY SCRIPT is delivered through a hardened loader that validates the
  download, retries across mirrors, and reports clearly if your executor hands
  back a bad copy.

────────────────────────────────────────────────────────────────────────────
  QUICK REFERENCE — WHAT GOT FIXED THIS PASS
────────────────────────────────────────────────────────────────────────────
  Prior Extinction   death-spawn loop · INF Stam slow/snap · eat/E blocked ·
                     Target tab load + name box + dino load + View · fossil
                     farm · Pro Food circle · Dream logo · Death-Fix toggle
  Jujutsu Shen.      teleports (all) · building avoidance · trash pick-up +
                     throw · logo
  Ability Arena      Auto Respawn · Auto Heal (Plus) · per-player Auto Dodge

                    ── press RightShift (or tap the Dream logo) ──
                              enjoy. — Dream Hub
