extends Node
## AudioManager Autoload (v8.0) — Real-Time Procedural Polyphonic Synthesizer in GDScript
## Generates 7 Zone-Specific 2-Bar Harmonic BGM Tracks, Distinct Character Voice Blips,
## Cozy Weather/Zone Ambience (Rain Patter, Night Wind Chimes, Ruins Hum), and BGM/SFX Volume Controls!

const MIX_RATE := 22050.0

const BGM_THEMES := {
	"plaza": {
		"name_th": "ลมหายใจต้นไม้โลก",
		"step_sec": 0.50,
		"notes": [261.6, 329.6, 392.0, 493.9, 523.3, 493.9, 392.0, 329.6, 293.7, 369.9, 440.0, 587.3, 523.3, 440.0, 392.0, 329.6],
		"harm":  [196.0, 261.6, 329.6, 392.0, 392.0, 329.6, 261.6, 196.0, 220.0, 293.7, 369.9, 440.0, 392.0, 329.6, 293.7, 261.6],
		"bass":  [130.8, 130.8, 146.8, 196.0],
		"vol": 0.11
	},
	"home": {
		"name_th": "อ้อมกอดกระท่อมรากไม้ทอง",
		"step_sec": 0.60,
		"notes": [349.2, 440.0, 523.3, 440.0, 392.0, 523.3, 659.3, 523.3, 349.2, 440.0, 587.3, 523.3, 440.0, 392.0, 349.2, 329.6],
		"harm":  [261.6, 349.2, 440.0, 349.2, 329.6, 392.0, 523.3, 392.0, 261.6, 349.2, 440.0, 392.0, 349.2, 293.7, 261.6, 261.6],
		"bass":  [174.6, 130.8, 146.8, 130.8],
		"vol": 0.10
	},
	"tavern": {
		"name_th": "ค่ำคืนโรงเตี๊ยมตะเกียงมอส",
		"step_sec": 0.36,
		"notes": [392.0, 493.9, 587.3, 659.3, 587.3, 493.9, 440.0, 523.3, 659.3, 587.3, 493.9, 392.0, 440.0, 493.9, 587.3, 493.9],
		"harm":  [293.7, 392.0, 493.9, 523.3, 493.9, 392.0, 329.6, 392.0, 523.3, 493.9, 392.0, 293.7, 329.6, 392.0, 440.0, 392.0],
		"bass":  [196.0, 146.8, 164.8, 146.8],
		"vol": 0.12
	},
	"smithy": {
		"name_th": "จังหวะค้อนศิลาเพลิง",
		"step_sec": 0.42,
		"notes": [293.7, 349.2, 440.0, 293.7, 392.0, 440.0, 523.3, 440.0, 349.2, 329.6, 293.7, 261.6, 293.7, 349.2, 392.0, 329.6],
		"harm":  [220.0, 261.6, 349.2, 220.0, 293.7, 349.2, 440.0, 349.2, 261.6, 246.9, 220.0, 196.0, 220.0, 261.6, 293.7, 246.9],
		"bass":  [146.8, 146.8, 130.8, 146.8],
		"vol": 0.11
	},
	"nature": {
		"name_th": "เพลงพรายน้ำและพงไพร",
		"step_sec": 0.56,
		"notes": [329.6, 392.0, 440.0, 587.3, 659.3, 587.3, 440.0, 392.0, 329.6, 493.9, 587.3, 659.3, 587.3, 493.9, 440.0, 392.0],
		"harm":  [246.9, 293.7, 329.6, 440.0, 493.9, 440.0, 329.6, 293.7, 246.9, 392.0, 440.0, 493.9, 440.0, 392.0, 329.6, 293.7],
		"bass":  [164.8, 196.0, 146.8, 164.8],
		"vol": 0.10
	},
	"ruins": {
		"name_th": "เสียงสะท้อนใต้รากไม้โบราณ",
		"step_sec": 0.64,
		"notes": [220.0, 261.6, 329.6, 415.3, 440.0, 415.3, 329.6, 261.6, 246.9, 293.7, 329.6, 392.0, 329.6, 293.7, 261.6, 220.0],
		"harm":  [164.8, 196.0, 246.9, 329.6, 329.6, 293.7, 246.9, 196.0, 185.0, 220.0, 246.9, 293.7, 246.9, 220.0, 196.0, 164.8],
		"bass":  [110.0, 130.8, 123.5, 110.0],
		"vol": 0.12
	},
	"wedding": {
		"name_th": "คำสัญญาใต้กลีบใบไม้ทอง",
		"step_sec": 0.48,
		"notes": [293.7, 369.9, 440.0, 587.3, 659.3, 739.9, 587.3, 440.0, 392.0, 493.9, 587.3, 739.9, 659.3, 587.3, 493.9, 440.0],
		"harm":  [220.0, 293.7, 369.9, 440.0, 493.9, 587.3, 440.0, 369.9, 293.7, 392.0, 440.0, 587.3, 493.9, 440.0, 392.0, 369.9],
		"bass":  [146.8, 110.0, 123.5, 196.0],
		"vol": 0.14
	}
}

var audio_enabled: bool = true
var bgm_volume: float = 0.75
var sfx_volume: float = 0.85
var current_zone: String = "plaza"
var override_zone: String = ""

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _voices: Array[Dictionary] = []
var _bgm_timer: float = 0.0
var _note_idx: int = 0
var _amb_phase: float = 0.0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.12
	_player.stream = gen
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

func set_zone(zone_id: String) -> void:
	if BGM_THEMES.has(zone_id) and zone_id != current_zone:
		current_zone = zone_id
		_note_idx = 0
		_bgm_timer = 0.05

func get_current_bgm_title() -> String:
	var z := override_zone if (override_zone != "" and BGM_THEMES.has(override_zone)) else current_zone
	return BGM_THEMES.get(z, BGM_THEMES["plaza"])["name_th"]

func add_tone(freq: float, dur: float, vol: float = 0.16, delay: float = 0.0, triangle: bool = false, is_bgm: bool = false) -> void:
	if not audio_enabled:
		return
	var scaled_vol := vol * (bgm_volume if is_bgm else sfx_volume)
	if scaled_vol <= 0.002:
		return
	_voices.append({
		"freq": freq,
		"dur": maxf(0.03, dur),
		"vol": scaled_vol,
		"delay": delay,
		"t": 0.0,
		"phase": 0.0,
		"tri": triangle
	})

func play_voice(char_id: String) -> void:
	if not audio_enabled:
		return
	var pitch_map := {
		"01_ren": 480.0, "02_marcus": 420.0, "03_lilian": 640.0, "04_eli": 450.0,
		"05_kyo": 560.0, "06_sora": 590.0, "07_sera": 710.0, "08_roland": 320.0,
		"09_celeste": 610.0, "10_lucian": 380.0, "11_pip": 680.0, "12_trixie": 740.0,
		"13_mirelle": 660.0, "14_kael": 360.0, "15_thorn": 270.0, "16_bram": 250.0
	}
	var base_f := float(pitch_map.get(char_id, 520.0))
	add_tone(base_f + randf_range(-25.0, 35.0), 0.055, 0.11, 0.0, true, false)

func play_sfx(kind: String) -> void:
	if not audio_enabled:
		return
	match kind:
		"talk":
			add_tone(520.0 + randf() * 130.0, 0.05, 0.10, 0.0, true)
		"door":
			add_tone(260.0, 0.09, 0.15)
			add_tone(390.0, 0.12, 0.13, 0.06)
		"coin":
			add_tone(880.0, 0.08, 0.15)
			add_tone(1175.0, 0.16, 0.15, 0.07)
		"heart":
			add_tone(523.25, 0.10, 0.14)
			add_tone(659.25, 0.10, 0.14, 0.08)
			add_tone(783.99, 0.20, 0.16, 0.16)
		"quest", "build":
			var notes := [523.25, 659.25, 783.99, 1046.5]
			for i in notes.size():
				add_tone(notes[i], 0.16, 0.15, i * 0.08, true)
		"sparkle":
			add_tone(1046.5, 0.08, 0.13)
			add_tone(1318.5, 0.12, 0.13, 0.06)
		"splash":
			add_tone(190.0, 0.12, 0.16, 0.0, true)
			add_tone(320.0, 0.14, 0.13, 0.06)
		"miss":
			add_tone(185.0, 0.16, 0.14, 0.0, true)
		"beam":
			add_tone(660.0, 0.09, 0.15)
			add_tone(990.0, 0.14, 0.14, 0.05)
		"anvil":
			add_tone(220.0, 0.07, 0.18, 0.0, true)
			add_tone(880.0, 0.12, 0.15, 0.02, true)
		"concert", "wedding":
			var wnotes := [293.7, 369.9, 440.0, 587.3, 739.9, 880.0]
			for i in wnotes.size():
				add_tone(wnotes[i], 0.28, 0.15, i * 0.10)

func _process(delta: float) -> void:
	if audio_enabled and bgm_volume > 0.01:
		_bgm_timer -= delta
		if _bgm_timer <= 0.0:
			var z := override_zone if (override_zone != "" and BGM_THEMES.has(override_zone)) else current_zone
			var th: Dictionary = BGM_THEMES.get(z, BGM_THEMES["plaza"])
			var step_s: float = th["step_sec"]
			_bgm_timer = step_s
			var is_night := (GameState.time_min >= 18.5 * 60.0 or GameState.time_min < 6.0 * 60.0) and GameState.current_scene == "outdoor"
			var mult := 0.84 if is_night else 1.0
			var notes: Array = th["notes"]
			var harm: Array = th["harm"]
			var bass: Array = th["bass"]
			var idx := _note_idx % notes.size()
			add_tone(float(notes[idx]) * mult, step_s * 0.86, float(th["vol"]), 0.0, false, true)
			if _note_idx % 2 == 0:
				add_tone(float(harm[idx % harm.size()]) * mult, step_s * 1.15, float(th["vol"]) * 0.48, 0.0, false, true)
			if _note_idx % 4 == 0:
				add_tone(float(bass[(_note_idx / 4) % bass.size()]) * mult, step_s * 1.8, float(th["vol"]) * 0.62, 0.0, true, true)
			_note_idx += 1

	if _playback == null:
		_voices.clear()
		return

	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var inv_rate := 1.0 / MIX_RATE
	var rain_amb := audio_enabled and GameState.current_scene == "outdoor" and GameState.weather == "rainy" and sfx_volume > 0.05
	var ruins_amb := audio_enabled and GameState.current_scene.begins_with("ruins_") and sfx_volume > 0.05
	for _f in frames:
		var sample := 0.0
		for i in range(_voices.size() - 1, -1, -1):
			var v: Dictionary = _voices[i]
			if float(v["delay"]) > 0.0:
				v["delay"] = float(v["delay"]) - inv_rate
				continue
			var t: float = float(v["t"])
			var dur: float = float(v["dur"])
			if t >= dur:
				_voices.remove_at(i)
				continue
			var env := minf(1.0, t / 0.012) * maxf(0.0, 1.0 - (t / dur))
			var ph: float = float(v["phase"])
			var osc := (2.0 * absf(2.0 * (ph - floorf(ph + 0.5))) - 1.0) if bool(v["tri"]) else sin(ph * TAU)
			sample += osc * env * float(v["vol"])
			v["phase"] = fmod(ph + float(v["freq"]) * inv_rate, 1.0)
			v["t"] = t + inv_rate
		if rain_amb:
			sample += randf_range(-1.0, 1.0) * 0.014 * sfx_volume
		elif ruins_amb:
			_amb_phase = fmod(_amb_phase + 74.0 * inv_rate, 1.0)
			sample += sin(_amb_phase * TAU) * 0.016 * sfx_volume
		sample = clampf(sample, -0.85, 0.85)
		_playback.push_frame(Vector2(sample, sample))
