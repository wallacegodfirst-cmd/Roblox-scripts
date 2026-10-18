# JJS combat test build — October 18, 2026

Full script: `JJS_fixed.lua`. Loader: `Load_JJS.lua`.

Built from the latest supplied `151305de-3fdb-4543-9e12-cbb0d6ef9ed3/pasted-text-1.txt`, preserved as `JJS_original.lua`. Prior Extinction was not edited.

Use a fresh game session and execute this build once. Older builds leave anonymous animation/input connections running; replacing the move hook alone cannot remove those connections.

## Changes and verification

| Requested feature | Implementation | Local evidence | Live status |
| --- | --- | --- | --- |
| Black Flash timing, including first use | One animation observer owns the follow-up; uses the original AutoBlackFlash reference's 0.19/0.20 second wall-clock delays. Removed the competing delayed fallback. | Initial cast, duplicate/reused tracks, paused animation, cancel, missing animation, blocked key and death regressions pass. | Hit registration and timing under real latency unverified. |
| Side Dash BF | One A/D + Q input with forward keys neutralized and avatar orientation held during direction selection. Closer back-position gate; temporary aim lock. | Held-W regression and single-dash checks pass. No position/velocity writes in native dash helper. | Native dash path and successful back hits unverified. |
| Back Dash BF | One S + Q, then shared back-aim and BF timing. | Back-direction and single-cast checks pass. | Spacing and hit result unverified. |
| Jump BF | Space + actual Jumping state, ordinary movement, no Q or forced translation. Requires airborne/back-range conditions. | Jump state, no-Q, cleanup checks pass. | Travel distance and BF result unverified. |
| Teleport BF | One position request, checked before casting; stops when rejected instead of repeatedly rewriting position. | Full-script compile; code review. | Server acceptance unverified and cannot be forced by client code. |
| M1 Chain | Uses the corrected native approach and the same single BF scheduler. | Shared movement/timing regressions pass. | Full live chain unverified. |
| Auto Uppercut / Downslam | Count accepted swings. Uppercut holds Space at swing three and releases after four. Downslam jumps and uses one native fourth attack. Removed companion direction-remote sends from these paths. | Normal combo arming/release and one-slam tests pass. | All-character animation coverage and actual finishers unverified. |
| Normal attacks stop working | Move observer cannot corrupt the forwarded FireServer method; preserves nil arguments and forwards once even if a callback fails. Key cleanup runs on failure. | Method-clobber, callback failure, named dispatch fallback, key-cleanup tests pass. | Executor-specific hooking remains unverified. |
| Uppercut / Downslam Assist | Stunned/downed eligibility; three observed M1s; close target needs no dash, far target uses one native side approach; one native final attack. | Close/far/failed-approach/standing-target paths pass. | Real stun markers, timing and hit outcomes unverified. |
| Soul Combo | Original 1 passes through, aim tilts up, one 3 is pressed, camera restored. Removed target-airborne waiting and the extra dash. | Input order, no extra 1/Q, toggle cancellation and camera cleanup pass. | Game acceptance of 3 during the move unverified. |
| Predict Swap | Removed implementation and all five controls. | No API references remain. | Not applicable. |
| Todo Auto BF | Observe a new moving pebble, aim and R to start Blazing Star; then 2, followed by one animation-timed 2. | R-before-glide order, follow-up count, missing-projectile and cancel cases pass. | Projectile naming/ownership heuristics, kick identity and timing need live confirmation. The code does not claim a generic Action track proves a successful BF. |
| Todo Auto Tap | Kept the complete existing Auto Tap function unchanged. | Byte-for-byte normalized-source comparison passes. | User previously reported this working. |
| Locust 3 → R | Observe target launch/ragdoll/damage with supplied animation IDs as corroboration; aim at the airborne target and send one R. | No early R, launch-triggered R, missed launch and cancel cases pass. | Live launch detection and special acceptance unverified. |

The full file compiles with Luau 0.722. `node tests.js` runs nine behavior suites plus preservation checks. These use mocks and do not simulate Roblox physics, game server cooldowns, hitboxes, damage, or animation acceptance. No Roblox Studio instances were connected during this revision. Consequently this is a revised **test build**, not a verified guarantee of Black Flash on every attempt.

## Mechanics consulted

- [Switcher mechanics](https://jujutsushenaniganswiki.com/wiki/switcher/): swapping with a pebble before it hits starts Blazing Star; Brute Force during that glide becomes Brutal Impact; the second activation is timed to the kick.
- [Locust Guy mechanics](https://jjs-wiki.com/wiki/locust-guy/): Crushing Jaws launches its target; the special has an aimed airborne-target follow-up.

The supplied `Autoblackflash.lua` reference provides the five animation IDs and wall-clock timing delays. Its timing profile is preserved rather than claimed as independently measured against the current game.

## Artifact integrity

The raw GitHub file at commit `d7973b62909de75073d84353860d6f11047e377a` was downloaded and compared with the local script. See `manifest.json` for SHA-256 values. The test branch is `test/jjs-combat-20261018`.

Build reproduction: `node build.js`, `node tests.js`, then `luau-compile.exe --null JJS_fixed.lua`.
