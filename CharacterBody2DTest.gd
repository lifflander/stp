extends CharacterBody2D

var dragging = false
var prev_position : Vector2

func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			print("pressed")
			dragging = true
			prev_position = get_local_mouse_position() + position
		else:
			dragging = false
			prev_position = Vector2(0,0)

			var global_pos = get_global_mouse_position()

	elif event is InputEventMouseMotion and dragging:
		var new_position = get_local_mouse_position()
		position = prev_position - new_position

func _physics_process(delta):
	pass
