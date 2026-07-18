# DREAM HUB — UPDATE LOG

---

## COMING NEXT UPDATE

- JJS Premium and Plus plans
- Boxing beta (Premium)
- INF Stamina fix (Prior Extinction)
- Teleport fix (Jujutsu Shenanigans)

---

## ALL GAMES (Prior Extinction + Ability Arena + Jujutsu Shenanigans)

### New features
- Live chat for every hub user — shared across all 3 games and every server (CHAT button, bottom right)
- Chat rows show avatar, username, role badge, plan, and the game the sender is in
- Staff roles: OWNER (ChloeFlash9563), DEV (Real_revvybxnned11), HEAD MOD (hvdkssl25), GAME MOD (bruckner_tempest)
- Roles show in the chat badge, the floating title above your head, and your menu profile card
- Emoji in chat: type :skull: :fire: :100: :joy: :heart: :clown: :cap: :goat: :pray: :moyai: and 15+ more
- 62 staff commands typed straight into the chat box — ?cmds opens the full list in-game
- ?warn — red warning popup on the target's screen (not in chat), logged to the tracker
- Warning tracker (?warns) — staff-only window: who has warnings, how many, every reason, who gave it
- ?clearwarns — wipe a user's warning record
- ?mute / ?unmute — block someone from live chat for a time limit, follows them across servers and games
- ?noemoji / ?okemoji — turn someone's emojis off for a time limit
- Message delete for staff — small x on every chat message; ?del, ?delall and ?clearchat by name
- ?announce — blue popup to every hub user in every game
- ?dm — private popup only the target sees;  ?notify — small corner notification
- ?slowmode / ?slowoff — force a wait between messages;  ?lockchat / ?unlockchat — staff-only chat
- ?badword / ?goodword — add or remove words from the AI filter live, no reload needed
- ?settitle / ?cleartitle — override anyone's overhead title for all hub users
- Info commands: ?who ?id ?age ?list ?staff ?online ?server ?ping ?time ?ver
- Self commands: ?tp ?rtp (random player) ?back ?view ?unview ?speed ?jump ?fly ?noclip ?invis
  ?unstuck ?sit ?reset ?rejoin ?hop ?fov ?bright ?day ?night ?copyid ?copyname ?copyprofile and more
- AI mod in live chat: messages are scanned BEFORE they send — rule breaks are blocked, censored for
  everyone, and auto-reported to staff with the exact message as evidence
- AI mod on staff clients also watches the normal in-game chat and auto-reports rule breaks
  (slurs / hate speech, advertising, scams, threats and harassment)
- Admin tab in every hub: load user (yourself included for testing), send warn, teleport to user,
  view player / stop viewing, fly, copy username / UserId / profile link, report to Discord
- Report to Discord with a reason box and a proof image link (direct png/jpg/gif links embed as the image)
- Bug report + feedback straight from the menu, with proof image link
- Rules tab: 15 rules, each with the action taken when broken
- Mod overhead title above staff heads — ONLY people running the hub can see it
- Dashboard menu: profile card with avatar + role + plan, update log panel, quick actions,
  session timer, member-for days, live player count
- Loading screen with spinner ring into the menu

### Fixes / bugs
- Discord reports were not arriving: some executors block discord.com — every report now retries
  through a webhook proxy and accepts any success status. Reports actually land now.
- Send Warn did nothing in some games: the chat-send only tried one channel — warns were moved off
  game chat entirely and now pop on the target's screen through the relay
- Input boxes showed "TextBox / This is a TextBox / Write your input there": labels now pass the right
  keys, and the library's hardcoded inner placeholder is rewritten right after each box is created
- ENTER HUB button text was off-center with a weird gap — now "ENTER HUB - PLAN" centered
- Admin teleport only worked in Prior Extinction — now generic (works in any game) with a dino fallback
- Overhead title could clip inside big characters — now sits above the model's real head height

### Reworked
- Warns: popup card + notification on the target's screen instead of a game chat message
- Overhead title: clean styled rainbow text, no box, no emoji; per-role text (OWNER / DEV / HEAD MOD / GAME MOD)
- Menu: hover glow on quick actions, gradient + hover effect on ENTER HUB, refreshed update log entries
- All emojis removed from the UI itself (buttons, titles, menu) — emojis live only in chat messages
- Add admins box and warn text box removed from the Admin tab (cleaner; custom warns via ?warn)

### Not working / known limits
- A script cannot capture a real screenshot — the exact chat message is the report evidence instead
- Chat, warns, mutes and titles only reach people running the hub (it is a relay, not a Roblox feature)
- Live chat refreshes about every 4 seconds
- Roblox does not expose anyone's Discord account — nothing can link the two

---

## PRIOR EXTINCTION

### New features
- Spawn rescue (Death Bug Fix) now drops you next to a RANDOM PLAYER instead of an empty spawn
- Force Run Speed slider (0 = auto learns your dino's real sprint)
- INF Stam diagnostic panel (helps hunt the real speed lever)
- Target system: type any name — profile, teleport, view, farm
- ESP: creatures + players, corpses, plants, fish, gems + fossils
- Auto farm: player, fossil, gem; auto eat food
- INF Food / INF Water / Anti Drown / Walk on Water / Anti Fall / anti-injury protections
- Progress restore (replays your spawn/restore payload)

### Fixes / bugs
- FIXED — clicking did no damage while Anti Fractured was on: the injury protection was swallowing any
  remote whose text matched injury words (crush / blunt / bite / head...), which included your own
  attacks. Attacks always pass through now; only injury reports about YOUR dino are blocked, so the
  protection itself is unchanged
- FIXED — teleports glided you across the map: you now snap to the destination instantly on your
  screen while the believable hop-path only plays out to the server (no send-back, no glide)
- FIXED — spawn rescue used to fight the game's own Unstuck timer / yank you around on normal spawns
- FIXED — auto farm was feeding you to death
- FIXED — corpse teleport put you on top of the corpse mesh / floating
- FIXED — second attack (right click) dealt no damage while INF Stam was on

### Reworked
- All teleports are instant-snap with anti-fall protection on landing
- Admin teleport generic with dino fallback
- Overhead title finds your dino model even though it is not a normal Roblox character

### Not working
- INF Stamina — NOT WORKING right now, getting fixed. Do not use it. (The game corrects sprint speed
  server-side; every client lever tried so far gets overridden. The fix is in progress.)

---

## ABILITY ARENA

### New features
- Everything in the ALL GAMES section (live chat, roles, 62 staff commands, AI mod, admin tab,
  rules tab, reports with proof, mod overhead titles)

### Fixes / bugs
- Input boxes show your labels and hints instead of the library defaults
- Reports retry through the proxy when the executor blocks Discord

### Reworked
- Warn text box removed from the Admin tab (Send Warn = standard warning; custom = ?warn in chat)

### Not working
- Nothing specific to this game right now

---

## JUJUTSU SHENANIGANS

### New features
- Everything in the ALL GAMES section (live chat, roles, 62 staff commands, AI mod, admin tab,
  rules tab, reports with proof, mod overhead titles)

### Fixes / bugs
- Input boxes show your labels and hints instead of the library defaults
- Reports retry through the proxy when the executor blocks Discord

### Reworked
- Warn text box removed from the Admin tab (Send Warn = standard warning; custom = ?warn in chat)

### Not working
- Teleport — NOT WORKING right now, getting fixed. A fix ships in the next update.
