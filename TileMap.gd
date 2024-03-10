extends TileMap
class_name IsoTileMap

@onready var logic_engine : LogicEngine = get_parent().get_node("LogicEngine")
@onready var map : Map = get_parent().get_node("Map")
@onready var label_holder : Node2D = get_node("LabelHolder")
@onready var sprite_holder : Node2D = get_node("SpriteHolder")

const unit_tile_set : int = 8
var width : int = 200
var height : int = 200
var selected_cell : Vector2i = Vector2i(-1,-1)
var selected_times : int = 0
var unit_is_selected : bool = false

var selection_layer : int = -1
var unit_layer_id : int = -1
var city_layer_id : int = -1
var terrain_layer_id : int = -1
var resource_layer_id : int = -1

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

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in get_layers_count():
		if get_layer_name(i) == "Base layer":
			terrain_layer_id = i
		if get_layer_name(i) == "Resources":
			resource_layer_id = i
		if get_layer_name(i) == "City":
			city_layer_id = i
		if get_layer_name(i) == "Unit layer":
			unit_layer_id = i
		if get_layer_name(i) == "Selection":
			selection_layer = i

	drawTerrainLayer()

func drawTerrainLayer():
	# Draw the base map layer
	for x in range(width):
		for y in range(height):
			var tile = map.getTileXY(x, y)
			if tile != null:
				set_cell(terrain_layer_id, Vector2i(x,y), tile.atlas.source_id, tile.atlas.atlas_coord)

func hasUnitOnSquare(cell : Vector2i) -> bool:
	if cell.x == -1 or cell.y == -1:
		return false
	else:
		return map.getTileVec(cell).unit != null
		#return unit_layer[convertTo1D(cell)].x != -1 and unit_layer[convertTo1D(cell)].y != -1 and unit_tile_set_layer[convertTo1D(cell)] != -1

func unselectCurrent():
	if selected_cell.x != -1 and selected_cell.y != -1:
		set_cell(selection_layer, selected_cell, -1, Vector2i(0,0), 0)
	unit_is_selected = false
	if builder:
		builder.queue_free()
	
func unselectAround():
	var unit = map.getTileVec(selected_cell).unit
	if unit:
		for move in unit.getValidMoves():
			set_cell(selection_layer, move, -1, Vector2i(-1,-1), 0)
	if builder:
		builder.queue_free()
		builder = null

func animateUnit(unit : LogicEngine.Unit, from : Vector2i, to : Vector2i):
	var new_sprite : Sprite2D = Sprite2D.new()
	var start_pos = to_global(map_to_local(from))
	var end_pos = to_global(map_to_local(to))
	new_sprite.position = start_pos
	var source = tile_set.get_source(unit.unit_source_id) as TileSetAtlasSource
	var origin = source.get_tile_data(unit.unit_coord, 0).texture_origin
	start_pos.y -= origin.y
	end_pos.y -= origin.y
	new_sprite.texture = source.get_texture()
	new_sprite.region_enabled = true
	new_sprite.region_rect = source.get_tile_texture_region(unit.unit_coord)
	sprite_holder.add_child(new_sprite)

	var tween = get_tree().create_tween()
	tween.tween_property(new_sprite, "position", end_pos, 0.3).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(new_sprite.queue_free)
	return tween

func selectCell(cell : Vector2i):
	var set_selected = true
	if cell == selected_cell:
		selected_times += 1
		
		if hasUnitOnSquare(selected_cell) and selected_times % 2 != 0:
			unit_is_selected = false
			unselectAround()
	else:
		if hasUnitOnSquare(selected_cell) and selected_times % 2 == 0:
			print("calling move unit")
			unselectAround()
			var tile = map.getTileVec(selected_cell)
			var unit = tile.unit
			if cell in unit.getValidMoves():
				var tween = animateUnit(unit, selected_cell, cell)
				tile.unit = null

				var do_move = func do_move_impl():
					logic_engine.moveUnit(unit, selected_cell, cell)

				tween.tween_callback(do_move)
			selected_cell = Vector2i(-1,-1)
			set_selected = false
		else:
			unselectAround()
		
		unselectCurrent()
		selected_times = 0

	if set_selected:
		selected_cell = cell
		if hasUnitOnSquare(selected_cell):
			var unit = map.getTileVec(selected_cell).unit
			var source = tile_set.get_source(10) as TileSetAtlasSource
			var origin = source.get_tile_data(unit.unit_coord, 0).texture_origin
			var tile_data = source.get_tile_data(unit.unit_coord, 0)

			var tween = get_tree().create_tween()
			tween.tween_property(tile_data, "texture_origin:y", origin.y+50, 0.1).set_trans(Tween.TRANS_LINEAR)
			tween.chain().tween_property(tile_data, "texture_origin:y", origin.y, 0.1).set_trans(Tween.TRANS_LINEAR)

var builder : BuilderIcon = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for child in label_holder.get_children():
		label_holder.remove_child(child)

	# Draw the unit layer
	for x in range(width):
		for y in range(height):
			var tile = map.getTileXY(x, y)
			if tile != null and tile.unit != null:
				set_cell(unit_layer_id, Vector2i(x,y), tile.unit.unit_source_id, tile.unit.unit_coord, 0)
				set_cell(selection_layer, selected_cell, -1, Vector2i(0,0), 0)
				
				# raster the health indicator
				var new_label : Label = Label.new()
				var label_pos = map_to_local(Vector2i(x, y))
				label_pos.x -= 180
				label_pos.y -= tile_set.tile_size.y - 80
				var global_pos = to_global(label_pos)
				new_label.position = global_pos
				new_label.label_settings = load("res://unit-hp-label-settings.tres")
				new_label.text = str(tile.unit.abilities.hp)
				label_holder.add_child(new_label)
				
				# check if we need to raster a builder icon
				if not builder and tile.unit.hasBuilder() and unit_is_selected and selected_cell.x == x and selected_cell.y == y:
					builder = BuilderIcon.new()
					builder.location = Vector2i(x,y)
					builder.le = logic_engine
					var builder_label_pos = map_to_local(Vector2i(x, y))
					builder_label_pos.x += 50
					builder_label_pos.y -= tile_set.tile_size.y - 20
					var builder_global_pos = to_global(builder_label_pos)
					builder.position = builder_global_pos
					builder.texture = load("res://assets/tilesets/Builder_Selection_1.png")
					sprite_holder.add_child(builder)
			else:
				set_cell(unit_layer_id, Vector2i(x,y), -1, Vector2i(-1,-1), 0)

	# Draw the city layer
	for x in range(width):
		for y in range(height):
			var tile = map.getTileVec(Vector2i(x,y))
			if tile.base != null:
				set_cell(city_layer_id, Vector2i(x,y), tile.base.base_source_id, tile.base.base_coord, 0)

				var new_label : Label = Label.new()
				new_label.position.x = 40
				new_label.label_settings = load("res://base-name-label-settings.tres")
				new_label.text = tile.base.name

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
			var unit = map.getTileVec(selected_cell).unit
			var valid_move_squares : Array[Vector2i] = unit.getValidMoves()
			set_cell(unit_layer_id, selected_cell, unit.unit_source_id+2, unit.unit_coord, 0)
			unit_is_selected = true
		else:
			set_cell(selection_layer, selected_cell, 9, Vector2i(0,0), 0)

	if unit_is_selected:
		var unit = map.getTileVec(selected_cell).unit

		if unit:
			for move in unit.getValidMoves():
				set_cell(selection_layer, move, 9, Vector2i(3,0), 0)




