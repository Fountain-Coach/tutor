# MIDI2 Multimedia Tutorial

This tutorial shows how to play audio and keep your user interface synchronized with MIDI 2.0 data.

## Playing Audio

Load a MIDI file and route it into an `AudioContext`. The player will handle decoding and playback once `play()` is called:

```ts
import { Midi2Player } from '@fountainlabs/midi2';

const context = new AudioContext();
const player = new Midi2Player({ context });

await player.load('/assets/cue.mid');
player.play();
```

## Synchronizing UI via MIDI2

During playback, the player emits timing information that can drive interface updates. Listen for `position` events to keep the UI in sync with the audio:

```ts
player.on('position', (seconds) => {
  document.querySelector('#time').textContent = seconds.toFixed(1);
});
```

## Play/Pause Controls

Hook simple controls into the player with standard DOM events:

```html
<button id="play">Play</button>
<button id="pause">Pause</button>
<script type="module">
  import { Midi2Player } from '@fountainlabs/midi2';

  const context = new AudioContext();
  const player = new Midi2Player({ context });
  await player.load('/assets/cue.mid');

  document.getElementById('play').addEventListener('click', () => player.play());
  document.getElementById('pause').addEventListener('click', () => player.pause());
</script>
```

These snippets demonstrate how audio playback and UI synchronization can be achieved using MIDI 2.0.
