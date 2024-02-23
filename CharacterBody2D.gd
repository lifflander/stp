extends CharacterBody2D

var dragging = false
var prev_position : Vector2

@onready var tile_map : IsoTileMap = get_parent().get_node("Tiles")

func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
			prev_position = get_local_mouse_position() + position
		else:
			dragging = false
			prev_position = Vector2(0,0)
			
			var local_pos = get_global_mouse_position()
			print(local_pos)
			var map_pos = tile_map.local_to_map(local_pos)
			print(map_pos)
			tile_map.special_cell = Vector2i(map_pos.x,map_pos.y)
			
	elif event is InputEventMouseMotion and dragging:
		var new_position = get_local_mouse_position()
		position = prev_position - new_position

func _physics_process(delta):
	pass
