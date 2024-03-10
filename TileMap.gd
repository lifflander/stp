extends TileMap
class_name IsoTileMap

@onready var logic_engine : LogicEngine = get_parent().get_node("LogicEngine")
@onready var label_holder : Node2D = get_node("LabelHolder")
@onready var sprite_holder : Node2D = get_node("SpriteHolder")

const unit_tile_set : int = 8
var width : int = 200
var height : int = 200
var selected_cell : Vector2i = Vector2i(-1,-1)
var selected_times : int = 0
var unit_is_selected : bool = false

var base_layer : Array[Vector2i]
var unit_layer : Array[Vector2i]
var unit_tile_set_layer : Array[int]
var unit_layer_health : Array[int]
var unit_layer_build : Array[int]

var selection_layer : int = -1
var unit_layer_id : int = -1
var city_layer_id : int = -1
var terrain_layer_id : int = -1

class BuilderIcon extends Sprite2D:
	var location : Vector2i
	var le : LogicEngine
	
	func _input(event):
		var global_pos = get_global_mouse_position()
		var local_pos = to_local(global_pos)
		# if event is InputEventMouseMotion and get_rect().has_point(local_pos):
		# 	new_sprite.texture = load("res://assets/tilesets/Builder_Selection_1.png")
		if event is InputEventMouseButton and event.is_pressed() and get_rect().has_point(local_pos):
			print("clicked builder")
			le.build_city(location)

func convertTo1D(idx : Vector2i) -> int:
	return idx.x * width + idx.y


class Circle:
	var pos : Vector2
	var radius : float
	var x1 : float
	var x2 : float
	var y1 : float
	var y2 : float
	var planet = 0

	func getSquareLen(rad : float) -> float:
		return sqrt(2) * rad
	
	func _init(p : Vector2, in_radius : float, in_planet : int):
		pos = p
		radius = in_radius
		planet = in_planet

		var len = getSquareLen(radius)

		x1 = p.x-len/2
		x2 = p.x+len/2
		y1 = p.y-len/2
		y2 = p.y+len/2

	func inCircle(p : Vector2i) -> bool:
		return (p.x - pos.x) * (p.x - pos.x) + (p.y - pos.y) * (p.y - pos.y) < radius * radius

	func inSquare(p : Vector2i) -> bool:
		return p.x >= x1 and p.x <= x2 and p.y >= y1 and p.y <= y2

# 10, 2, 10
# 15, 27, 10

#5, 25, 10
#0, 0, 10

var circles = [Circle.new(Vector2(6,5), 6, 0), Circle.new(Vector2(5,17), 6, 1)]
var altitude = FastNoiseLite.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	altitude.seed = randi()

	for i in get_layers_count():
		if get_layer_name(i) == "Base layer":
			terrain_layer_id = i
		if get_layer_name(i) == "Resources":
			pass
		if get_layer_name(i) == "City":
			city_layer_id = i
		if get_layer_name(i) == "Unit layer":
			unit_layer_id = i
		if get_layer_name(i) == "Selection":
			selection_layer = i

	# Populate layers
	# At the beginning no units exist to set all to -1
	unit_layer.resize(width*height)
	base_layer.resize(width*height)
	unit_tile_set_layer.resize(width*height)
	unit_layer_health.resize(width*height)
	unit_layer_build.resize(width*height)
	for x in range(width):
		for y in range(height):
			#print("x=", x, ", y=", y, ", 1d=", convertTo1D(Vector2i(x,y)))
			unit_layer[convertTo1D(Vector2i(x,y))] = Vector2i(-1, -1)
			base_layer[convertTo1D(Vector2i(x,y))] = Vector2i(-1, -1)
			unit_layer_health[convertTo1D(Vector2i(x,y))] = -1
			unit_layer_build[convertTo1D(Vector2i(x,y))] = -1

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
		
		if hasUnitOnSquare(selected_cell) and selected_times % 2 != 0:
			unit_is_selected = false
			unselect_around()
	else:
		if hasUnitOnSquare(selected_cell) and selected_times % 2 == 0:
			print("calling move unit")
			unselect_around()
			logic_engine.move_unit(selected_cell, cell)
			selected_cell = Vector2i(-1,-1)
			set_selected = false
		else:
			unselect_around()
		
		unselect_current()
		selected_times = 0

	if set_selected:
		selected_cell = cell
		if hasUnitOnSquare(selected_cell):
			var lin_idx : int = convertTo1D(selected_cell)
			var unit_to_draw : Vector2i = unit_layer[lin_idx]
			var source = tile_set.get_source(10) as TileSetAtlasSource
			var origin = source.get_tile_data(unit_to_draw, 0).texture_origin
			var tile_data = source.get_tile_data(unit_to_draw, 0)

			var tween = get_tree().create_tween()
			tween.tween_property(tile_data, "texture_origin:y", origin.y+50, 0.1).set_trans(Tween.TRANS_LINEAR)
			tween.chain().tween_property(tile_data, "texture_origin:y", origin.y, 0.1).set_trans(Tween.TRANS_LINEAR)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var layer : int = 0

	for child in label_holder.get_children():
		label_holder.remove_child(child)
	for child in sprite_holder.get_children():
		sprite_holder.remove_child(child)

	var cx = 0
	var cy = 0

	# Draw the base map layer
	for x in range(width):
		for y in range(height):
				for c in circles:
					if c.inCircle(Vector2i(x,y)):
						#print("planet=" + str(c.planet) + ", x=", str(x), ", y=", str(y))
						var alt = altitude.get_noise_2d(float(x)*50.0, float(y)*50.0)*10
						var mountain = alt > 1
						if c.planet == 0:
							if mountain:
								set_cell(terrain_layer_id, Vector2i(x,y), 7, Vector2i(5,0))
							else:
								set_cell(terrain_layer_id, Vector2i(x,y), 6, Vector2i(1,0))
							cx += 1
						elif c.planet == 1:
							if mountain:
								set_cell(terrain_layer_id, Vector2i(x,y), 7, Vector2i(6,0))
							else:
								set_cell(terrain_layer_id, Vector2i(x,y), 6, Vector2i(2,0))
							cy += 1
						else:
							print("ERROR")
			#if special_cell.x == x and special_cell.y == y:
			#	set_cell(layer, Vector2i(x,y), 0, Vector2i(3,4), 0)
			#else:
			#set_cell(layer, Vector2i(x,y), 6, Vector2i(x%4,0), 0)
			#pass
	#print("cx=", cx, ", cy=", cy)

	# Draw the unit layer
	layer = unit_layer_id
	for x in range(width):
		for y in range(height):
			var lin_idx : int = convertTo1D(Vector2i(x,y))
			var unit_to_draw : Vector2i = unit_layer[lin_idx]
			if unit_to_draw.x != -1 and unit_to_draw.y != -1:
				set_cell(layer, Vector2i(x,y), unit_tile_set_layer[lin_idx], unit_to_draw, 0)
				set_cell(selection_layer, selected_cell, -1, Vector2i(0,0), 0)

	# Draw the city layer
	layer = city_layer_id
	for x in range(width):
		for y in range(height):
			var lin_idx : int = convertTo1D(Vector2i(x,y))
			var base_to_draw : Vector2i = base_layer[lin_idx]
			if base_to_draw.x != -1 and base_to_draw.y != -1:
				set_cell(layer, Vector2i(x,y), 12, base_to_draw, 0)
				var the_base = logic_engine.get_base(Vector2i(x,y))
				the_base.name

				var new_label : Label = Label.new()
				new_label.position.x = 40
				new_label.label_settings = load("res://base-name-label-settings.tres")
				new_label.text = the_base.name

				var poly_pos = map_to_local(Vector2i(x, y))
				poly_pos.x -= 75
				var global_pos = to_global(poly_pos)
				var new_poly : Polygon2D = Polygon2D.new()
				new_poly.position = global_pos
				var height : int = 75
				var width : int = 200
				new_poly.set_polygon(PackedVector2Array([Vector2(0,0),Vector2(width,0),Vector2(width,height),Vector2(0,height)]))
				new_poly.set_color(Color(0,0,0,0.7))
				new_poly.add_child(new_label)

				label_holder.add_child(new_poly)

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
		
		set_cell(selection_layer, right, 9, Vector2i(3,0), 0)
		set_cell(selection_layer, left, 9, Vector2i(3,0), 0)
		set_cell(selection_layer, top, 9, Vector2i(3,0), 0)
		set_cell(selection_layer, bottom, 9, Vector2i(3,0), 0)
		set_cell(selection_layer, rightx, 9, Vector2i(3,0), 0)
		set_cell(selection_layer, leftx, 9, Vector2i(3,0), 0)
		set_cell(selection_layer, topx, 9, Vector2i(3,0), 0)
		set_cell(selection_layer, bottomx, 9, Vector2i(3,0), 0)

	# draw health decorators
	for x in range(width):
		for y in range(height):
			var lin_idx : int = convertTo1D(Vector2i(x,y))
			if unit_layer_health[lin_idx] != -1:
				var new_label : Label = Label.new()
				var label_pos = map_to_local(Vector2i(x, y))
				label_pos.x -= 180
				label_pos.y -= tile_set.tile_size.y - 80
				var global_pos = to_global(label_pos)
				new_label.position = global_pos
				new_label.label_settings = load("res://unit-hp-label-settings.tres")
				new_label.text = str(unit_layer_health[lin_idx])
				label_holder.add_child(new_label)

	# draw builder decorators
	for x in range(width):
		for y in range(height):
			var lin_idx : int = convertTo1D(Vector2i(x,y))
			if unit_layer_build[lin_idx] != -1 and unit_is_selected and selected_cell.x == x and selected_cell.y == y:
				var new_sprite : BuilderIcon = BuilderIcon.new()
				new_sprite.location = Vector2i(x,y)
				new_sprite.le = logic_engine
				var label_pos = map_to_local(Vector2i(x, y))
				label_pos.x += 50
				label_pos.y -= tile_set.tile_size.y - 20
				var global_pos = to_global(label_pos)
				new_sprite.position = global_pos
				new_sprite.texture = load("res://assets/tilesets/Builder_Selection_1.png")
				sprite_holder.add_child(new_sprite)



