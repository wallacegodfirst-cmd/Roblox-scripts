# JJS October 19 r2 — test build

Full script: `JJS_fixed.lua`. Loader: `Load_JJS.lua`. Execute once in a fresh game session so listeners and hooks from older builds cannot interfere.

This revision uses the live feedback in `da8cd3bb-29e5-4e2a-b7d4-9f05adf01885/goal-objective.md` and builds on the previously delivered October 19 script. The approved side-dash geometry is unchanged. Prior Extinction and production loaders were not edited.

## Changes by requested feature

| Feature | Change | Verification and remaining limit |
| --- | --- | --- |
| BF chains: intermittent missing 3 / plain Divergent Fist | Release 3 before each injected down event, including the timed follow-up. An unsuccessful approach no longer spends the script's BF cooldown. The CAS trigger does not swallow a press that the script would immediately reject on cooldown. | First-cast, repeated tracks, held-key edges, no-windup, cancellation, death, text focus and failed-approach retry tests pass. Server acceptance and actual Black Flash hits remain unverified. Passing through a cooldown-blocked press preserves normal game input; it does not bypass the game's cooldown. |
| Back/side movement and aim | Preserve the approved steering path; allow 0.32 seconds to observe native dash acceptance and raise back-aim render priority. | Exact-source geometry preservation check passes. Current back-hit positioning and native animation timing still require live testing. |
| Jump BF | Increase the temporary jump-path movement-speed boost from up to +3 / 12% to up to +5 / 30%. Restore it after the sequence. | Full compile and source inspection; no claim of measured live jump speed or successful BF. |
| M1 Chain | Defer the sequence out of the animation callback and wait 0.42 seconds for the initial punch before requesting movement. | Sequence test verifies the delay and that failed approaches do not consume script cooldown. Live dash/attack cancellation behavior remains unverified. |
| Auto Uppercut / Auto Downslam and assists | Restore the supplied character-direction `Activated("Up")` / `Activated("Down")` route via the current character-service resolver. Three observed directional attacks precede the fourth; a human first punch reduces injected attacks to three total. Close targets need no dash; farther targets use the existing side approach. Downslam jumps before the fourth. Native-input fallback remains when no character remote resolves. | Full controller test covers close uppercut, far downslam, unknown M1 animation IDs correlated with requests, 0.37-second mock cooldown, and a human first punch. All-character service resolution and server interpretation remain unverified. |
| Locust 3 | Preserve the original physical 3. Immediately start a bounded burst of 18 R key presses, 0.14 seconds apart, with target aim and cancellation. Remove the previous launch-signal gate and duplicate initial remote cast. | Test verifies immediate R, no extra 3, bounded count and disable cleanup. The previous supplied CrushJaw/Locust remotes remain context for the move; this revision follows the user's latest request for physical R input. Live follow-up acceptance remains unverified. |
| Locust Fly | Add **System → Locust → Locust Fly**. A manual R waits for airborne state, faces away so S+Q travels back toward the target, then turns toward it and sends one M1. | Test verifies launch ordering, direction input, final aim, one click, cancellation and cleanup. Actual airborne dash availability and travel are unverified. |
| Soul Combo | Preserve the original 1; queue briefly behind an occupied input owner, aim up, then send exactly one deliberately released/pressed 3 after 0.16 seconds with a 0.10-second hold. | Input order, one 3/no extra 1 or Q, brief-owner queue, cancellation and restoration tests pass. Acceptance of 3 during the live ability remains unverified. |
| Hollow Nuke | Default to click-selected player/dummy with no low-HP gate. Sequence is Blue → approach → Blue → find a newly observed Blue effect → aim Red at it. Add Lowest HP, Largest Target (model volume), and Closest choices. HP threshold applies only to Lowest HP. Re-clicking the same target can run again after the script cooldown. | Tests cover full-health selection, same-target re-click, key order, orb aiming, absent-orb stop, all three automatic selectors, threshold and cancellation. Blue identification uses fresh effect names/owner attributes; real effect structure, cooldown acceptance, teleport acceptance and detonation require live testing. |
| Anti-Counter Jump on Head | Replace glide/teleport plus decorative animation with actual Space/jump and horizontal steering toward the head. Pass the countering model directly so equal dummy names do not select another model. | Real jump/no-position-write, movement, focus and cleanup tests pass. Actual landing on a moving character's head is unverified. |

The original supplied finisher references are in `1ce20c5d-ec88-4f4e-ab9f-937c69e47a8a/Pasted text.txt` around lines 9042–9090 and the older `f641f097-06d0-4d77-8644-2c38b1d9bf10/pasted-text.txt` around lines 1221–1230. They use directional strings on character `Activated` remotes; this revision resolves the current character rather than hardcoding Itadori.

## Verification

Run `node build.js`, `node tests.js`, and `luau-compile.exe --null JJS_fixed.lua`.

The complete file compiles with Luau 0.722: 17 KLOC / 804 KB bytecode. All listed local sequence tests pass. Todo Auto Tap, the approved side-dash steering geometry, and Auto Evasive are source-identical to the preceding build. Evasive was left alone because the latest user feedback explicitly deferred testing it. Predict Swap remains removed. No embedded Discord webhook endpoints were found.

These tests use mocks. They do not run Roblox physics, execute against a JJS server, or prove actual damage, Black Flash, uppercut, downslam, Hollow detonation, or successful head landing. The full goal remains incomplete pending live results for this revision. No claim of 100% Black Flash success is made.

## Artifact integrity

- Source SHA-256: `5549eba5f6498cd3cc1f84f6caf254a83d0676632d8e599c9ab0eaaf8a998c50`
- Output SHA-256: `f770b1f630c9a978d187aa1723d62165fe5ab0ed8e7bcc4d0b634e5738d1edd7`
- Test branch: `test/jjs-combat-20261019-r2`
- Immutable script commit: `220aef060e1dcb8df605a186e2d785807e7e0853`
