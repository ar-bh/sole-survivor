extends Camera2D

# --- AI: horizontal follow speed (higher = snappier catch-up) ---
const HORIZONTAL_FOLLOW := 18.0

# --- AI: cached player ref + locked camera height ---
var _player: Node2D
var _lock_y: float


func _ready() -> void:
	_player = get_parent()
	# AI: detach from player transform; we set global_position manually each frame.
	top_level = true
	global_position = _player.global_position
	_lock_y = global_position.y


func _physics_process(delta: float) -> void:
	# AI: follow player on X only — Y stays at spawn so jumps don't move the camera.
	global_position.x = lerpf(global_position.x, _player.global_position.x, HORIZONTAL_FOLLOW * delta)
	global_position.y = _lock_y
