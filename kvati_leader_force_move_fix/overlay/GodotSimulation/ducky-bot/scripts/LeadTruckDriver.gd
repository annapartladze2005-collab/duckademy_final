extends Node3D

# FORCE-MOVE lead truck driver for KvatiTown convoying.
# This intentionally does NOT wait for CameraStreamer/Python. If this script is
# attached to LeadTruck, the truck moves by itself immediately after scene load.
# Dashboard reset still calls reset_leader(), and the leader speed slider still
# calls set_speed().

@export var speed: float = 0.14
@export var min_speed: float = 0.0
@export var max_speed: float = 0.25
@export var reach_distance: float = 0.035
@export var rotation_offset_degrees: float = 180.0

# Kept only so old scene properties do not break loading. Not used as a gate.
@export var start_grace_s: float = 0.0
@export var wait_for_camera: bool = false
@export var stop_at_end: bool = false

@export var corner_slowdown: float = 0.75
@export var corner_angle_threshold_degrees: float = 20.0
@export var debug_print: bool = true

var _points: Array[Vector3] = []
var _current_index: int = 1
var _finished: bool = false
var _base_speed: float = 0.14
var _grace_left: float = 0.0
var _debug_timer: float = 0.0


func _ready() -> void:
	_build_path()
	_base_speed = clamp(speed, min_speed, max_speed)
	add_to_group("npc_leader")
	set_process(true)
	set_physics_process(false)
	reset_leader()
	print("[LeadTruckDriver FORCE] ready path_points=", _points.size(), " speed=", _base_speed, " wait_for_camera=IGNORED")


func _build_path() -> void:
	# Tuned for GodotSimulation/ducky-bot/scenes/convoying.tscn.
	# First section is the known-working old path. Extra points extend motion.
	_points = [
		# start ahead of follower
		Vector3(4.17, 0.08, 2.30),
		Vector3(4.17, 0.08, 2.45),
		Vector3(4.17, 0.08, 2.60),
		Vector3(4.17, 0.08, 2.72),

		# smooth left turn
		Vector3(4.22, 0.08, 2.84),
		Vector3(4.30, 0.08, 2.94),
		Vector3(4.42, 0.08, 3.02),
		Vector3(4.58, 0.08, 3.08),
		Vector3(4.76, 0.08, 3.12),
		Vector3(4.96, 0.08, 3.14),
		Vector3(5.15, 0.08, 3.15),

		# long straight after turn
		Vector3(5.35, 0.08, 3.15),
		Vector3(5.60, 0.08, 3.15),
		Vector3(5.85, 0.08, 3.15),
		Vector3(6.10, 0.08, 3.15),
		Vector3(6.35, 0.08, 3.15),
		Vector3(6.60, 0.08, 3.14),

		# gentle turn down/right lane
		Vector3(6.82, 0.08, 3.08),
		Vector3(7.02, 0.08, 2.94),
		Vector3(7.15, 0.08, 2.72),
		Vector3(7.22, 0.08, 2.45),
		Vector3(7.24, 0.08, 2.15),
		Vector3(7.24, 0.08, 1.85),
		Vector3(7.24, 0.08, 1.55),
		Vector3(7.18, 0.08, 1.25),

		# lower lane curve and straight
		Vector3(7.02, 0.08, 1.02),
		Vector3(6.78, 0.08, 0.84),
		Vector3(6.48, 0.08, 0.74),
		Vector3(6.15, 0.08, 0.70),
		Vector3(5.80, 0.08, 0.70),
		Vector3(5.45, 0.08, 0.70),
		Vector3(5.10, 0.08, 0.70),
		Vector3(4.75, 0.08, 0.72),
	]


func reset_leader() -> void:
	if _points.is_empty():
		_build_path()
	global_position = _points[0]
	_current_index = 1
	_finished = false
	_grace_left = max(0.0, start_grace_s)
	_debug_timer = 999.0
	_face_next_point()
	print("[LeadTruckDriver FORCE] reset pos=", global_position, " next=", _current_index, " speed=", _base_speed)


func set_speed(new_speed: float) -> void:
	_base_speed = clamp(new_speed, min_speed, max_speed)
	speed = _base_speed
	print("[LeadTruckDriver FORCE] speed set to ", _base_speed)


func _process(delta: float) -> void:
	if _finished:
		return

	if _grace_left > 0.0:
		_grace_left -= delta
		return

	if _points.size() < 2:
		return

	var move_left := _base_speed * delta
	while move_left > 0.0 and not _finished:
		if _current_index >= _points.size():
			_finish_or_loop()
			return

		var target := _points[_current_index]
		var to_target := target - global_position
		var distance := to_target.length()

		if distance <= reach_distance:
			_current_index += 1
			continue

		var direction := to_target.normalized()
		var effective_move := move_left
		if _turn_coming(direction):
			effective_move *= corner_slowdown

		var step := min(distance, effective_move)
		global_position += direction * step
		_face_direction(direction)
		move_left -= step

	_debug_timer += delta
	if debug_print and _debug_timer >= 1.0:
		_debug_timer = 0.0
		print("[LeadTruckDriver FORCE] moving pos=", global_position, " target_index=", _current_index, " speed=", _base_speed)


func _finish_or_loop() -> void:
	if stop_at_end:
		_finished = true
		print("[LeadTruckDriver FORCE] reached end and stopped")
		return
	print("[LeadTruckDriver FORCE] reached end; looping to start")
	reset_leader()


func _turn_coming(current_direction: Vector3) -> bool:
	if _current_index + 1 >= _points.size():
		return false
	var next_direction := (_points[_current_index + 1] - _points[_current_index]).normalized()
	if next_direction.length() <= 0.0:
		return false
	return abs(current_direction.angle_to(next_direction)) > deg_to_rad(corner_angle_threshold_degrees)


func _face_next_point() -> void:
	if _current_index >= _points.size():
		return
	var direction := (_points[_current_index] - global_position).normalized()
	if direction.length() > 0.0:
		_face_direction(direction)


func _face_direction(direction: Vector3) -> void:
	look_at(global_position + direction, Vector3.UP)
	rotate_y(deg_to_rad(rotation_offset_degrees))
