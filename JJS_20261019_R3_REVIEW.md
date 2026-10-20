# JJS October 19 r3

Full script: `JJS_fixed.lua`. Loader: `Load_JJS.lua`. Execute once in a fresh session; earlier builds' anonymous animation/input listeners may remain active otherwise.

This revision follows the user's latest r2 live feedback and the supplied screenshot of the luminous blue Lapse Blue MAX effect. The screenshot establishes appearance, not an internal Roblox instance name or animation ID.

## Changes and evidence

| Request | Change | Verification limit |
| --- | --- | --- |
| Side/back dash occasionally aborts or looks away | Fixed a competing general lock-on callback that set AutoRotate true every frame even when its mode was Off. It now yields while a combat sequence owns input. Successful sequences retain the final target-facing camera angle after releasing their temporary lock. The approved steering geometry remains in place. | Dynamic ownership and final-camera restoration tests pass. Actual physics, back positioning and intermittent server corrections require live testing. |
| Original 3 produces Divergent Fist before the intended chain | A consumed trigger cannot pass through during a busy sequence or script cooldown. Added a narrowly scoped move-hook guard for the original local Divergent Fist cast when its trigger timestamp is newer than the chain's injected press. Script-dispatched chain casts and other moves pass through. The guard expires after 0.3 seconds. | Tests verify original-trigger rejection, chain dispatch, unrelated moves and expiry. This cannot guarantee that a server accepts every timed follow-up as Black Flash. |
| Jump should bunny-hop rather than substitute a dash | Starts one real Space/jump before directional setup, avoiding the immediate release/repress setup. Keeps ordinary movement and restores the temporary speed change. | Test verifies one Space, no Q substitution, jump state and cleanup. Live jump arc and successful back hit remain unverified. |
| Far uppercut/downslam assists stop after one punch | Far targets are approached with the shared native side dash before counting the three attacks. A target that moves away can still be approached before the fourth. Close targets retain the working four-hit path. This deliberately changes the old far-target order, which could stop before ever reaching its dash. | Full-controller test makes the first action an approach when far, then observes four accepted attacks. Live server timing/all-character behavior remain unverified. |
| Auto Uppercut/Downslam should work with spam clicking without extra punches | Normal auto toggles no longer run the downed-target polling combo. They observe the user's accepted swing animations and modify only the armed fourth native M1 packet to the existing Up/Down direction. They do not inject extra M1s. Assist toggles retain automatic downed-target combos. Reset and cancellation clear the manual count. | Tests verify no unsolicited attacks, no injected manual-combo punches, selective fourth-packet rewrite, downslam jump preparation and preservation of other packets. Real animation coverage still needs testing. |
| Locust 3 does not spend R | Replaced virtual R key events with the exact supplied `LocustService.RE.RightActivated:FireServer()` endpoint, with no arguments. The original 3 still passes through; the R burst is bounded and cancelable. | Tests verify exact endpoint/argument count, burst limit and cancellation. Successful bar consumption and ability acceptance are not proven by calling a remote. |
| Locust Fly placement and trigger | Moved to **Assistant → Dash Assists**. A manual R immediately invokes the same native back-dash approach used by combat, then aims at the target and sends one M1 if in range. Removed the airborne gate. Added cancellation validation to the shared approach. | Sequence tests pass. No teleport was added to this feature. Actual dash availability and arrival remain unverified. |
| Soul aim/3 should follow the target's launch | Waits for the selected/nearest target to become airborne or rise, then aims up and sends 3. If a slot-3 move and its exact remote have already been learned from the game, use that captured call; otherwise send the key. | Airborne gating, one 3, aim order and cancellation tests pass. Launch detection and game acceptance remain unverified. |
| Hollow must aim at Blue after the player dies | After the initial Blue input, the sequence no longer depends on the target remaining alive. It sends one Blue then one Red at the observed effect; it does not duplicate Blue or require a teleport. The detector accepts fresh blue/cyan parts and emitter/light evidence in addition to names, while retaining owner/distance checks. | A test removes the target after Blue and confirms Red is aimed at an unnamed blue effect. Real effect hierarchy and successful detonation remain unverified. |
| Hollow should keep responding while enabled | Selected targets remain eligible while enabled, and same-target clicks can trigger again after the bounded 0.5-second script retry interval. Disabling cancels the sequence. In-game ability cooldowns still apply. | Cancellation and sequence cleanup pass. Live cooldown behavior remains unverified. |
| Hollow threshold means HP, e.g. 70 or less | Changed the slider to **Hollow HP Limit** and compare actual Health rather than percentage. Lowest HP chooses the lowest-health living player/dummy; Closest and Largest Target remain available. | Test verifies a 100/200 target is excluded at a 70 HP threshold, while 65 HP is included. |

## Validation

`node build.js` reproduces the script. `node tests.js` passes the targeted behavior suites. The complete file compiles using Luau 0.722: 17 KLOC / 806 KB bytecode. No embedded Discord webhook endpoints were found.

These are mocked local tests, not live JJS verification. They do not establish successful damage, every Black Flash, server movement acceptance, bar consumption, or Hollow detonation. The user's report that close-range finishers and the previous movement looked good is preserved as feedback, not proof that new behavior is live-verified. The complete goal is still unverified.

## Integrity

- Source SHA-256: `f770b1f630c9a978d187aa1723d62165fe5ab0ed8e7bcc4d0b634e5738d1edd7`
- Output SHA-256: `ad2d15e3add2e8bda5492f6b6610fa7d9866a3a092e627b8a4fc61e9a95efd51`
- Immutable script commit: `cd92bace3052fc55039a9d8d5b2972a7967e08e2`
- Test branch: `test/jjs-combat-20261019-r3`

Production loaders and Prior Extinction were not changed.
