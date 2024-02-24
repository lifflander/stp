extends TileMap
class_name IsoTileMap

const unit_tile_set : int = 2
var width : int = 10
var height : int = 10
var special_cell : Vector2i = Vector2i(-1,-1)

var unit_layer : Array[Vector2i]
var unit_tile_set_layer : Array[int]

func convertTo1D(idx : Vector2i) -> int:
	return idx.x * width + idx.y

# Called when the node enters the scene tree for the first time.
func _ready():
	# Populate layers
	# At the beginning no units exist to set all to -1
	unit_layer.resize(width*height)
	unit_tile_set_layer.resize(width*height)
	for x in range(width):
		for y in range(height):
			#print("x=", x, ", y=", y, ", 1d=", convertTo1D(Vector2i(x,y)))
			unit_layer[convertTo1D(Vector2i(x,y))] = Vector2i(-1, -1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var layer : int = 0

	# Draw the base map layer
	for x in range(width):
		for y in range(height):
			pass
			#if special_cell.x == x and special_cell.y == y:
			#	set_cell(layer, Vector2i(x,y), 0, Vector2i(3,4), 0)
			#else:
			#	set_cell(layer, Vector2i(x,y), 0, Vector2i(x%4,y%4), 0)

	# Draw the unit layer
	layer = 1
	for x in range(width):
		for y in range(height):
			var lin_idx : int = convertTo1D(Vector2i(x,y))
			var unit_to_draw : Vector2i = unit_layer[lin_idx]
			if unit_to_draw.x != -1 and unit_to_draw.y != -1:
				set_cell(layer, Vector2i(x,y), unit_tile_set_layer[lin_idx], unit_to_draw, 0)


