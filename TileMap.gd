extends TileMap
class_name IsoTileMap

@onready var logic_engine : LogicEngine = get_parent().get_node("LogicEngine")
@onready var map : Map = get_parent().get_node("Map")
@onready var label_holder : Node2D = get_node("LabelHolder")
@onready var sprite_holder : Node2D = get_node("SpriteHolder")

const unit_tile_set : int = 8
var width : int = 200
var height : int = 200

class SelectionState:
	var tile : Vector2i = Vector2i(-1,-1)
	var times : int = 0
	var map : Map = null
	var has_unit_selected : bool = false
	var unit_valid_moves : Array[Vector2i]

	func _init(in_map : Map):
		map = in_map

	func select(in_tile : Vector2i) -> Vector2i:
		var old_tile = tile
	
		if in_tile != tile:
			tile = in_tile
			times = 0
		else:
			times += 1
	
		has_unit_selected = unitSelected()
	
		return old_tile

	func getTile() -> Vector2i:
		return tile

	func validTile() -> bool:
		return tile != Vector2i(-1,-1)

	func selectedTileHasBase() -> bool:
		if validTile():
			return map.getTileVec(tile).hasBase()
		else:
			return false
			
	func selectedTileHasUnit() -> bool:
		if validTile():
			return map.getTileVec(tile).hasUnit()
		else:
			return false

	func unitSelected() -> bool:
		if selectedTileHasUnit() and times % 2 == 0:
			return true
		else:
			return false

	func baseSelected() -> bool:
		if selectedTileHasBase():
			if selectedTileHasUnit() and times % 2 == 1:
				return true
			elif selectedTileHasUnit() and times % 2 == 0:
				return false
			return true
		else:
			return false

var selection : SelectionState = null

var selection_layer : int = -1
var unit_layer_id : int = -1
var city_layer_id : int = -1
var terrain_layer_id : int = -1
var resource_layer_id : int = -1
var space_layer_id : int = -1

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
			le.buildCity(location)
			
class BuildUnit extends Button:
	var unit : LogicEngine.Unit = null
	var location : Vector2i
	var tile_map : IsoTileMap
	var le : LogicEngine

	func _init(name : String, in_loc : Vector2i, in_le : LogicEngine, in_tile_map : IsoTileMap):
		set_text(name)
		location = in_loc
		tile_map = in_tile_map
		le = in_le
		
	func _pressed():
		if get_text() == "ColonyPod":
			unit = LogicEngine.ColonypodUnit.new(le, tile_map, location)
			le.players[0].units.append(unit)
		elif get_text() == "Spaceman":
			unit = LogicEngine.SpacemanUnit.new(le, tile_map, location)
			le.players[0].units.append(unit)

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
		if get_layer_name(i) == "Space":
			space_layer_id = i

	drawTerrainLayer()

	selection = SelectionState.new(map)

func drawTerrainLayer():
	# Draw the base map layer
	for x in range(width):
		for y in range(height):
			var tile = map.getTileXY(x, y)
			if tile != null:
				if tile.type == Map.TileTypeEnum.SPACE or tile.type == Map.TileTypeEnum.ATMOSPHERE:
					set_cell(space_layer_id, Vector2i(x,y), tile.atlas_space.source_id, tile.atlas_space.atlas_coord)
				
				if tile.type != Map.TileTypeEnum.SPACE:
					set_cell(terrain_layer_id, Vector2i(x,y), tile.atlas.source_id, tile.atlas.atlas_coord)
					
				#if tile.type == Map.TileTypeEnum.SPACE:
					#var local_pos = map_to_local(Vector2i(x,y))
					#var x_rand = randf() * tile_set.tile_size.x
					#var y_rand = randf() * tile_set.tile_size.y
					#var global_pos = to_global(Vector2(local_pos.x - tile_set.tile_size.x/2 + x_rand, local_pos.y - tile_set.tile_size.y/2 + y_rand))
					#var c : Circle2D = Circle2D.new()
					#c.position = global_pos
					#c.radius = 10
					#sprite_holder.add_child(c)

func animateUnit(unit : LogicEngine.Unit, from : Vector2i, to : Vector2i):
	var new_sprite : Sprite2D = Sprite2D.new()
	var start_pos = to_global(map_to_local(from))
	var end_pos = to_global(map_to_local(to))
	new_sprite.position = start_pos
	var source = tile_set.get_source(unit.unit_source_id) as TileSetAtlasSource
	var origin = source.get_tile_data(unit.unit_coord, 0).texture_origin
	start_pos.y -= origin.y
	end_pos.y -= origin.y
	start_pos.x -= origin.x
	end_pos.x -= origin.x
	new_sprite.texture = source.get_texture()
	new_sprite.region_enabled = true
	new_sprite.region_rect = source.get_tile_texture_region(unit.unit_coord)
	sprite_holder.add_child(new_sprite)

	var tween = get_tree().create_tween()
	tween.tween_property(new_sprite, "position", end_pos, 0.3).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(new_sprite.queue_free)
	return tween

func setUIForBase(base : LogicEngine.Base):
	print("setUIBase")
	var dcr = get_parent().find_child("DynamicColorRect") as ColorRect
	dcr.visible = true
	var dcrc = get_parent().find_child("DynamicHBoxContainer") as HBoxContainer
	for child in dcrc.get_children():
		dcrc.remove_child(child)
	var new_label : Label = Label.new()
	new_label.text = base.name + ": Level " + str(base.level)
	dcrc.add_child(new_label)
#
	var loc = base.location
	var u1 = BuildUnit.new("ColonyPod", loc, logic_engine, self)
	dcrc.add_child(u1)
	
	var u2 = BuildUnit.new("Spaceman", loc, logic_engine, self)
	dcrc.add_child(u2)
#
	#var u2 = BuildUnit.new(LogicEngine.ColonypodUnit.new(logic_engine, self, loc))
	#dcrc.add_child(u2)
#
	#var u3 = BuildUnit.new(LogicEngine.SpacemanUnit.new(logic_engine, self, loc))
	#dcrc.add_child(u3)
#
	#var u4 = BuildUnit.new(LogicEngine.TankUnit.new(logic_engine, self, loc))
	#dcrc.add_child(u4)

func unselectCell(tile : Vector2i):
	set_cell(selection_layer, tile, -1, Vector2i(0,0), 0)
	var dcr = get_parent().find_child("DynamicColorRect") as ColorRect
	dcr.visible = false
	if builder:
		builder.queue_free()
		builder = null
	if map.getTileVec(tile).hasBase():
		var base = map.getTileVec(tile).base
		for line in base.highlight_border_lines:
			line.set_visible(false)

func selectCell(tile : Vector2i):
	if selection.has_unit_selected:
		var elm = map.getTileVec(selection.getTile())
		var unit = elm.unit
		
		if unit:
			var valid_moves = unit.getValidMoves()
			if tile in valid_moves:
				print("moving to tile: ", tile)
				var tween = animateUnit(unit, selection.getTile(), tile)
				elm.unit = null

				var do_move = func do_move_impl():
					logic_engine.moveUnit(unit, selection.getTile(), tile)

				tween.tween_callback(do_move)
				
				tile = Vector2i(-1,-1)
		
			for move in valid_moves:
				set_cell(selection_layer, move, -1, Vector2i(3,0), 0)
		else:
			for move in selection.unit_valid_moves:
				set_cell(selection_layer, move, -1, Vector2i(3,0), 0)
	
	var old_tile = selection.select(tile)

	if old_tile != tile:
		unselectCell(old_tile)

	var unit_selected = selection.unitSelected()
	var base_selected = selection.baseSelected()

	print("unit: ", unit_selected, ", base:", base_selected)

	if unit_selected:
		unselectCell(selection.getTile())

		var unit = map.getTileVec(selection.getTile()).unit
		var source = tile_set.get_source(10) as TileSetAtlasSource
		var origin = source.get_tile_data(unit.unit_coord, 0).texture_origin
		var tile_data = source.get_tile_data(unit.unit_coord, 0)

		var tween = get_tree().create_tween()
		tween.tween_property(tile_data, "texture_origin:y", origin.y+50, 0.1).set_trans(Tween.TRANS_LINEAR)
		tween.chain().tween_property(tile_data, "texture_origin:y", origin.y, 0.1).set_trans(Tween.TRANS_LINEAR)
		
		var valid_moves = unit.getValidMoves()
		selection.unit_valid_moves = valid_moves
		for move in valid_moves:
			set_cell(selection_layer, move, 9, Vector2i(3,0), 0)
	elif base_selected:
		var base = map.getTileVec(selection.getTile()).base
		setUIForBase(base)
		for line in base.highlight_border_lines:
			line.set_visible(true)
	else:
		if selection.validTile():
			set_cell(selection_layer, selection.getTile(), 9, Vector2i(0,0), 0)

func drawCity(base : LogicEngine.Base):
	set_cell(city_layer_id, base.location, base.base_source_id, base.base_coord, 0)

	var new_label : Label = Label.new()
	new_label.position.x = 40
	new_label.label_settings = load("res://base-name-label-settings.tres")
	new_label.text = base.name
	new_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)

	var poly_pos = map_to_local(base.location)
	var global_pos = to_global(poly_pos)
	
	var new_pc : PanelContainer = PanelContainer.new()
	new_pc.position = global_pos
	new_pc.add_child(new_label)
	new_pc.set_size(Vector2(150,70))
	new_pc.position.x -= new_pc.get_size().x/2
	sprite_holder.add_child(new_pc)

	var base_pos = map_to_local(base.location)
	var global_base_pos = to_global(base_pos)
	var len = base.level+1
	var new_pop_bar : PopulationBar2 = PopulationBar2.new(3)
	global_base_pos.x -= len*200/2
	global_base_pos.y += 75
	new_pop_bar.position = global_base_pos
	new_pop_bar.set_size(Vector2(len*200,50))
	sprite_holder.add_child(new_pop_bar)

	for p in logic_engine.players:
		for b in p.bases:
			for l in b.border_lines:
				l.queue_free()
			b.border_lines.clear()

			for l in b.highlight_border_lines:
				l.queue_free()
			b.highlight_border_lines.clear()

			var border_lines = drawBorders(b, false)
			for l in border_lines:
				sprite_holder.add_child(l)
				b.border_lines.append(l)

			var highlight_border_lines = drawBorders(b, true)
			for l in highlight_border_lines:
				l.set_default_color(Color(0,0.3,1.0,0.5))
				l.set_visible(false)
				sprite_holder.add_child(l)
				b.highlight_border_lines.append(l)

func drawBorders(base : LogicEngine.Base, draw_overlap : bool) -> Array[Line2D]:
	var lines : Array[Line2D] = []

	for tile in base.tiles_inside_outer:
		var line : Line2D = Line2D.new()
		line.set_default_color(Color(1.0,1.0,0.5,0.5))
		line.set_z_index(-1)
		line.set_width(15)
		line.set_joint_mode(Line2D.LINE_JOINT_BEVEL)
		#line.set_texture(load("res://dashed-line-material.tres"))

		var local_pos = map_to_local(tile)
		var offset = 20

		var offsetPoint = func off(pt : Vector2) -> Vector2:
			pt.x -= 15
			pt.y -= offset+20
			return pt

		if tile.x > base.location.x or true:
			var base_owned = map.getTileVec(Vector2i(tile.x+1, tile.y)).baseOwnedBy()
			if not base_owned or (draw_overlap and not base_owned == base):
				var p1 = to_global(Vector2(local_pos.x, local_pos.y + tile_set.tile_size.y/2))
				var p2 = to_global(Vector2(local_pos.x + tile_set.tile_size.x/2, local_pos.y))
				line.add_point(offsetPoint.call(p1))
				line.add_point(offsetPoint.call(p2))

		if tile.y > base.location.y or true:
			var base_owned = map.getTileVec(Vector2i(tile.x, tile.y+1)).baseOwnedBy()
			if not base_owned or (draw_overlap and not base_owned == base):
				var p1 = to_global(Vector2(local_pos.x, local_pos.y + tile_set.tile_size.y/2))
				var p2 = to_global(Vector2(local_pos.x - tile_set.tile_size.x/2, local_pos.y))
				line.add_point(offsetPoint.call(p1))
				line.add_point(offsetPoint.call(p2))

		if tile.x < base.location.x or true:
			var base_owned = map.getTileVec(Vector2i(tile.x-1, tile.y)).baseOwnedBy()
			if not base_owned or (draw_overlap and not base_owned == base):
				var p1 = to_global(Vector2(local_pos.x, local_pos.y - tile_set.tile_size.y/2))
				var p2 = to_global(Vector2(local_pos.x - tile_set.tile_size.x/2, local_pos.y))
				line.add_point(offsetPoint.call(p1))
				line.add_point(offsetPoint.call(p2))

		if tile.y < base.location.y or true:
			var base_owned = map.getTileVec(Vector2i(tile.x, tile.y-1)).baseOwnedBy()
			if not base_owned or (draw_overlap and not base_owned == base):
				var p1 = to_global(Vector2(local_pos.x, local_pos.y - tile_set.tile_size.y/2))
				var p2 = to_global(Vector2(local_pos.x + tile_set.tile_size.x/2, local_pos.y))
				line.add_point(offsetPoint.call(p1))
				line.add_point(offsetPoint.call(p2))

		lines.append(line)

	return lines

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
				#set_cell(selection_layer, selection.getTile(), -1, Vector2i(0,0), 0)
				
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
				var selected_tile = selection.getTile()
				if not builder and tile.unit.hasBuilder() and selection.unitSelected() and selected_tile.x == x and selected_tile.y == y:
					print("making builder")
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

	var unit_selected = selection.unitSelected()
	if unit_selected:
		var unit = map.getTileVec(selection.getTile()).unit
		set_cell(unit_layer_id, selection.getTile(), unit.unit_source_id+2, unit.unit_coord, 0)





