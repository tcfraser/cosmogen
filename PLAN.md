# Reversible Gameplay and Animation Plan

## Working Agreement

Implement one step at a time, then stop for the user's inspection and runtime testing. Ask for design advice when the next choice is unclear. Keep implementations small for PICO-8's token and character limits. Do not commit or create pull requests.

## Core Design

Puzzle state is discrete. An accepted move applies its complete logical consequences immediately; animation presents the transition without determining legality. A move followed by undo must restore the previous puzzle state regardless of animation progress.

- **Logical state:** cable anchors, collected critters, checkpoints, changed objects and tiles. Undo restores these exactly.
- **Transition state:** old/new appearances and travel progress. Reverse or rebuild these for undo.
- **Ambient visuals:** oxygen pulse phase and idle animation. These can continue independently of undo.

Use compact history proportional to changes, rather than full world snapshots or per-frame history. Existing anchors and collection indices suffice for current mechanics. Add move records containing previous values when new mechanics require them. No deliberate undo cap is planned, but memory is finite. New moves after undo branch from the restored state; redo is deferred.

Active cable resets and undo history must remain separate concepts. Confirm checkpoint behavior with the user before implementation, especially whether undo crosses a checkpoint.

## Step 1: Atomic Logical Actions

Make path extension, crossing updates, and critter collection complete together. Make undo restore both crossings and collection immediately. Keep idle animation independent of logical changes. Preserve existing directional controls, including vertical-then-horizontal resolution of simultaneous directions and reverse-direction undo.

Acceptance: collection updates on arrival, undo restores it immediately, blocked moves do not change puzzle state, and repeated undo stops at the initial anchor. Stop for inspection.

## Step 2: Movement Transitions and Input Buffering

Animate the astronaut and growing/retracting cable between exact states. Allow one active transition and initially one buffered directional command. Queue intent, validate it when consumed, and keep logical state at most one move ahead of its presentation.

Undo clears pending movement and takes priority. During an unfinished move, restore its previous logical state and reverse from current visual progress. Completed moves get a reverse transition. Initially finish a reversal before starting another undo; tune held-undo speed later.

Coordinate camera behavior with visible player movement. The user chose distance-scaled duration with limits, latest-direction buffer replacement, and vertical-only priority for simultaneous axes. Revised tuning uses smoothstep easing: adjacent ground moves take 2 frames; space moves (distance >= 2) take one frame per tile, bounded to approximately 4–12 frames. Undo uses the same timing. Undo or reverse-direction input clears the buffer; repeated undo during retraction waits for a subsequent input repeat. Camera transitions start from the current displayed camera position when redirected.

Future visual idea: thruster sprite animations on departure and landing for space moves. Deferred for now.

Basic critter visibility waits for visual arrival; suction and cable-travel effects remain in step 4. Crossing decorations follow the visible segment during extension and retraction; reusable path-distance geometry remains in step 3. Stop for inspection.

## Step 3: Cable Geometry and Oxygen Pulses

Provide position and direction at a distance along the anchor path. Use shared path geometry for the astronaut, visible cable extent, and a repeating oxygen pulse moving from source to player. Reveal crossing decorations only when the visible cable reaches them. Pulse phase is cosmetic, not simulated oxygen. Stop for inspection.

## Step 4: Collection Effects and Checkpoints

Keep a collected critter visibly present until the astronaut reaches it, using the transition's previous appearance. Then animate suction and travel backward along the cable. Associate longer-lived cosmetic effects with their originating action; cancel them when that action is undone.

If delivery unlocks gameplay, define the unlock as a discrete logical action rather than an animation-timed consequence. Objects and tiles can share transition progress while choosing their own visual treatment. Add checkpoint behavior and compact reversible records after design discussion. Split this step into separately reviewed changes as needed.

## Progress

- Step 1: inspected and accepted by the user.
- Step 2: implemented; awaiting user inspection and PICO-8 testing.
- Steps 3–4: pending.
