extends CharacterBody2D

var dragging = false
var prev_position : Vector2

@onready var tile_map : IsoTileMap = get_parent().get_node("Tiles")

func _ready():
	set_process_input(true)
	
	get_tree().get_root().size_changed.connect(resize)

func resize():
	var size = get_tree().get_root().get_viewport().size
	var cr = get_parent().find_child("ColorRect") as ColorRect
	var dcr = get_parent().find_child("DynamicColorRect") as ColorRect
	var cc = get_parent().find_child("CenterContainer") as CenterContainer
	cr.set_size(Vector2i(size.x, 100))
	dcr.set_size(Vector2i(size.x, 100))
	cc.set_size(Vector2i(size.x, 50))

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
			prev_position = get_local_mouse_position() + position
		else:
			dragging = false
			prev_position = Vector2(0,0)

			var global_pos = get_global_mouse_position()
			var local_pos = tile_map.to_local(global_pos)
			var map_pos = tile_map.local_to_map(local_pos)
			print("global:, ", global_pos, ", local: ", local_pos, ", map: ", map_pos)
			tile_map.selectCell(map_pos)

	elif event is InputEventMouseMotion and dragging:
		var new_position = get_local_mouse_position()
		position = prev_position - new_position

func _physics_process(delta):
	pass
