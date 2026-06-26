extends CharacterBody2D

# --- YOU: core node refs ---
@onready var skin_root: Node2D = $Skin
@onready var skin: AnimatedSprite2D = $Skin/Body
@onready var label: RichTextLabel = $CanvasLayer/Label

# --- AI: procedural leg node refs (Line2D children under Skin, flip with body) ---
@onready var walk_legs: Node2D = $Skin/WalkLegs
@onready var left_leg: Line2D = $Skin/WalkLegs/LeftLeg
@onready var right_leg: Line2D = $Skin/WalkLegs/RightLeg

# --- AI: procedural arm node refs (same idea as legs) ---
@onready var walk_arm_connects: Node2D = $Skin/WalkArmConnects
@onready var left_arm_connect: Line2D = $Skin/WalkArmConnects/LeftArmConnect
@onready var right_arm_connect: Line2D = $Skin/WalkArmConnects/RightArmConnect
@onready var walk_arms: Node2D = $Skin/WalkArms
@onready var left_arm: Line2D = $Skin/WalkArms/LeftArm
@onready var right_arm: Line2D = $Skin/WalkArms/RightArm
@onready var left_fist: Node2D = $Skin/WalkArms/LeftFist
@onready var right_fist: Node2D = $Skin/WalkArms/RightFist
@onready var left_shoe: Node2D = $Skin/WalkLegs/LeftShoe
@onready var right_shoe: Node2D = $Skin/WalkLegs/RightShoe

# --- AI: Jordan-style shoe bricks — set false or delete WalkLegs/*Shoe nodes to remove. ---
const SHOES_ENABLED := true
const SHOE_ROW_COUNT := 5
const SHOE_UP_OFFSET := 1.0
@export var shoe_color := Color(1.0, 0.55, 0.0)
@export var shoe_toe_color := Color(1.0, 0.68, 0.18)
@export var shoe_collar_color := Color(0.82, 0.32, 0.0)
@export var shoe_sole_color := Color.BLACK
@export var shoe_swoosh_color := Color.WHITE

# --- YOU: movement speeds ---
const STANDING_SPEED := 300.0
const HANDSTAND_SPEED:= 800.0
const GRAVITY := 980.0

# --- YOU: jump values ---
const STANDING_JUMP_VELOCITY := -600.0
const ORIGINAL_HANDSTAND_JUMP_VELOCITY := -360.0
var handstand_jump_velocity := ORIGINAL_HANDSTAND_JUMP_VELOCITY

# --- YOU: acceleration / friction ---
const ACCELERATION := 1500.0
const FRICTION := 1500.0

# --- YOU: runtime movement state ---
var target_max_speed := STANDING_SPEED
var handstand_bonus := 0
var handstand_mode := false

# --- AI: controller rumble strength while handstanding ---
const HANDSTAND_RUMBLE_WEAK := 0.12
const HANDSTAND_RUMBLE_STRONG := 0.08

# --- AI: leg tuning (32x32 Skin local space, sprite center = origin) ---
#         positive Y = down. tweak these if feet/hips look wrong.
const IDLE_HIP_Y := 5.3
const IDLE_HIP_SPREAD := 1.75
const IDLE_LEG_LENGTH := 10.5
const WALK_HIP_Y := 6
const WALK_HIP_SPREAD := 2.0
const WALK_LEG_LENGTH := 10.5
const WALK_LEG_SWING := deg_to_rad(32.0)
const WALK_LEG_SPEED := 16.0
const STANDING_LEG_BLEND_SPEED := 10.0
const STANDING_WALK_VELOCITY_BLEND := 120.0
const STANDING_FALL_MOVE_THRESHOLD := 10.0
const STANDING_AIR_RISE_VELOCITY := 30.0
const STANDING_AIR_FALL_VELOCITY := 30.0
const STANDING_AIR_LEG_RISE_TILT := deg_to_rad(-7.0)
const STANDING_AIR_LEG_FALL_TILT := deg_to_rad(6.0)
const STANDING_AIR_ARM_DANGLE_MAX := deg_to_rad(18.0)
const STANDING_AIR_ARM_FALL_TILT := deg_to_rad(5.0)
const STANDING_AIR_ARM_RAISE_ANGLE := deg_to_rad(118.0)
const STANDING_AIR_ARM_FALL_ANGLE := deg_to_rad(-6.0)
const STANDING_AIR_MOVE_LEG_LEAN := deg_to_rad(4.0)
const STANDING_AIR_MOVE_ARM_LEAN := deg_to_rad(3.0)
const STANDING_AIR_RISE_VEL_SCALE := 420.0
const STANDING_AIR_FALL_VEL_SCALE := 520.0
const STANDING_AIR_LEG_LAG := 9.0
const STANDING_AIR_ARM_LAG := 3.5
const STANDING_AIR_ARM_SWAY_ANGLE := deg_to_rad(4.0)
const STANDING_AIR_ARM_SWAY_SPEED := 8.5
const STANDING_AIR_ARM_SWAY_DAMP := 5.0
const STANDING_AIR_ARM_JUMP_SWAY := deg_to_rad(5.0)
const HANDSTAND_IDLE_ANIM_SPEED := 0.35
const HANDSTAND_MOVE_ANIM_SPEED := 1.0
const HANDSTAND_HIP_Y := -3.0
const HANDSTAND_HIP_SPREAD := 2.0
const HANDSTAND_LEG_LENGTH := 9.5
const SHOE_HANDSTAND_TRIM := 3.5
const HANDSTAND_REST_SPREAD := deg_to_rad(14.0)
const HANDSTAND_WOBBLE_SWING := deg_to_rad(4.0)
const HANDSTAND_WOBBLE_SPEED := 4.0

# --- AI TEST: handstand run — full limbs + handstand_idle anim. set false to revert. ---
const HANDSTAND_RUN_TEST := true
const HANDSTAND_RUN_SPEED_THRESHOLD := 10.0
const HANDSTAND_RUN_LEG_WOBBLE_SPEED := 14.0
const HANDSTAND_RUN_LEG_WOBBLE_SWING := deg_to_rad(10.0)
const HANDSTAND_RUN_STEP_SPEED := 14.0
const HANDSTAND_RUN_HAND_FORWARD := 5.0
const HANDSTAND_RUN_HAND_LIFT := 3.5
const HANDSTAND_RUN_ELBOW_REACH := 0.45
const HANDSTAND_RUN_BODY_BOB := 3.5
const HANDSTAND_RUN_BODY_BOB_ENABLED := true
const HANDSTAND_RUN_SHOULDER_SHIFT := 0.6
const HANDSTAND_RUN_CONNECT_REACH := 0.45

# --- AI: smooth blends between limb states (idle/walk, handstand idle/run, body bob). ---
const LIMB_BLEND_SPEED := 8.0
const HANDSTAND_RUN_BLEND_IN_START := 10.0
const HANDSTAND_RUN_BLEND_IN_END := 90.0

# --- AI: arm tuning (same coordinate space as legs) ---
#         standing = one straight segment. handstand = shoulder → elbow → hand + fist pixels.
const STANDING_IDLE_ARM_LENGTH := 7.5
const STANDING_WALK_ARM_LENGTH := 7.5
const STANDING_ARM_SWING := deg_to_rad(12.0)
const STANDING_ARM_SPEED := 13.0
const STANDING_ARM_PHASE_OFFSET := PI * 0.5
const STANDING_SHOULDER_Y := 1.0
const STANDING_SHOULDER_OUT := 5.5
# AI: handstand arms — fixed side attach; only shoulder_y bobs with idle anim frames.
const HANDSTAND_SHOULDER_LEFT := -8.0
const HANDSTAND_SHOULDER_RIGHT := 9.0
const HANDSTAND_BASE_SHOULDER_Y := 2.0
const HANDSTAND_BASE_HAND_DROP := 12.0
# AI: inner x edge of green body — connect stub stops here, never crosses past the torso.
const HANDSTAND_BODY_EDGE_LEFT := -3.0
const HANDSTAND_BODY_EDGE_RIGHT := 3.0
const HANDSTAND_ELBOW_OUT := 3.5
const HANDSTAND_ELBOW_DROP := 1.5
const HANDSTAND_HAND_IN := 2.5
const HANDSTAND_IDLE_FRAME_SHOULDER_Y := [2.0, 3.0]
const FIST_WIDTH := 3
const FIST_HEIGHT := 2
# AI: fist brick spans x -1..1; anchor node on hand tip centers it (right uses scale.x = -1).
const FIST_CENTER_X := 0.0

# --- AI: leg animation timers / blend state ---
var _walk_leg_phase := 0.0
var _handstand_leg_phase := 0.0
var _standing_leg_blend := 0.0
var _standing_air_leg_tilt := 0.0
var _standing_air_arm_tilt := 0.0
var _standing_air_arm_sway := 0.0
var _standing_air_arm_sway_vel := 0.0
var _standing_air_time := 0.0
var _standing_air_vertical_jump := false
var _standing_air_jump_style_locked := false
var _standing_air_face_right := true

# --- AI: arm animation timers ---
var _walk_arm_phase := 0.0
var _handstand_arm_phase := 0.0
var _handstand_run_blend := 0.0
var _skin_bob_current := 0.0

# --- AI: last horizontal facing (used while idle so sprite doesn't flip back) ---
var _face_right := true
var _skin_base_pos := Vector2.ZERO


func _ready() -> void:
	_skin_base_pos = skin_root.position
	_setup_walk_legs()
	_setup_walk_arms()
	_setup_shoes()


# --- YOU: main movement loop ---
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if handstand_mode:
		target_max_speed = HANDSTAND_SPEED
	else:
		target_max_speed = STANDING_SPEED

	var direction := Input.get_axis("left", "right")
	if direction != 0:
		var target_velocity_x = direction * target_max_speed
		if handstand_mode:
			velocity.x = move_toward(velocity.x, target_velocity_x+(direction*handstand_bonus), ACCELERATION * delta)
			handstand_bonus += 10
			handstand_jump_velocity = ORIGINAL_HANDSTAND_JUMP_VELOCITY - (handstand_bonus / 10.0)
			if handstand_bonus >= 500:
				handstand_bonus = 500
		else:
			velocity.x = move_toward(velocity.x, target_velocity_x, ACCELERATION * delta)
			handstand_bonus = 0
			handstand_jump_velocity = ORIGINAL_HANDSTAND_JUMP_VELOCITY
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		handstand_bonus = 0
		handstand_jump_velocity = ORIGINAL_HANDSTAND_JUMP_VELOCITY

	if Input.is_action_just_pressed("jump") and is_on_floor():
		if handstand_mode:
			velocity.y = handstand_jump_velocity
		else:
			velocity.y = STANDING_JUMP_VELOCITY
			_standing_air_vertical_jump = _standing_jump_is_vertical()
			_standing_air_jump_style_locked = true
			_standing_air_face_right = _standing_jump_face_right()
			_standing_air_time = 0.0
			_standing_air_arm_sway = 0.0
			if _standing_air_vertical_jump:
				_standing_air_arm_sway_vel = 0.0
				_standing_air_arm_tilt = 0.0
			else:
				_standing_air_arm_sway_vel = (
					STANDING_AIR_ARM_JUMP_SWAY
					if _standing_air_face_right
					else -STANDING_AIR_ARM_JUMP_SWAY
				)

	move_and_slide()
	_update_handstand_mode()

	_handle_animations()

	#extra stuff
	label.text = "velocity:x\n" + str(velocity.x)
	_update_handstand_rumble()


# --- AI: legs + arms update every rendered frame (not tied to physics tick) ---
func _process(delta: float) -> void:
	_update_limb_blends(delta)
	_update_legs(delta)
	_update_arms(delta)


# --- AI: ease between movement states so limbs/bob don't snap. ---
func _update_limb_blends(delta: float) -> void:
	var run_target := 0.0
	if handstand_mode and HANDSTAND_RUN_TEST and is_on_floor():
		run_target = _handstand_run_target_blend()
	_handstand_run_blend = move_toward(_handstand_run_blend, run_target, LIMB_BLEND_SPEED * delta)

	if not handstand_mode or _handstand_run_blend <= 0.001:
		_skin_bob_current = move_toward(_skin_bob_current, 0.0, LIMB_BLEND_SPEED * delta)
		skin_root.position.y = _skin_base_pos.y - _skin_bob_current


func _handstand_run_target_blend() -> float:
	return clampf(
		(absf(velocity.x) - HANDSTAND_RUN_BLEND_IN_START) / (HANDSTAND_RUN_BLEND_IN_END - HANDSTAND_RUN_BLEND_IN_START),
		0.0,
		1.0,
	)


# --- AI: one-time leg line setup ---
func _setup_walk_legs() -> void:
	for leg: Line2D in [left_leg, right_leg]:
		leg.width = 1.0
		leg.default_color = Color.BLACK
		leg.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, IDLE_LEG_LENGTH)])

	left_leg.position = Vector2(-IDLE_HIP_SPREAD, IDLE_HIP_Y)
	right_leg.position = Vector2(IDLE_HIP_SPREAD, IDLE_HIP_Y)


func _setup_shoes() -> void:
	_build_jordan_shoe(left_shoe, false)
	_build_jordan_shoe(right_shoe, true)


func _build_jordan_shoe(parent: Node2D, mirror: bool) -> void:
	for child in parent.get_children():
		child.free()

	# O=upper, T=toe cap, W=swoosh, C=collar, B=sole — tiny AJ1-ish silhouette
	var pattern := PackedStringArray([
		" COCOC ",
		" OOOOO ",
		"OOTWWO ",
		"OOWWOOO",
		"BBBBBBB",
	])
	for row in range(pattern.size()):
		var line := pattern[row]
		for col in range(line.length()):
			var pixel := line[col]
			if pixel == " ":
				continue
			var draw_col := line.length() - 1 - col if mirror else col
			var block := ColorRect.new()
			block.size = Vector2(1.0, 1.0)
			block.position = Vector2(float(draw_col) - line.length() * 0.5 + 0.5, float(row))
			match pixel:
				"O":
					block.color = shoe_color
				"T":
					block.color = shoe_toe_color
				"W":
					block.color = shoe_swoosh_color
				"C":
					block.color = shoe_collar_color
				"B":
					block.color = shoe_sole_color
				_:
					block.color = shoe_color
			parent.add_child(block)


func _shoe_leg_trim() -> float:
	if handstand_mode:
		return SHOE_HANDSTAND_TRIM
	return SHOE_ROW_COUNT + SHOE_UP_OFFSET


func _leg_foot_tip(tip: Vector2) -> Vector2:
	if not SHOES_ENABLED or tip.length_squared() < 0.001:
		return tip
	return tip - tip.normalized() * _shoe_leg_trim()


func _place_shoe_on_leg(shoe: Node2D, leg: Line2D) -> void:
	var tip := leg.points[1]
	if tip.length_squared() < 0.001:
		return
	shoe.rotation = tip.angle() - PI / 2.0
	shoe.position = leg.position + tip


func _update_shoes() -> void:
	if not SHOES_ENABLED:
		left_shoe.visible = false
		right_shoe.visible = false
		return

	left_shoe.visible = walk_legs.visible
	right_shoe.visible = walk_legs.visible
	if not walk_legs.visible:
		return

	_place_shoe_on_leg(left_shoe, left_leg)
	_place_shoe_on_leg(right_shoe, right_leg)


# --- AI: pick leg pose from player state ---
func _update_legs(delta: float) -> void:
	if handstand_mode:
		if not is_on_floor():
			walk_legs.visible = false
			_update_shoes()
			return
		if _is_handstand_running() and not HANDSTAND_RUN_TEST:
			walk_legs.visible = false
			_update_shoes()
			return
		walk_legs.visible = true
		_set_leg_hips(HANDSTAND_HIP_Y, HANDSTAND_HIP_SPREAD)
		_update_handstand_legs(delta)
		_update_shoes()
		return

	walk_legs.visible = true
	_update_standing_legs(delta)
	_update_shoes()


# --- AI: move both leg hip anchors (top of each Line2D) ---
func _set_leg_hips(hip_y: float, hip_spread: float) -> void:
	left_leg.position = Vector2(-hip_spread, hip_y)
	right_leg.position = Vector2(hip_spread, hip_y)


# --- AI: standing legs — walk swing on floor; subtle state tilt in air. ---
func _update_standing_legs(delta: float) -> void:
	var target_blend := 0.0
	if is_on_floor():
		var input_walk := Input.get_axis("left", "right") != 0.0
		var velocity_walk := clampf(absf(velocity.x) / STANDING_WALK_VELOCITY_BLEND, 0.0, 1.0)
		target_blend = 1.0 if input_walk else velocity_walk
	_standing_leg_blend = move_toward(_standing_leg_blend, target_blend, STANDING_LEG_BLEND_SPEED * delta)
	_update_standing_air_limb_tilts(delta)

	var hip_y := lerpf(IDLE_HIP_Y, WALK_HIP_Y, _standing_leg_blend)
	var hip_spread := lerpf(IDLE_HIP_SPREAD, WALK_HIP_SPREAD, _standing_leg_blend)
	var leg_length := lerpf(IDLE_LEG_LENGTH, WALK_LEG_LENGTH, _standing_leg_blend)
	_set_leg_hips(hip_y, hip_spread)

	if is_on_floor() and _standing_leg_blend > 0.01:
		_walk_leg_phase += delta * WALK_LEG_SPEED * _standing_leg_blend

	var left_swing := 0.0
	var right_swing := 0.0
	if is_on_floor():
		var swing := sin(_walk_leg_phase) * WALK_LEG_SWING * _standing_leg_blend
		left_swing = swing
		right_swing = -swing
	else:
		left_swing = _standing_air_leg_tilt
		right_swing = _standing_air_leg_tilt
	var left_tip := Vector2(sin(left_swing), cos(left_swing)) * leg_length
	var right_tip := Vector2(sin(right_swing), cos(right_swing)) * leg_length
	if not is_on_floor():
		left_tip = _standing_air_mirror_tip(left_tip)
		right_tip = _standing_air_mirror_tip(right_tip)
	left_tip = _leg_foot_tip(left_tip)
	right_tip = _leg_foot_tip(right_tip)
	left_leg.points = PackedVector2Array([
		Vector2.ZERO,
		left_tip,
	])
	right_leg.points = PackedVector2Array([
		Vector2.ZERO,
		right_tip,
	])


func _update_standing_air_limb_tilts(delta: float) -> void:
	var leg_target := 0.0
	var arm_target := 0.0
	if is_on_floor():
		if not _standing_air_jump_style_locked:
			_standing_air_vertical_jump = false
			_standing_air_arm_sway = 0.0
			_standing_air_arm_sway_vel = 0.0
			_standing_air_arm_tilt = 0.0
		_standing_air_jump_style_locked = false
		_standing_air_time = 0.0
	else:
		_standing_air_time += delta
		leg_target = _standing_air_leg_tilt_target()
		if _standing_air_vertical_jump:
			arm_target = _standing_air_vertical_arm_angle_target()
		else:
			arm_target = _standing_air_arm_tilt_target()
			_update_standing_air_arm_sway(delta)

	_standing_air_leg_tilt = _smooth_air_follow(
		_standing_air_leg_tilt,
		leg_target,
		STANDING_AIR_LEG_LAG,
		delta,
	)
	_standing_air_arm_tilt = _smooth_air_follow(
		_standing_air_arm_tilt,
		arm_target,
		STANDING_AIR_ARM_LAG,
		delta,
	)


func _smooth_air_follow(current: float, target: float, lag: float, delta: float) -> float:
	return lerpf(current, target, 1.0 - exp(-lag * delta))


func _standing_jump_is_vertical() -> bool:
	return Input.get_axis("left", "right") == 0.0


func _standing_jump_face_right() -> bool:
	var move_dir := Input.get_axis("left", "right")
	if move_dir != 0.0:
		return move_dir > 0.0
	if absf(velocity.x) > 1.0:
		return velocity.x > 0.0
	return _face_right


func _standing_air_mirror_tip(tip: Vector2) -> Vector2:
	if _standing_air_face_right:
		return tip
	return Vector2(-tip.x, tip.y)


func _standing_air_arm_tip(angle: float, length: float, side: float) -> Vector2:
	return Vector2(sin(angle * side), cos(angle)) * length


func _standing_air_rise_amount() -> float:
	return clampf(-velocity.y / STANDING_AIR_RISE_VEL_SCALE, 0.0, 1.0)


func _standing_air_fall_amount() -> float:
	return clampf(velocity.y / STANDING_AIR_FALL_VEL_SCALE, 0.0, 1.0)


func _standing_air_move_amount() -> float:
	return clampf(absf(velocity.x) / STANDING_WALK_VELOCITY_BLEND, 0.0, 1.0)


func _standing_air_leg_tilt_target() -> float:
	var rise := _standing_air_rise_amount()
	var fall := _standing_air_fall_amount()
	var move := _standing_air_move_amount()
	var tilt := rise * STANDING_AIR_LEG_RISE_TILT * (1.0 - fall) + fall * STANDING_AIR_LEG_FALL_TILT
	if move > 0.0:
		tilt -= STANDING_AIR_MOVE_LEG_LEAN * move
	return tilt


func _standing_air_arm_tilt_target() -> float:
	var rise := _standing_air_rise_amount()
	var fall := _standing_air_fall_amount()
	var move := _standing_air_move_amount()
	var tilt := rise * STANDING_AIR_ARM_DANGLE_MAX * (1.0 - fall) + fall * STANDING_AIR_ARM_FALL_TILT
	if move > 0.0:
		tilt += STANDING_AIR_MOVE_ARM_LEAN * move
	return tilt


func _standing_air_vertical_arm_angle_target() -> float:
	var rise := _standing_air_rise_amount()
	var fall := _standing_air_fall_amount()
	return rise * STANDING_AIR_ARM_RAISE_ANGLE * (1.0 - fall) + fall * STANDING_AIR_ARM_FALL_ANGLE


func _update_standing_air_arm_sway(delta: float) -> void:
	var rise := _standing_air_rise_amount()
	if rise <= 0.05:
		var settle := 1.0 - exp(-STANDING_AIR_ARM_SWAY_DAMP * delta)
		_standing_air_arm_sway = lerpf(_standing_air_arm_sway, 0.0, settle)
		_standing_air_arm_sway_vel = lerpf(_standing_air_arm_sway_vel, 0.0, settle)
		return

	var bob := sin(_standing_air_time * STANDING_AIR_ARM_SWAY_SPEED) * STANDING_AIR_ARM_SWAY_ANGLE * rise
	var fade := exp(-_standing_air_time * 1.8)
	bob *= fade
	_standing_air_arm_sway_vel += (bob - _standing_air_arm_sway) * 24.0 * delta
	_standing_air_arm_sway_vel *= exp(-STANDING_AIR_ARM_SWAY_DAMP * delta)
	_standing_air_arm_sway += _standing_air_arm_sway_vel * delta


# --- AI: handstand legs — wobble blends idle ↔ run. ---
func _update_handstand_legs(delta: float) -> void:
	var wobble_speed := lerpf(HANDSTAND_WOBBLE_SPEED, HANDSTAND_RUN_LEG_WOBBLE_SPEED, _handstand_run_blend)
	var wobble_swing := lerpf(HANDSTAND_WOBBLE_SWING, HANDSTAND_RUN_LEG_WOBBLE_SWING, _handstand_run_blend)
	_handstand_leg_phase += delta * wobble_speed
	var wobble := sin(_handstand_leg_phase) * wobble_swing
	var left_angle := -HANDSTAND_REST_SPREAD + wobble
	var right_angle := HANDSTAND_REST_SPREAD - wobble
	var left_tip := Vector2(sin(left_angle), -cos(left_angle)) * HANDSTAND_LEG_LENGTH
	var right_tip := Vector2(sin(right_angle), -cos(right_angle)) * HANDSTAND_LEG_LENGTH
	left_leg.points = PackedVector2Array([
		Vector2.ZERO,
		_leg_foot_tip(left_tip),
	])
	right_leg.points = PackedVector2Array([
		Vector2.ZERO,
		_leg_foot_tip(right_tip),
	])


# --- AI: one-time arm line setup ---
func _setup_walk_arms() -> void:
	for arm: Line2D in [left_arm, right_arm, left_arm_connect, right_arm_connect]:
		arm.width = 1.0
		arm.default_color = Color.BLACK

	for arm: Line2D in [left_arm, right_arm]:
		arm.points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(0.0, STANDING_IDLE_ARM_LENGTH),
		])

	left_arm_connect.visible = false
	right_arm_connect.visible = false

	_build_fist_brick(left_fist)
	_build_fist_brick(right_fist)
	left_fist.scale = Vector2(1.0, 1.0)
	right_fist.scale = Vector2(-1.0, 1.0)
	left_fist.visible = false
	right_fist.visible = false


# --- AI: fixed 3x2 black fist brick centered on the hand tip. ---
func _build_fist_brick(parent: Node2D) -> void:
	for child in parent.get_children():
		child.free()

	for row in range(FIST_HEIGHT):
		for col in range(FIST_WIDTH):
			var block := ColorRect.new()
			block.color = Color.BLACK
			block.size = Vector2(1.0, 1.0)
			block.position = Vector2(float(col) - 1.0, float(row))
			parent.add_child(block)


# --- AI: place fist centered on hand line end; right fist faces opposite via scale.x. ---
func _place_handstand_fists(left_hand_world: Vector2, right_hand_world: Vector2) -> void:
	left_fist.visible = true
	right_fist.visible = true
	left_fist.position = left_hand_world + Vector2(FIST_CENTER_X, 0.0)
	right_fist.position = right_hand_world + Vector2(FIST_CENTER_X, 0.0)


# --- AI: flip-aware shoulder placement (Skin flip_h does NOT mirror child nodes). ---
func _apply_side_positions(left_node: Node2D, right_node: Node2D, left_x: float, right_x: float, y: float) -> void:
	if _face_right:
		left_node.position = Vector2(left_x, y)
		right_node.position = Vector2(right_x, y)
	else:
		left_node.position = Vector2(-right_x, y)
		right_node.position = Vector2(-left_x, y)


# --- AI: fixed standing shoulders — body art no longer shifts, so no per-frame tracking. ---
func _update_standing_shoulder_positions() -> void:
	_apply_side_positions(
		left_arm,
		right_arm,
		-STANDING_SHOULDER_OUT,
		STANDING_SHOULDER_OUT,
		STANDING_SHOULDER_Y,
	)


# --- AI: pick arm pose from player state ---
func _update_arms(delta: float) -> void:
	if handstand_mode:
		if not is_on_floor():
			walk_arms.visible = false
			walk_arm_connects.visible = false
			return
		if not HANDSTAND_RUN_TEST and _is_handstand_running():
			walk_arms.visible = false
			walk_arm_connects.visible = false
			return
		walk_arms.visible = true
		walk_arm_connects.visible = true
		left_fist.visible = false
		right_fist.visible = false
		left_arm_connect.visible = false
		right_arm_connect.visible = false
		_update_handstand_arms_blended(delta)
		return

	walk_arms.visible = true
	walk_arm_connects.visible = false
	left_fist.visible = false
	right_fist.visible = false
	left_arm_connect.visible = false
	right_arm_connect.visible = false
	_update_standing_arms(delta)


# --- AI: standing arms — walk swing on floor; rotate in air (fixed length). ---
func _update_standing_arms(delta: float) -> void:
	_update_standing_shoulder_positions()

	var arm_length := STANDING_IDLE_ARM_LENGTH
	if is_on_floor():
		arm_length = lerpf(STANDING_IDLE_ARM_LENGTH, STANDING_WALK_ARM_LENGTH, _standing_leg_blend)

	if is_on_floor() and _standing_leg_blend > 0.0:
		_walk_arm_phase += delta * STANDING_ARM_SPEED

	if is_on_floor():
		var swing_amount := sin(_walk_arm_phase + STANDING_ARM_PHASE_OFFSET) * STANDING_ARM_SWING * _standing_leg_blend
		left_arm.points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(sin(-swing_amount), cos(-swing_amount)) * arm_length,
		])
		right_arm.points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(sin(swing_amount), cos(swing_amount)) * arm_length,
		])
		return

	var angle := _standing_air_arm_tilt
	if _standing_air_vertical_jump:
		left_arm.points = PackedVector2Array([
			Vector2.ZERO,
			_standing_air_arm_tip(angle, arm_length, -1.0),
		])
		right_arm.points = PackedVector2Array([
			Vector2.ZERO,
			_standing_air_arm_tip(angle, arm_length, 1.0),
		])
		return

	var sway := _standing_air_arm_sway
	var dangle := angle
	var left_tip := Vector2(sin(-dangle - sway), cos(-dangle - sway)) * arm_length
	var right_tip := Vector2(sin(-dangle + sway), cos(-dangle + sway)) * arm_length
	left_tip = _standing_air_mirror_tip(left_tip)
	right_tip = _standing_air_mirror_tip(right_tip)
	left_arm.points = PackedVector2Array([Vector2.ZERO, left_tip])
	right_arm.points = PackedVector2Array([Vector2.ZERO, right_tip])


# --- AI: handstand_idle frame data — hand_drop shrinks when shoulder moves down so fists stay on ground. ---
func _get_handstand_frame_data(frame_i: int) -> Dictionary:
	var i := clampi(frame_i, 0, HANDSTAND_IDLE_FRAME_SHOULDER_Y.size() - 1)
	var shoulder_y: float = HANDSTAND_IDLE_FRAME_SHOULDER_Y[i]
	return {
		"shoulder_y": shoulder_y,
		"hand_drop": HANDSTAND_BASE_HAND_DROP - (shoulder_y - HANDSTAND_BASE_SHOULDER_Y),
	}


# --- AI: handstand arms — smooth idle ↔ run via _handstand_run_blend. ---
func _update_handstand_arms_blended(delta: float) -> void:
	var step_speed := lerpf(HANDSTAND_WOBBLE_SPEED, HANDSTAND_RUN_STEP_SPEED, _handstand_run_blend)
	if _handstand_run_blend > 0.001:
		_handstand_arm_phase += delta * step_speed

	var run_left := sin(_handstand_arm_phase)
	var run_right := sin(_handstand_arm_phase + PI)
	var left_step := lerpf(1.0, run_left, _handstand_run_blend)
	var right_step := lerpf(1.0, run_right, _handstand_run_blend)
	var move_dir := 1.0 if _face_right else -1.0

	_apply_handstand_run_body_bob(left_step, right_step, delta)
	_apply_handstand_run_arm_pose(left_step, right_step, move_dir)


# --- AI: eased vertical sprite offset during handstand run crawl. ---
func _apply_handstand_run_body_bob(left_step: float, right_step: float, delta: float) -> void:
	if not HANDSTAND_RUN_BODY_BOB_ENABLED:
		_skin_bob_current = move_toward(_skin_bob_current, 0.0, LIMB_BLEND_SPEED * delta)
	else:
		var push := maxf(left_step, right_step)
		var dip := minf(left_step, right_step)
		var wave := sin(_handstand_arm_phase * 2.0)
		var target_bob := (push * 0.65 - dip * 0.35 + wave * 0.25) * HANDSTAND_RUN_BODY_BOB * _handstand_run_blend
		_skin_bob_current = move_toward(_skin_bob_current, target_bob, LIMB_BLEND_SPEED * delta)
	skin_root.position.y = _skin_base_pos.y - _skin_bob_current


# --- AI: step -1 reach/lift, +1 plant/push — all joints move during crawl. ---
func _apply_handstand_run_arm_pose(left_step: float, right_step: float, move_dir: float) -> void:
	var data := _get_handstand_frame_data(skin.frame)
	_apply_handstand_shoulders(
		data.shoulder_y,
		left_step,
		right_step,
	)

	var left_hand := _handstand_run_hand_point(-HANDSTAND_HAND_IN, data.hand_drop, left_step, move_dir)
	var right_hand := _handstand_run_hand_point(HANDSTAND_HAND_IN, data.hand_drop, right_step, move_dir)
	var left_elbow := _handstand_run_elbow_point(left_step, -1.0)
	var right_elbow := _handstand_run_elbow_point(right_step, 1.0)

	var left_toward := _handstand_toward_body_center(left_arm.position.x)
	var right_toward := _handstand_toward_body_center(right_arm.position.x)
	var left_connect := _handstand_run_connect_point(
		left_step,
		left_arm.position.x,
		left_toward,
	)
	var right_connect := _handstand_run_connect_point(
		right_step,
		right_arm.position.x,
		right_toward,
	)

	left_arm_connect.visible = true
	right_arm_connect.visible = true
	left_arm_connect.position = left_arm.position
	right_arm_connect.position = right_arm.position
	left_arm_connect.points = PackedVector2Array([
		Vector2.ZERO,
		left_connect,
	])
	right_arm_connect.points = PackedVector2Array([
		Vector2.ZERO,
		right_connect,
	])

	# AI: outer limb starts at shoulder edge — same origin as connect, not at connect tip.
	left_arm.points = PackedVector2Array([
		Vector2.ZERO,
		left_elbow,
		left_hand,
	])
	right_arm.points = PackedVector2Array([
		Vector2.ZERO,
		right_elbow,
		right_hand,
	])

	_place_handstand_fists(left_arm.position + left_hand, right_arm.position + right_hand)


func _handstand_toward_body_center(shoulder_x: float) -> float:
	return 1.0 if shoulder_x < 0.0 else -1.0


func _handstand_connect_max_inset(shoulder_x: float, toward_center: float) -> float:
	if toward_center > 0.0:
		return maxf(HANDSTAND_BODY_EDGE_LEFT - shoulder_x, 0.0)
	return maxf(shoulder_x - HANDSTAND_BODY_EDGE_RIGHT, 0.0)


func _apply_handstand_shoulders(base_y: float, left_step: float, right_step: float) -> void:
	var left_y := base_y + _handstand_run_shoulder_lift(left_step)
	var right_y := base_y + _handstand_run_shoulder_lift(right_step)
	var left_x := HANDSTAND_SHOULDER_LEFT + _handstand_run_shoulder_shift(left_step, -1.0)
	var right_x := HANDSTAND_SHOULDER_RIGHT + _handstand_run_shoulder_shift(right_step, 1.0)
	if _face_right:
		left_arm.position = Vector2(left_x, left_y)
		right_arm.position = Vector2(right_x, right_y)
	else:
		left_arm.position = Vector2(-right_x, right_y)
		right_arm.position = Vector2(-left_x, left_y)


func _handstand_run_plant_blend(step: float) -> float:
	return clampf((step + 1.0) * 0.5, 0.0, 1.0)


func _handstand_run_hand_point(base_x: float, base_drop: float, step: float, move_dir: float) -> Vector2:
	var reach := 1.0 - _handstand_run_plant_blend(step)
	var forward := reach * HANDSTAND_RUN_HAND_FORWARD * move_dir
	var lift := reach * HANDSTAND_RUN_HAND_LIFT
	return Vector2(base_x + forward, base_drop - lift)


func _handstand_run_elbow_point(step: float, side: float) -> Vector2:
	var plant := _handstand_run_plant_blend(step)
	var reach := 1.0 - plant
	var elbow_out := lerpf(HANDSTAND_ELBOW_OUT * HANDSTAND_RUN_ELBOW_REACH, HANDSTAND_ELBOW_OUT, plant)
	var elbow_drop := lerpf(HANDSTAND_ELBOW_DROP - 1.4, HANDSTAND_ELBOW_DROP + 0.3, plant)
	elbow_out += reach * 0.8
	return Vector2(side * elbow_out, elbow_drop)


func _handstand_run_connect_point(step: float, shoulder_x: float, toward_center: float) -> Vector2:
	var plant := _handstand_run_plant_blend(step)
	var reach := 1.0 - plant
	var max_inset := _handstand_connect_max_inset(shoulder_x, toward_center)
	var inset := lerpf(max_inset * HANDSTAND_RUN_CONNECT_REACH, max_inset, plant)
	return Vector2(toward_center * inset, -reach * 0.6)


func _handstand_run_shoulder_lift(step: float) -> float:
	var plant := _handstand_run_plant_blend(step)
	var reach := 1.0 - plant
	return plant * 0.45 - reach * 0.35


func _handstand_run_shoulder_shift(step: float, side: float) -> float:
	var reach := 1.0 - _handstand_run_plant_blend(step)
	return side * reach * HANDSTAND_RUN_SHOULDER_SHIFT



# --- AI TEST: handstand on floor uses handstand_idle for both idle and run when enabled. ---
func _is_handstand_running() -> bool:
	return absf(velocity.x) > HANDSTAND_RUN_SPEED_THRESHOLD



func _is_standing_walking_on_floor() -> bool:
	return is_on_floor() and not handstand_mode and (
		Input.get_axis("left", "right") != 0.0
		or absf(velocity.x) > STANDING_FALL_MOVE_THRESHOLD
	)


func _resolve_standing_body_anim() -> StringName:
	if is_on_floor():
		return "standing_walking" if _is_standing_walking_on_floor() else "standing_idle"
	var moving := absf(velocity.x) > STANDING_FALL_MOVE_THRESHOLD
	var rising := velocity.y < -STANDING_AIR_RISE_VELOCITY
	var falling := velocity.y > STANDING_AIR_FALL_VELOCITY
	if moving:
		return "standing_moving_jumping" if rising or not falling else "standing_moving_falling"
	return "standing_idle_jumping" if rising or not falling else "standing_idle_falling"


func _update_handstand_anim_speed() -> void:
	if not handstand_mode:
		skin.speed_scale = 1.0
		return
	if not is_on_floor():
		skin.speed_scale = HANDSTAND_MOVE_ANIM_SPEED
		return
	var moving := _handstand_run_blend > 0.01 or _is_handstand_running()
	skin.speed_scale = HANDSTAND_MOVE_ANIM_SPEED if moving else HANDSTAND_IDLE_ANIM_SPEED


func _play_body_anim(anim_name: StringName) -> void:
	if skin.animation != anim_name:
		skin.play(anim_name)


# --- YOU: sprite animation state machine ---
func _handle_animations() -> void:
	if is_on_floor():
		if _is_handstand_running():
			if handstand_mode:
				if HANDSTAND_RUN_TEST:
					_play_body_anim("handstand_idle")
				else:
					skin.stop()
			elif not handstand_mode:
				_play_body_anim(_resolve_standing_body_anim())
		else:
			if handstand_mode:
				_play_body_anim("handstand_idle")
			elif not handstand_mode:
				_play_body_anim(_resolve_standing_body_anim())
	elif handstand_mode:
		_play_body_anim("handstand_idle")
	else:
		_play_body_anim(_resolve_standing_body_anim())

	_update_handstand_anim_speed()

	# --- AI: facing — handstand run tracks velocity; otherwise keep last move direction while idle. ---
	if handstand_mode and _is_handstand_running():
		if velocity.x != 0.0:
			_face_right = velocity.x > 0.0
	elif absf(velocity.x) > 1.0:
		_face_right = velocity.x > 0.0

	# --- AI: handstand body art faces the opposite way — invert flip_h only in handstand. ---
	if handstand_mode:
		skin.flip_h = _face_right
	else:
		skin.flip_h = not _face_right


# --- AI: handstand only toggles on landing, not mid-air ---
func _update_handstand_mode() -> void:
	if not is_on_floor():
		return

	var wants_handstand := Input.is_action_pressed("switch")
	if wants_handstand == handstand_mode:
		return

	handstand_mode = wants_handstand
	if not handstand_mode:
		handstand_bonus = 0
		handstand_jump_velocity = ORIGINAL_HANDSTAND_JUMP_VELOCITY
		_stop_handstand_rumble()


# --- AI: rumble all connected gamepads while handstanding ---
func _update_handstand_rumble() -> void:
	if not handstand_mode:
		return

	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, HANDSTAND_RUMBLE_WEAK, HANDSTAND_RUMBLE_STRONG, 0.0)


# --- AI: stop rumble when leaving handstand ---
func _stop_handstand_rumble() -> void:
	for device in Input.get_connected_joypads():
		Input.stop_joy_vibration(device)


func _exit_tree() -> void:
	_stop_handstand_rumble()
