extends TileMap
class_name IsoTileMap

var special_cell : Vector2i = Vector2i(-1,-1)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for x in range(10):
		for y in range(10):
			if special_cell.x == x and special_cell.y == y:
				set_cell(0, Vector2i(x,y), 0, Vector2i(3,4), 0)
			else:
				set_cell(0, Vector2i(x,y), 0, Vector2i(x%4,y%4), 0)

	
	#set_cell(0,Vector2i())

