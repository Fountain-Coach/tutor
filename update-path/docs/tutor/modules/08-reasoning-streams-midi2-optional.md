# Module 08 — Reasoning Streams (Optional, MIDI2)

**Outcome**: Stream planner/awareness events as SSE-over-MIDI for transparency; add basic transport controls.

## What you’ll ship
A live stream panel that displays reasoning events and lets users start/stop playback.

## Specs to read
- Planner/Awareness streaming endpoints
- MIDI2 transport interfaces (consumer side)

## Behavioral acceptance
- [ ] Live stream appears with event sequencing; transport works (play/stop/replay)
- [ ] No out-of-spec/private calls; only documented streaming endpoints

## Test plan
- Fixture-based stream playback and UI timeline assertions

## Runbook
- Configure stream endpoints and MIDI client per environment constraints

## Hand-off to Codex
> Implement a basic event stream viewer backed by documented streaming endpoints; attach MIDI transport.
