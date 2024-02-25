extends TileMap
class_name IsoTileMap

@onready var logic_engine : LogicEngine = get_parent().get_node("LogicEngine")
@onready var label_holder : Node2D = get_node("LabelHolder")

const unit_tile_set : int = 8
var width : int = 10
var height : int = 10
var selected_cell : Vector2i = Vector2i(-1,-1)
var selected_times : int = 0
var unit_is_selected : bool = false

var unit_layer : Array[Vector2i]
var unit_tile_set_layer : Array[int]
var unit_layer_health : Array[int]

const selection_layer = 3
const unit_layer_id = 1

func convertTo1D(idx : Vector2i) -> int:
	return idx.x * width + idx.y

# Called when the node enters the scene tree for the first time.
func _ready():
	# Populate layers
	# At the beginning no units exist to set all to -1
	unit_layer.resize(width*height)
	unit_tile_set_layer.resize(width*height)
	unit_layer_health.resize(width*height)
	for x in range(width):
		for y in range(height):
			#print("x=", x, ", y=", y, ", 1d=", convertTo1D(Vector2i(x,y)))
			unit_layer[convertTo1D(Vector2i(x,y))] = Vector2i(-1, -1)
			unit_layer_health[convertTo1D(Vector2i(x,y))] = -1

func hasUnitOnSquare(cell) -> bool:
	if cell.x == -1 or cell.y == -1:
		return false
	else:
		return unit_layer[convertTo1D(cell)].x != -1 and unit_layer[convertTo1D(cell)].y != -1 and unit_tile_set_layer[convertTo1D(cell)] != -1

func unselect_current():
	if selected_cell.x != -1 and selected_cell.y != -1:
		set_cell(selection_layer, selected_cell, -1, Vector2i(0,0), 0)
	unit_is_selected = false
	
func unselect_around():
	var right : Vector2i = Vector2i(selected_cell.x + 1, selected_cell.y)
	var left : Vector2i = Vector2i(selected_cell.x, selected_cell.y + 1)
	var top : Vector2i = Vector2i(selected_cell.x - 1, selected_cell.y)
	var bottom : Vector2i = Vector2i(selected_cell.x, selected_cell.y - 1)
		
	var rightx : Vector2i = Vector2i(selected_cell.x + 1, selected_cell.y - 1)
	var leftx: Vector2i = Vector2i(selected_cell.x - 1, selected_cell.y + 1)
	var topx : Vector2i = Vector2i(selected_cell.x - 1, selected_cell.y - 1)
	var bottomx : Vector2i = Vector2i(selected_cell.x + 1, selected_cell.y + 1)
		
	set_cell(selection_layer, right, -1, Vector2i(0,0), 0)
	set_cell(selection_layer, left, -1, Vector2i(0,0), 0)
	set_cell(selection_layer, top, -1, Vector2i(0,0), 0)
	set_cell(selection_layer, bottom, -1, Vector2i(0,0), 0)
	set_cell(selection_layer, rightx, -1, Vector2i(0,0), 0)
	set_cell(selection_layer, leftx, -1, Vector2i(0,0), 0)
	set_cell(selection_layer, topx, -1, Vector2i(0,0), 0)
	set_cell(selection_layer, bottomx, -1, Vector2i(0,0), 0)

func select_cell(cell : Vector2i):
	var set_selected = true
	if cell == selected_cell:
		selected_times += 1
	else:
		if hasUnitOnSquare(selected_cell) and selected_times % 2 == 0:
			print("calling move unit")
			unselect_around()
			logic_engine.move_unit(selected_cell, cell)
			selected_cell = Vector2i(-1,-1)
			set_selected = false
		
		unselect_current()
		selected_times = 0

	if set_selected:
		selected_cell = cell

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var layer : int = 0

	# Draw the base map layer
	for x in range(width):
		for y in range(height):
			#if special_cell.x == x and special_cell.y == y:
			#	set_cell(layer, Vector2i(x,y), 0, Vector2i(3,4), 0)
			#else:
			#set_cell(layer, Vector2i(x,y), 6, Vector2i(x%4,0), 0)
			pass

	# Draw the unit layer
	layer = unit_layer_id
	for x in range(width):
		for y in range(height):
			var lin_idx : int = convertTo1D(Vector2i(x,y))
			var unit_to_draw : Vector2i = unit_layer[lin_idx]
			if unit_to_draw.x != -1 and unit_to_draw.y != -1:
				set_cell(layer, Vector2i(x,y), unit_tile_set_layer[lin_idx], unit_to_draw, 0)
				set_cell(selection_layer, selected_cell, -1, Vector2i(0,0), 0)

	if selected_cell.x != -1 and selected_cell.y != -1:
		if hasUnitOnSquare(selected_cell) and selected_times % 2 == 0:
			var lin_idx : int = convertTo1D(selected_cell)
			var unit_to_draw : Vector2i = unit_layer[lin_idx]
			set_cell(unit_layer_id, selected_cell, unit_tile_set_layer[lin_idx]+2, unit_to_draw, 0)
			unit_is_selected = true
		else:
			set_cell(selection_layer, selected_cell, 9, Vector2i(0,0), 0)
			
	if unit_is_selected:
		var right : Vector2i = Vector2i(selected_cell.x + 1, selected_cell.y)
		var left : Vector2i = Vector2i(selected_cell.x, selected_cell.y + 1)
		var top : Vector2i = Vector2i(selected_cell.x - 1, selected_cell.y)
		var bottom : Vector2i = Vector2i(selected_cell.x, selected_cell.y - 1)
		
		var rightx : Vector2i = Vector2i(selected_cell.x + 1, selected_cell.y - 1)
		var leftx: Vector2i = Vector2i(selected_cell.x - 1, selected_cell.y + 1)
		var topx : Vector2i = Vector2i(selected_cell.x - 1, selected_cell.y - 1)
		var bottomx : Vector2i = Vector2i(selected_cell.x + 1, selected_cell.y + 1)
		
		set_cell(selection_layer, right, 11, Vector2i(0,0), 0)
		set_cell(selection_layer, left, 11, Vector2i(0,0), 0)
		set_cell(selection_layer, top, 11, Vector2i(0,0), 0)
		set_cell(selection_layer, bottom, 11, Vector2i(0,0), 0)
		set_cell(selection_layer, rightx, 11, Vector2i(0,0), 0)
		set_cell(selection_layer, leftx, 11, Vector2i(0,0), 0)
		set_cell(selection_layer, topx, 11, Vector2i(0,0), 0)
		set_cell(selection_layer, bottomx, 11, Vector2i(0,0), 0)

	for child in label_holder.get_children():
		label_holder.remove_child(child)

	# draw health decorators
	for x in range(width):
		for y in range(height):
			var lin_idx : int = convertTo1D(Vector2i(x,y))
			if unit_layer_health[lin_idx] != -1:
				var new_label : Label = Label.new()
				var label_pos = map_to_local(Vector2i(x, y))
				label_pos.x -= 150
				label_pos.y -= tile_set.tile_size.y - 50
				var global_pos = to_global(label_pos)
				new_label.position = global_pos
				new_label.label_settings = load("res://unit-hp-label-settings.tres")
				new_label.text = str(unit_layer_health[lin_idx])
				label_holder.add_child(new_label)



