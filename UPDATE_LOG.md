# DREAM HUB — UPDATE LOG

---

## ALL GAMES (Prior Extinction + Ability Arena + Jujutsu Shenanigans)

### New
- Live chat for every hub user, shared across all 3 games and all servers (CHAT button, bottom right)
- Chat shows avatar, username, role badge, plan, and the game they are in
- Staff roles: OWNER (ChloeFlash9563), DEV (Real_revvybxnned11), HEAD MOD (hvdkssl25), GAME MOD (bruckner_tempest)
- Role shows in the chat badge, the title above your head, and your menu profile card
- Emoji in chat: type :skull: :fire: :100: :joy: :heart: :clown: :cap: :goat: :pray: :moyai: and 15+ more
- 60+ staff commands typed straight into the chat box — type ?cmds to see every one
- ?warn — red warning popup on the target's screen (not in chat) + saved to the warning tracker
- Warning tracker (?warns) — staff-only list of who has warnings and every reason
- ?mute / ?unmute — block someone from live chat for a time limit, cross-server
- ?noemoji / ?okemoji — turn someone's emojis off for a time limit
- Staff can delete any chat message (small x on the message) — ?del / ?delall / ?clearchat too
- ?announce (blue popup to every hub user), ?dm (private popup), ?notify (small notification)
- ?slowmode / ?lockchat — chat speed limit and staff-only lock
- ?badword / ?goodword — add or remove words from the AI filter live
- ?settitle / ?cleartitle — override anyone's overhead title
- Self commands: ?tp ?rtp ?back ?view ?speed ?jump ?fly ?noclip ?invis ?fov ?bright ?day ?night ?hop ?rejoin and more
- AI mod: your message is scanned before it sends — rule-breaking messages are blocked, censored for everyone, and auto-reported to staff with the exact message as evidence
- AI mod also watches the in-game chat on staff clients and auto-reports rule breaks
- Admin tab: warn, teleport, view player, fly, copy identity, report to Discord with proof image link
- Bug report + feedback from the menu, with proof image link
- Rules tab: 15 rules, each with the action taken when broken
- Mod overhead title above staff heads — only people running the hub can see it

### Removed
- Add admins box in the Admin tab
- Warn text box in the Admin tab (Send Warn sends a standard warning; custom text is ?warn in chat)
- Every emoji in the UI (ENTER HUB button, overhead titles, menu)

### Reworked
- Discord reports now retry through a proxy when an executor blocks discord.com — reports actually arrive
- Send Warn shows as a popup + notification on the target's screen instead of posting in game chat
- Overhead title: clean styled text, no box, no emoji, sits above the real head height
- Menu: dashboard layout, hover effects, cleaner ENTER HUB button, refreshed update log
- Input boxes show proper labels and hints instead of the library's "TextBox / Write your input there"

### Not working / known limits
- A script cannot capture a real screenshot — the exact chat message is used as report evidence instead
- Chat, warns, mutes and titles only reach people running the hub (it is a relay, not a Roblox feature)
- Live chat updates every ~4 seconds (polling relay, no server of our own)
- Roblox does not expose anyone's Discord account — nothing can link the two

---

## PRIOR EXTINCTION

### New
- Spawn rescue (Death Bug Fix) now drops you next to a RANDOM PLAYER instead of an empty spawn
- Force Run Speed slider (0 = auto learn your dino's sprint)
- INF Stam diagnostic panel for hunting the speed lever

### Removed
- Nothing this round

### Reworked
- All teleports are instant now — you snap to the destination on your screen while the server path walks
  believable hops in the background (no more gliding across the map)
- Clicking now deals damage with Anti Fractured on — attack remotes were being swallowed by the injury
  protection keywords; attacks now always pass through while your own protection stays
- Admin teleport works in any game (generic character teleport with a dino fallback)
- Overhead title finds your dino model even though it is not a normal Roblox character

### Not working / known limits
- INF Stamina — NOT working right now, do not use it (a fix is in progress; the game controls sprint
  speed server-side and every client-side lever tried so far gets corrected by the server)

---

## ABILITY ARENA

### New
- Everything in the ALL GAMES section (live chat, roles, staff commands, AI mod, admin tab, rules tab)

### Removed
- Warn text box in the Admin tab

### Reworked
- Input boxes: label and hint now show your text (library placeholder rewritten after creation)
- Report sends retry through the proxy when the executor blocks Discord

### Not working / known limits
- None specific to this game right now

---

## JUJUTSU SHENANIGANS

### New
- Everything in the ALL GAMES section (live chat, roles, staff commands, AI mod, admin tab, rules tab)

### Removed
- Warn text box in the Admin tab

### Reworked
- Input boxes: label and hint now show your text (library placeholder rewritten after creation)
- Report sends retry through the proxy when the executor blocks Discord

### Not working / known limits
- None specific to this game right now
