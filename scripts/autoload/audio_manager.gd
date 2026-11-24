extends Node
## AudioManager Autoload — Real-Time Procedural Polyphonic Synthesizer in GDScript
## Generates 7 Zone-Specific Dynamic BGM Tracks + Crisp Cozy SFX with zero external audio files.

const MIX_RATE := 22050.0

const BGM_THEMES := {
	"plaza": {
		"name_th": "ลมหายใจต้นไม้โลก",
		"step_sec": 0.54,
		"notes": [261.6, 329.6, 392.0, 493.9, 523.3, 493.9, 392.0, 329.6, 293.7, 369.9, 440.0, 392.0],
		"bass": [130.8, 130.8, 146.8, 196.0],
		"vol": 0.11
	},
	"home": {
		"name_th": "อ้อมกอดกระท่อมรากไม้ทอง",
		"step_sec": 0.64,
		"notes": [349.2, 440.0, 523.3, 440.0, 392.0, 523.3, 659.3, 523.3, 349.2, 440.0, 587.3, 523.3],
		"bass": [174.6, 130.8, 146.8, 130.8],
		"vol": 0.10
	},
	"tavern": {
		"name_th": "ค่ำคืนโรงเตี๊ยมตะเกียงมอส",
		"step_sec": 0.38,
		"notes": [392.0, 493.9, 587.3, 659.3, 587.3, 493.9, 440.0, 523.3, 659.3, 587.3, 493.9, 392.0],
		"bass": [196.0, 146.8, 164.8, 146.8],
		"vol": 0.12
	},
	"smithy": {
		"name_th": "จังหวะค้อนศิลาเพลิง",
		"step_sec": 0.44,
		"notes": [293.7, 349.2, 440.0, 293.7, 392.0, 440.0, 523.3, 440.0, 349.2, 329.6, 293.7, 261.6],
		"bass": [146.8, 146.8, 130.8, 146.8],
		"vol": 0.11
	},
	"nature": {
		"name_th": "เพลงพรายน้ำและพงไพร",
		"step_sec": 0.60,
		"notes": [329.6, 392.0, 440.0, 587.3, 659.3, 587.3, 440.0, 392.0, 329.6, 493.9, 587.3, 440.0],
		"bass": [164.8, 196.0, 146.8, 164.8],
		"vol": 0.10
	},
	"ruins": {
		"name_th": "เสียงสะท้อนใต้รากไม้โบราณ",
		"step_sec": 0.68,
		"notes": [220.0, 261.6, 329.6, 415.3, 440.0, 415.3, 329.6, 261.6, 246.9, 293.7, 329.6, 220.0],
		"bass": [110.0, 130.8, 123.5, 110.0],
		"vol": 0.12
	},
	"wedding": {
		"name_th": "คำสัญญาใต้กลีบใบไม้ทอง",
		"step_sec": 0.50,
		"notes": [293.7, 369.9, 440.0, 587.3, 659.3, 739.9, 587.3, 440.0, 392.0, 493.9, 587.3, 739.9],
		"bass": [146.8, 110.0, 123.5, 196.0],
		"vol": 0.14
	}
}

var audio_enabled: bool = true
var current_zone: String = "plaza"
var override_zone: String = ""

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _voices: Array[Dictionary] = []
var _bgm_timer: float = 0.0
var _note_idx: int = 0

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

func add_tone(freq: float, dur: float, vol: float = 0.16, delay: float = 0.0, triangle: bool = false) -> void:
	if not audio_enabled:
		return
	_voices.append({
		"freq": freq,
		"dur": maxf(0.03, dur),
		"vol": vol,
		"delay": delay,
		"t": 0.0,
		"phase": 0.0,
		"tri": triangle
	})

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
	if audio_enabled:
		_bgm_timer -= delta
		if _bgm_timer <= 0.0:
			var z := override_zone if (override_zone != "" and BGM_THEMES.has(override_zone)) else current_zone
			var th: Dictionary = BGM_THEMES.get(z, BGM_THEMES["plaza"])
			var step_s: float = th["step_sec"]
			_bgm_timer = step_s
			var is_night := (GameState.time_min >= 18.5 * 60.0 or GameState.time_min < 6.0 * 60.0) and GameState.current_scene == "outdoor"
			var mult := 0.84 if is_night else 1.0
			var notes: Array = th["notes"]
			var bass: Array = th["bass"]
			add_tone(float(notes[_note_idx % notes.size()]) * mult, step_s * 0.86, float(th["vol"]))
			if _note_idx % 3 == 0:
				add_tone(float(bass[(_note_idx / 3) % bass.size()]) * mult, step_s * 1.5, float(th["vol"]) * 0.65, 0.0, true)
			_note_idx += 1

	if _playback == null:
		_voices.clear()
		return

	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var inv_rate := 1.0 / MIX_RATE
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
		sample = clampf(sample, -0.85, 0.85)
		_playback.push_frame(Vector2(sample, sample))
