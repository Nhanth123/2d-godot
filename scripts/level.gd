extends Node2D

@onready var start = $Start
@onready var exit = $Exit
@onready var death_zone = $Deathzone
@onready var hub = $UI/HUD
@onready var ui = $UI

@export var next_level: PackedScene = null
@export var level_time = 60
@export var is_final_level: bool = false
 
var player = null
var time_node = null
var time_left
var win = false

func _process(delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.global_position = start.get_spawn_position()
	
	var traps = get_tree().get_nodes_in_group("traps")
	for trap in traps:
		trap.connect("touched_player", _on_trap_touched_player)
	
	exit.body_entered.connect(_on_exit_body_entered)
	death_zone.body_entered.connect(_on_deathzone_body_entered)
	
	time_left = level_time
	hub.set_time_label(time_left)
	
	time_node = Timer.new()
	time_node.name = "Level Timer"
	time_node.wait_time = 1
	time_node.timeout.connect(_on_level_timer_timeout)
	add_child(time_node)
	time_node.start()

func _on_deathzone_body_entered(body):
	AudioPlayer.play_sfx("hurt")
	reset_player()

func _on_trap_touched_player():
	AudioPlayer.play_sfx("hurt")
	reset_player()

func reset_player():
	player.velocity = Vector2.ZERO
	player.global_position = start.get_spawn_position()

func _on_exit_body_entered(body):
	if body is Player:
		if is_final_level || (next_level != null):
			exit.animate()
			player.active = false
			win = true
			await get_tree().create_timer(1.5).timeout
			if is_final_level:
				ui.show_win_screen(true)
			else:
				get_tree().change_scene_to_packed(next_level)
		
func _on_level_timer_timeout():
	if win == false:
		time_left -= 1
		hub.set_time_label(time_left)
		
		if time_left < 0 :
			reset_player()
			time_left = level_time
			hub.set_time_label(time_left)
