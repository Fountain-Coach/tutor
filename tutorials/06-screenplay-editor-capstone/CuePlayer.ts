import { Midi2Player } from '@fountainlabs/midi2';

const context = new AudioContext();
export const player = new Midi2Player({ context });

export async function playCue() {
  await player.load('cue.mid');
  player.play();
}
