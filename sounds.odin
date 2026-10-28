package main

import "core:math"
import rl "vendor:raylib"

Sounds :: struct {
	place: rl.Sound,
	note:  rl.Sound,
	error: rl.Sound,
	win:   rl.Sound,
}

// Short tones synthesized at startup: no audio files to ship. Call after InitAudioDevice.
load_sounds :: proc() -> Sounds {
	return {
		place = make_tone({880}, 0.09, 0.35),
		note  = make_tone({1320}, 0.05, 0.2),
		error = make_tone({220, 175}, 0.09, 0.35),
		win   = make_tone({523.25, 659.25, 783.99, 1046.5}, 0.13, 0.35), // C E G C arpeggio
	}
}

unload_sounds :: proc(s: Sounds) {
	rl.UnloadSound(s.place)
	rl.UnloadSound(s.note)
	rl.UnloadSound(s.error)
	rl.UnloadSound(s.win)
}

// One note per frequency, played in sequence. Each note has a 5 ms attack and an
// exponential decay, with a soft octave on top so it sounds less like a test beep.
@(private = "file")
make_tone :: proc(freqs: []f32, note_len: f32, volume: f32) -> rl.Sound {
	SAMPLE_RATE :: 44100
	per_note := int(note_len * SAMPLE_RATE)
	samples := make([]i16, per_note * len(freqs))
	defer delete(samples) // raylib copies the data into its own buffer

	for freq, k in freqs {
		for i in 0 ..< per_note {
			t := f32(i) / SAMPLE_RATE
			envelope := min(t / 0.005, 1) * math.exp(-t * 6 / note_len)
			wave := math.sin(2 * math.PI * freq * t) + 0.3 * math.sin(4 * math.PI * freq * t)
			samples[k * per_note + i] = i16(wave / 1.3 * envelope * volume * 32767)
		}
	}

	wave := rl.Wave {
		frameCount = u32(len(samples)),
		sampleRate = SAMPLE_RATE,
		sampleSize = 16,
		channels   = 1,
		data       = raw_data(samples),
	}
	return rl.LoadSoundFromWave(wave)
}
