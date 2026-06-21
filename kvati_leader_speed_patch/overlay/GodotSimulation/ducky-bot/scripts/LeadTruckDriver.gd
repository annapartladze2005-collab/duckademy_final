extends Node3D

# Lead truck motion for the convoying simulation.
# This keeps the leader on a longer lane route, waits until the Python camera
# stream is connected, and exposes reset/speed hooks used by the dashboard.

@export var speed: float = 0.055
@export var min_speed: float = 0.0
@export var max_speed: float = 0.25
@export var reach_distance: float = 0.045
@export var rotation_offset_degrees: float = 180.0
@export var start_grace_s: float = 1.0
@export var wait_for_camera: bool = true
@export var stop_at_end: bool = true
@export var corner_slowdown: float = 0.65
@export var corner_angle_threshold_degrees: float = 18.0

var _points: Array[Vector3] = []
var _current_index: int = 0
var _finished: bool = false
var _base_speed: float = 0.055
var _connected_for: float = -1.0

@onready var _camera_streamer: Node = get_tree().current_scene.get_node_or_null("DuckieBot/CameraStreamer")


func _ready() -> void:
	_build_path()
	_base_speed = clamp(speed, min_speed, max_speed)
	add_to_group("npc_leader")
	reset_leader()
	print("[LeadTruckDriver] Lead truck ready; path points=", _points.size(), " speed=", _base_speed)


func _build_path() -> void:
	# Coordinates are tuned for KvatiTown/GodotSimulation/ducky-bot/scenes/convoying.tscn.
	# They follow the visible road tiles for much longer than the old single-turn path:
	# start ahead of the follower, cross the first intersection, go down the right lane,
	# then continue across the lower lane. Keep small point spacing around turns so the
	# truck rotates smoothly instead of snapping left/right.
	_points = [
		# start: straight road in front of DuckieBot
		Vector3(4.17, 0.08, 2.30),
		Vector3(4.17, 0.08, 2.48),
		Vector3(4.17, 0.08, 2.66),
		Vector3(4.20, 0.08, 2.82),

		# first gentle left turn through the crossroad
		Vector3(4.28, 0.08, 2.96),
		Vector3(4.42, 0.08, 3.06),
		Vector3(4.62, 0.08, 3.12),
		Vector3(4.90, 0.08, 3.15),

		# long straight after the first turn
		Vector3(5.20, 0.08, 3.15),
		Vector3(5.55, 0.08, 3.15),
		Vector3(5.90, 0.08, 3.15),
		Vector3(6.25, 0.08, 3.15),
		Vector3(6.58, 0.08, 3.13),

		# smooth right/down turn onto the next lane
		Vector3(6.86, 0.08, 3.06),
		Vector3(7.08, 0.08, 2.88),
		Vector3(7.20, 0.08, 2.62),
		Vector3(7.24, 0.08, 2.30),

		# long vertical lane
		Vector3(7.24, 0.08, 1.95),
		Vector3(7.24, 0.08, 1.60),
		Vector3(7.18, 0.08, 1.28),

		# lower turn onto another straight lane
		Vector3(7.02, 0.08, 1.02),
		Vector3(6.76, 0.08, 0.82),
		Vector3(6.45, 0.08, 0.72),

		# lower straight lane back across the map
		Vector3(6.10, 0.08, 0.70),
		Vector3(5.75, 0.08, 0.70),
		Vector3(5.40, 0.08, 0.70),
		Vector3(5.05, 0.08, 0.70),
		Vector3(4.70, 0.08, 0.72),
	]


func reset_leader() -> void:
	if _points.is_empty():
		_build_path()

	global_position = _points[0]
	_current_index = 1
	_finished = false
	_connected_for = -1.0
	_face_next_point()
	print("[LeadTruckDriver] Reset to start")


func set_speed(new_speed: float) -> void:
	_base_speed = clamp(new_speed, min_speed, max_speed)
	speed = _base_speed
	print("[LeadTruckDriver] Speed set to ", _base_speed)


func _camera_up() -> bool:
	if not wait_for_camera:
		return true
	if _camera_streamer == null:
		return true
	var tcp: StreamPeerTCP = _camera_streamer._tcp
	return tcp != null and tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED


func _physics_process(delta: float) -> void:
	if _finished:
		return

	if not _camera_up():
		_connected_for = -1.0
		return

	if _connected_for < 0.0:
		_connected_for = 0.0
		print("[LeadTruckDriver] Camera stream up; leader departs in ", start_grace_s, "s")

	_connected_for += delta
	if _connected_for < start_grace_s:
		return

	if _current_index >= _points.size():
		_finish_or_loop()
		return

	var target := _points[_current_index]
	var to_target := target - global_position
	var distance := to_target.length()

	while distance <= reach_distance:
		_current_index += 1
		if _current_index >= _points.size():
			_finish_or_loop()
			return
		target = _points[_current_index]
		to_target = target - global_position
		distance = to_target.length()

	var direction := to_target.normalized()
	var current_speed := _base_speed
	if _turn_coming(direction):
		current_speed *= corner_slowdown

	var step := min(distance, current_speed * delta)
	global_position += direction * step
	_face_direction(direction)


func _finish_or_loop() -> void:
	if stop_at_end:
		_finished = true
		print("[LeadTruckDriver] Lead truck reached end and stopped")
		return
	reset_leader()


func _turn_coming(current_direction: Vector3) -> bool:
	if _current_index + 1 >= _points.size():
		return false
	var next_direction := (_points[_current_index + 1] - _points[_current_index]).normalized()
	if next_direction.length() <= 0.0:
		return false
	var angle := abs(current_direction.angle_to(next_direction))
	return angle > deg_to_rad(corner_angle_threshold_degrees)


func _face_next_point() -> void:
	if _current_index >= _points.size():
		return
	var direction := (_points[_current_index] - global_position).normalized()
	if direction.length() > 0.0:
		_face_direction(direction)


func _face_direction(direction: Vector3) -> void:
	look_at(global_position + direction, Vector3.UP)
	rotate_y(deg_to_rad(rotation_offset_degrees))
