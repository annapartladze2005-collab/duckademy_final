extends PathFollow3D

# Path-based lead truck mover for KvatiTown convoying.
# This matches the working idea from duckietown-convoy: the leader is a child
# of PathFollow3D, so Godot moves it along a real path instead of manually
# rewriting the imported vehicle root transform.

@export var speed: float = 0.14
@export var min_speed: float = 0.0
@export var max_speed: float = 0.25
@export var start_progress: float = 0.0
@export var loop_to_start: bool = true
@export var model_yaw_degrees: float = 180.0
@export var debug_print: bool = true

var _debug_timer: float = 0.0
var _finished: bool = false
var _curve_length: float = 0.0

@onready var _visual: Node3D = get_node_or_null("LeaderVehicle") as Node3D


func _ready() -> void:
	rotation_mode = PathFollow3D.ROTATION_Y
	loop = false
	add_to_group("npc_leader")
	_refresh_curve_length()
	if _visual != null:
		_visual.rotation.y = deg_to_rad(model_yaw_degrees)
	reset_leader()
	set_process(true)
	print("[KvatiLeaderPath] ready curve_length=", _curve_length, " speed=", speed)


func _refresh_curve_length() -> void:
	var path := get_parent() as Path3D
	if path != null and path.curve != null:
		_curve_length = path.curve.get_baked_length()
	else:
		_curve_length = 0.0


func reset_leader() -> void:
	_refresh_curve_length()
	progress = start_progress
	_finished = false
	_debug_timer = 999.0
	print("[KvatiLeaderPath] reset progress=", progress, " speed=", speed)


func set_speed(new_speed: float) -> void:
	speed = clamp(float(new_speed), min_speed, max_speed)
	_finished = false
	print("[KvatiLeaderPath] speed set to ", speed)


func _process(delta: float) -> void:
	if _finished:
		return
	if _curve_length <= 0.001:
		_refresh_curve_length()
		if _curve_length <= 0.001:
			return
	if speed <= 0.0:
		return

	progress += speed * delta

	if progress >= _curve_length:
		if loop_to_start:
			progress = fposmod(progress, _curve_length)
			print("[KvatiLeaderPath] looped to start")
		else:
			progress = _curve_length
			_finished = true
			print("[KvatiLeaderPath] reached end and stopped")

	_debug_timer += delta
	if debug_print and _debug_timer >= 1.0:
		_debug_timer = 0.0
		print("[KvatiLeaderPath] moving progress=", progress, "/", _curve_length, " speed=", speed, " pos=", global_position)
