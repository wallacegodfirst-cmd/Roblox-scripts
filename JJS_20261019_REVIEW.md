# JJS test build — October 19, 2026

This revision builds on the October 18 script whose side-dash path the user approved. `JJS_original.lua` preserves that baseline. `JJS_fixed.lua` is the complete revised script, and `Load_JJS.lua` loads the immutable test build.

Execute once in a fresh session so input and animation listeners from previous builds cannot interfere.

## Changes

- Preserved the approved native dash steering geometry. A BF cast now waits for actual dash acceptance and minimum travel. Known shared dash cooldowns are awaited before taking controls; an unavailable dash stops instead of becoming a short walk and turn. Despawn, cancellation and input cleanup are guarded.
- Improved the shared BF scheduler: an observed BF windup takes priority over a queued M1 request, and a newly attached Animator's in-progress windup can be caught with elapsed-time correction. These changes also apply to the existing teleport and back-dash paths. Teleport remains subject to server acceptance.
- Jump keeps a real Space/jump action, with a small temporary movement-speed increase that is restored afterward.
- M1 BF and M1 Chain start from the first observed human punch. Removed the outdated M1-count selector.
- Uppercut and downslam use observed swings while holding M1 through native cooldowns. The human first punch counts toward the three; the controller supplies the remaining two. Downed/ability follow-ups supply three. Close targets need no dash; farther targets use the shared side-dash approach before the fourth attack. Uppercut is primed at swing three. Move-follow-up detection uses existing animation catalogs, while an ability-pending guard prevents the polling path from consuming inputs during the move.
- Locust uses the user's exact `CrushJawService.RE.Activated(Crushing Jaws)` call and no-argument `LocustService.RE.RightActivated()`. It listens for the captured launch animations or corroborated target damage plus lift. The fallback input observer does not duplicate the native initial cast.
- Evasive activates on the local character's ragdoll state. Cycle chooses Back, Left, Right; individual directions remain selectable. Optional return behind the target happens only after recovery and the shared dash cooldown. Standing enemy animations do not spend evasive.
- Todo Drop aims at the launch target and presses 4 promptly after the uppercut marker. The downslam timing slider is preserved.
- Shortened the requested Auto-tab and Side Dash Assist labels. Todo Auto Tap and Soul Combo are unchanged.

## Verification and limitations

`node build.js` reproduces the full script. `node tests.js` passes behavior suites for BF timing/ownership, dash acceptance, observed M1 counts, close/far finisher orchestration, Locust payload and cancellation, evasive ordering, and preservation checks. The entire script compiles with Luau 0.722: 17 KLOC / 794 KB bytecode. No embedded Discord webhook endpoints were found.

These are local mocked sequence tests, not live Roblox physics or server tests. They do not prove successful Black Flash on every attempt, all-character animation coverage, server acceptance of remotes or teleport, exact live cooldowns, or damage registration. This is a test build awaiting the user's live results.

## Reference

[JJS controls and mechanics](https://jujutsushenaniganswiki.com/wiki/controls-mechanics/) describes side/back dash sharing a two-second cooldown and evasive as a ragdoll escape. The implementation separates escape from the optional return approach accordingly. Animation IDs and remote paths come from the supplied script and the user's captured calls.

## Integrity

Source SHA-256: `9fa6d742fa295d8b9def83ab35abe9a355515cbed17bdc440e96e956b6afd1da`

Output SHA-256: `5549eba5f6498cd3cc1f84f6caf254a83d0676632d8e599c9ab0eaaf8a998c50`

Test branch: `test/jjs-combat-20261019`

Script commit: `636db188d614f1c206474424be0dd46d7814e52c`

Production loaders and Prior Extinction were not changed.
