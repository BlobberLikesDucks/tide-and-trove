extends Node
## Phase-driven music with crossfades, plus a pooled SFX player.

const MUSIC := {
	"prep": "res://assets/audio/music_prep.wav",
	"open": "res://assets/audio/music_open.wav",
	"closing": "res://assets/audio/music_closing.wav",
}

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _current := ""
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _make_player("Music")
	_b = _make_player("Music")
	for i in range(14):
		_pool.append(_make_player("SFX"))


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _load(path: String, loop: bool) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var s = load(path)
	if s is AudioStreamWAV and loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		# frames = bytes / (2 bytes per sample * channels); the v2 score is stereo 16-bit
		s.loop_end = int(s.data.size() / (2 * (2 if s.stereo else 1)))
	_cache[path] = s
	return s


func play_music(key: String, fade: float = 1.6) -> void:
	if key == _current:
		return
	_current = key
	var stream := _load(MUSIC.get(key, ""), true)
	if stream == null:
		return
	var incoming := _b if _a.playing else _a
	var outgoing := _a if incoming == _b else _b
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(incoming, "volume_db", 0.0, fade)
	if outgoing.playing:
		_tween.tween_property(outgoing, "volume_db", -40.0, fade)
		_tween.chain().tween_callback(outgoing.stop)


func sfx(id: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var s := _load("res://assets/audio/sfx_%s.wav" % id, false)
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.pitch_scale = pitch * randf_range(0.96, 1.04)
	p.volume_db = volume_db
	p.play()
