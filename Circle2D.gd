class_name Circle2D extends Node2D

var radius : float = 0.0
var color : Color = Color(0,0,0,1)

func _draw():
	draw_circle(position, radius, color)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass