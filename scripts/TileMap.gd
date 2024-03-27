extends TileMap
class_name IsoTileMap

@onready var logic_engine : LogicEngine = get_parent().get_node("LogicEngine")
@onready var character_body : CharacterBody2D = get_parent().get_node("CharacterBody2D")
@onready var map : Map = get_parent().get_node("Map")
@onready var label_holder : Node2D = get_node("LabelHolder")
@onready var sprite_holder : Node2D = get_node("SpriteHolder")
@onready var camera : Camera2D = get_parent().find_child("Camera2D")
@onready var characterbody : CharacterBody2D = get_parent().find_child("CharacterBody2D")

const unit_tile_set : int = 8
var width : int = 200
var height : int = 200

class SelectionState:
	var tile : Vector2i = Vector2i(-1,-1)
	var times : int = 0
	var map : Map = null
	var has_unit_selected : bool = false
	var unit_valid_moves : Array[Vector2i]
	var unit_valid_attacks : Array[Vector2i]

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
var improvement_layer_id : int = -1

class BuilderIcon extends TextureButton:
	var location : Vector2i
	var le : LogicEngine
	var tile_map : IsoTileMap

	func _pressed():
		tile_map.selectCell(Vector2i(-1,-1))
		le.buildCity(location)

class BuildUnit extends TextureButton:
	var unit : LogicEngine.Unit = null
	var location : Vector2i
	var tile_map : IsoTileMap
	var le : LogicEngine
	var base : LogicEngine.Base = null

	func _init(in_loc : Vector2i, in_le : LogicEngine, in_tile_map : IsoTileMap, in_base : LogicEngine.Base, in_unit : LogicEngine.Unit):
		location = in_loc
		tile_map = in_tile_map
		le = in_le
		base = in_base
		unit = in_unit

	func _back_button_pressed():
		var unit_select_ui = le.get_parent().find_child("UnitSelectUI") as UnitSelectUI
		unit_select_ui.set_visible(false)

	func _train_button_pressed():
		if unit:
			unit.setLocation(location)
			le.players[0].units.append(unit)
			base.addSupportedUnit(unit)
			unit.setSupportingBase(base)
			tile_map.drawUnit(unit)
			unit = null
			tile_map.selection.times += 1

		var unit_select_ui = le.get_parent().find_child("UnitSelectUI") as UnitSelectUI
		unit_select_ui.set_visible(false)

	func _pressed():
		var unit_select_ui = le.get_parent().find_child("UnitSelectUI") as UnitSelectUI
		unit.setupSelectDiaglog(unit_select_ui)

		var train_button = unit_select_ui.find_child("TrainButton", true) as Button
		train_button.pressed.connect(_train_button_pressed)

		var back_button = unit_select_ui.find_child("BackButton", true) as Button
		back_button.pressed.connect(_back_button_pressed)

		unit_select_ui.set_visible(true)

class ExtractResource extends Button:
	var location : Vector2i
	var tile_map : IsoTileMap
	var le : LogicEngine
	var base : LogicEngine.Base = null

	func _init(name : String, in_loc : Vector2i, in_le : LogicEngine, in_tile_map : IsoTileMap, in_base : LogicEngine.Base):
		set_text(name)
		location = in_loc
		tile_map = in_tile_map
		le = in_le
		base = in_base
		
	func _pressed():
		print("extracted crystal")
		base.increasePopulation()
		tile_map.removeResource(location)
		
class BuildImprovement extends Button:
	var location : Vector2i
	var tile_map : IsoTileMap
	var le : LogicEngine
	var base : LogicEngine.Base = null
	var build_name : String = ""

	func _init(in_build_name : String, in_loc : Vector2i, in_le : LogicEngine, in_tile_map : IsoTileMap, in_base : LogicEngine.Base):
		build_name = in_build_name
		set_text(build_name)
		location = in_loc
		tile_map = in_tile_map
		le = in_le
		base = in_base
		
	func _pressed():
		print("build improvement")
		if build_name == "Wormhole":
			var improvement = base.addWormhole(location)
			tile_map.set_cell(tile_map.improvement_layer_id, location, improvement.ident.source_id, improvement.ident.atlas_coord)
		elif build_name == "Greenhouse":
			var improvement = base.addGreenhouse(location)
			tile_map.set_cell(tile_map.improvement_layer_id, location, improvement.ident.source_id, improvement.ident.atlas_coord)
		elif build_name == "Spacedock":
			var improvement = base.addSpacedock(location)
			tile_map.set_cell(tile_map.improvement_layer_id, location, improvement.ident.source_id, improvement.ident.atlas_coord)
		elif build_name == "Solarfarm":
			var improvement = base.addSolarfarm(location)
			tile_map.set_cell(tile_map.improvement_layer_id, location, improvement.ident.source_id, improvement.ident.atlas_coord)

func convertTo1D(idx : Vector2i) -> int:
	return idx.x * width + idx.y

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if not event.is_pressed():
			var global_pos = get_global_mouse_position()
			var local_pos = to_local(global_pos)
			var map_pos = local_to_map(local_pos)
			print("global:, ", global_pos, ", local: ", local_pos, ", map: ", map_pos)
			selectCell(map_pos)

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMagnifyGesture:
		camera.set_zoom(Vector2(camera.zoom.x * event.factor, camera.zoom.y * event.factor))
	elif event is InputEventPanGesture:
		var local_delta = event.delta * 50
		characterbody.set_position(Vector2(characterbody.get_position().x + local_delta.x, characterbody.get_position().y + local_delta.y))

var start_zoom: Vector2
var start_dist: float
var touch_points: Dictionary = {}
var start_angle: float
var current_angle: float

func _handle_touch(event: InputEventScreenTouch):
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)

func _handle_drag(event: InputEventScreenDrag):
	if touch_points.size() == 2:
		# Find the index of the not moving
		var pivot_index = 1 if event.index == 0 else 0

		# get the 3 point involved
		var pivot_point: Vector2 = touch_points[pivot_index]
		var old_point: Vector2 = touch_points[event.index]
		var new_point: Vector2 = event.position

		var old_vector: Vector2 = old_point - pivot_point
		var new_vector: Vector2 = new_point - pivot_point
		
		var delta_scale = new_vector.length() / old_vector.length()
		camera.set_zoom(Vector2(camera.get_zoom().x * delta_scale, camera.get_zoom().y * delta_scale))
		touch_points[event.index] = new_point

const unit_set : int = 8
const unit_set_selected : int = 10
const unit_set_disabled : int = 16
const unit_set_selected_disabled : int = 17
const unit_set_ready_move : int = 18

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)

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
		if get_layer_name(i) == "Improvement":
			improvement_layer_id = i

	drawTerrainLayer()

	selection = SelectionState.new(map)

	var source = tile_set.get_source(8) as TileSetAtlasSource
	var source_sel = tile_set.get_source(unit_set_selected) as TileSetAtlasSource
	var source_dis = tile_set.get_source(unit_set_disabled) as TileSetAtlasSource
	var source_dis_sel = tile_set.get_source(unit_set_selected_disabled) as TileSetAtlasSource
	var source_move = tile_set.get_source(unit_set_ready_move) as TileSetAtlasSource
	for x in 8:
		for y in 4:
			var coord = Vector2i(x,y)
			if source.get_tile_data(coord, 0):
				source_sel.get_tile_data(coord, 0).set_texture_origin(source.get_tile_data(coord, 0).get_texture_origin())
				source_dis.get_tile_data(coord, 0).set_texture_origin(source.get_tile_data(coord, 0).get_texture_origin())
				source_dis_sel.get_tile_data(coord, 0).set_texture_origin(source.get_tile_data(coord, 0).get_texture_origin())
				source_move.get_tile_data(coord, 0).set_texture_origin(source.get_tile_data(coord, 0).get_texture_origin())
				source_dis.get_tile_data(coord, 0).set_modulate(Color(0.5,0.5,0.5,1.0))
				source_dis_sel.get_tile_data(coord, 0).set_modulate(Color(0.5,0.5,0.5,1.0))
				#source_dis_sel.get_tile_data(coord, 0).set_material(load("res://orb-shader.tres"))
				source_move.get_tile_data(coord, 0).set_material(load("res://move-material.tres"))

func removeResource(t : Vector2i):
	map.getTileVec(t).resource.source_id = -1
	set_cell(resource_layer_id, t, -1, Vector2i(-1,-1))

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
					
				if tile.resource.source_id != -1:
					set_cell(resource_layer_id, Vector2i(x,y), tile.resource.source_id, tile.resource.atlas_coord)

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

func makeTextureForButton(ident : Map.AtlasIdent) -> AtlasTexture:
	var source = tile_set.get_source(ident.source_id) as TileSetAtlasSource
	#var origin = source.get_tile_data(ident.atlas_coord, 0).texture_origin
	var texture = source.get_texture()
	var t : AtlasTexture = AtlasTexture.new()
	t.set_atlas(texture)
	t.set_region(source.get_tile_texture_region(ident.atlas_coord))
	return t

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

	var base_select_ui = get_parent().find_child("BaseSelectUI") as BaseSelectUI
	base.setupSelectBaseDiaglog(base_select_ui)
	base_select_ui.set_visible(true)

	#if base.canSupportMoreUnits():
		#var units : Array[LogicEngine.Unit] = [
			#LogicEngine.ColonypodUnit.new(logic_engine, self),
			#LogicEngine.SpacemanUnit.new(logic_engine, self),
			#LogicEngine.NukeUnit.new(logic_engine, self),
			#LogicEngine.HoverSaberUnit.new(logic_engine, self),
			#LogicEngine.SatelliteUnit.new(logic_engine, self),
			#LogicEngine.TankUnit.new(logic_engine, self),
			#LogicEngine.HackerUnit.new(logic_engine, self),
			#LogicEngine.MissileUnit.new(logic_engine, self)
		#]
#
		#if base.hasSpacedock():
			#units.append(LogicEngine.WormholeUnit.new(logic_engine, self))
			#units.append(LogicEngine.SpaceshipUnit.new(logic_engine, self))
			#units.append(LogicEngine.CapitalShipUnit.new(logic_engine, self))
#
		#for u in units:
			#var u1 = BuildUnit.new(loc, logic_engine, self, base, u)
			#u1.set_texture_normal(makeTextureForButton(u.getSmallImage()))
			#dcrc.add_child(u1)

func setUIForSquare(tile : Map.Tile):
	var dcr = get_parent().find_child("DynamicColorRect") as ColorRect
	dcr.visible = true
	var dcrc = get_parent().find_child("DynamicHBoxContainer") as HBoxContainer
	for child in dcrc.get_children():
		dcrc.remove_child(child)

	var loc = tile.getXY()
	
	if tile.resource.source_id != -1:
		var inside_base : bool = false
		var base : LogicEngine.Base = null

		for p in logic_engine.players:
			for b in p.bases:
				if loc in b.tiles_inside:
					inside_base = true
					base = b

		if inside_base:
			var u1 = ExtractResource.new("Extract Crystal", loc, logic_engine, self, base)
			dcrc.add_child(u1)
		else:
			if tile.type == Map.TileTypeEnum.LAND:
				var u1 = Label.new()
				u1.text = "Land square with Crystal"
				dcrc.add_child(u1)
			elif tile.type == Map.TileTypeEnum.MOUNTAIN:
				var u1 = Label.new()
				u1.text = "Mountain square with Crystal"
				dcrc.add_child(u1)

	else:
		if tile.type == Map.TileTypeEnum.LAND:
			var u1 = Label.new()
			u1.text = "Land square"
			dcrc.add_child(u1)
			
			if tile.isOownedByBase():
				var the_base = tile.baseOwnedBy()
				var u2 = BuildImprovement.new("Wormhole", loc, logic_engine, self, the_base)
				dcrc.add_child(u2)

				var u3 = BuildImprovement.new("Greenhouse", loc, logic_engine, self, the_base)
				dcrc.add_child(u3)

				var u4 = BuildImprovement.new("Solarfarm", loc, logic_engine, self, the_base)
				dcrc.add_child(u4)

		elif tile.type == Map.TileTypeEnum.MOUNTAIN:
			var u1 = Label.new()
			u1.text = "Mountain square"
			dcrc.add_child(u1)
		elif tile.type == Map.TileTypeEnum.SPACE:
			var u1 = Label.new()
			u1.text = "Space square"
			dcrc.add_child(u1)
		elif tile.type == Map.TileTypeEnum.ATMOSPHERE:
			var u1 = Label.new()
			u1.text = "Atmosphere square"
			dcrc.add_child(u1)

			if tile.isOownedByBase():
				var the_base = tile.baseOwnedBy()
				var u4 = BuildImprovement.new("Spacedock", loc, logic_engine, self, the_base)
				#u4.set_texture_normal(makeTextureForButton(LogicEngine.SpacemanUnit.smallImage()))
				dcrc.add_child(u4)

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
		print("Here")
		var elm = map.getTileVec(selection.getTile())
		var unit = elm.unit
		
		if unit:
			if unit.canMove():
				var valid_moves = selection.unit_valid_moves
				if tile in valid_moves:
					var into_wormhole : bool = false
					if map.getTileVec(tile).isOownedByBase():
						var base = map.getTileVec(tile).baseOwnedBy()
						for i in base.improvements:
							if i.location == tile and i.isWormhole():
								into_wormhole = true

					if into_wormhole:
						print("into wormhole")

					print("moving to tile: ", tile)
					undrawUnit(unit, unit.location, false)
					var tween = animateUnit(unit, selection.getTile(), tile)
					elm.unit = null

					var do_move = func do_move_impl():
						logic_engine.moveUnit(unit, selection.getTile(), tile)

					tween.tween_callback(do_move)
					
					tile = Vector2i(-1,-1)

					for move in valid_moves:
						set_cell(selection_layer, move, -1, Vector2i(3,0), 0)

			if unit.canAttack():
				var squares_can_attack : Array[Vector2i] = selection.unit_valid_attacks
				if tile in squares_can_attack:
					logic_engine.unitAttack(unit, map.getTileVec(tile).unit)
					tile = Vector2i(-1,-1)

				for s in squares_can_attack:
					set_cell(selection_layer, s, -1, Vector2i(3,0), 0)

			if tile != Vector2i(-1,-1):
				drawUnit(unit)

		for move in selection.unit_valid_moves:
			set_cell(selection_layer, move, -1, Vector2i(3,0), 0)
		for s in selection.unit_valid_attacks:
			set_cell(selection_layer, s, -1, Vector2i(3,0), 0)
	
	var old_tile = selection.select(tile)

	if old_tile != tile:
		unselectCell(old_tile)

	var unit_selected = selection.unitSelected()
	var base_selected = selection.baseSelected()

	print("unit: ", unit_selected, ", base:", base_selected, ", times:", selection.times)

	if unit_selected:
		unselectCell(selection.getTile())

		var unit = map.getTileVec(selection.getTile()).unit

		var source : TileSetAtlasSource
		if unit.canMove() or (unit.canAttack() and unit.getUnitsWithinRange() != []):
			set_cell(unit_layer_id, selection.getTile(), unit_set_selected, unit.unit_coord, 0)
			source = tile_set.get_source(unit_set_selected) as TileSetAtlasSource
		else:
			set_cell(unit_layer_id, selection.getTile(), unit_set_selected_disabled, unit.unit_coord, 0)
			source = tile_set.get_source(unit_set_selected_disabled) as TileSetAtlasSource

		var origin = source.get_tile_data(unit.unit_coord, 0).texture_origin
		var tile_data = source.get_tile_data(unit.unit_coord, 0)

		var tween = get_tree().create_tween()
		tween.tween_property(tile_data, "texture_origin:y", origin.y+50, 0.1).set_trans(Tween.TRANS_LINEAR)
		tween.chain().tween_property(tile_data, "texture_origin:y", origin.y, 0.1).set_trans(Tween.TRANS_LINEAR)
		
		var into_wormhole : bool = false
		if map.getTileVec(tile).isOownedByBase():
			var base = map.getTileVec(selection.getTile()).baseOwnedBy()
			for i in base.improvements:
				if i.location == tile and i.isWormhole():
					into_wormhole = true

		if unit.canMove():
			var all_moves : Array[Vector2i] = []
			if into_wormhole:
				for p in logic_engine.players:
					for u in p.units:
						if u is LogicEngine.WormholeUnit:
							var valid_moves = unit.getValidMovesImpl([u.location])
							all_moves += valid_moves

			all_moves += unit.getValidMoves()
			selection.unit_valid_moves = all_moves
			for move in all_moves:
				set_cell(selection_layer, move, 9, Vector2i(3,0), 0)

		if unit.canAttack():
			var units_can_attack : Array[LogicEngine.Unit] = unit.getUnitsWithinRange()
			selection.unit_valid_attacks = []
			for u in units_can_attack:
				selection.unit_valid_attacks.append(u.location)
				set_cell(selection_layer, u.location, 9, Vector2i(3,1), 0)


		if unit.hasBuilder():
			print("making builder")
			builder = BuilderIcon.new()
			builder.location = unit.location
			builder.le = logic_engine
			builder.tile_map = self
			var builder_label_pos = map_to_local(unit.location)
			builder_label_pos.x += 50
			builder_label_pos.y -= tile_set.tile_size.y - 20
			var builder_global_pos = to_global(builder_label_pos)
			builder.position = builder_global_pos
			builder.set_texture_normal(load("res://assets/tilesets/Builder_Selection_1.png"))
			sprite_holder.add_child(builder)
	elif base_selected:
		var base = map.getTileVec(selection.getTile()).base
		setUIForBase(base)
		for line in base.highlight_border_lines:
			line.set_visible(true)
	else:
		if selection.validTile():
			set_cell(selection_layer, selection.getTile(), 9, Vector2i(0,0), 0)
			setUIForSquare(map.getTileVec(selection.getTile()))

func updateCity(base : LogicEngine.Base):
	set_cell(city_layer_id, base.location, base.base_source_id, base.base_coord, 0)

func drawCity(base : LogicEngine.Base):
	set_cell(city_layer_id, base.location, base.base_source_id, base.base_coord, 0)

	var new_label : Label = Label.new()
	#new_label.position.x = 40
	new_label.label_settings = load("res://base-name-label-settings.tres")
	new_label.text = base.name
	new_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)

	var poly_pos = map_to_local(base.location)
	var global_pos = to_global(poly_pos)

	var credit_image : TextureRect = TextureRect.new()
	credit_image.set_texture(load("res://assets/tilesets/Energy Credit_2_Small.png"))
	credit_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	var pc = PanelContainer.new()
	pc.set_position(global_pos)
	var new_pc : HBoxContainer = HBoxContainer.new()
	new_pc.add_child(new_label)
	new_pc.add_child(credit_image)

	var num_credits : Label = Label.new()
	num_credits.set_text(str(base.creditsPerTurn()))
	num_credits.set_theme(load("res://selected-theme.tres"))

	new_pc.add_child(num_credits)

	pc.add_child(new_pc)

	sprite_holder.add_child(pc)
	pc.set_position(Vector2(pc.get_position().x - pc.get_size().x/2, pc.get_position().y))

	var base_pos = map_to_local(base.location)
	var global_base_pos = to_global(base_pos)
	var len = base.level+1
	var new_pop_bar : PopulationBar2 = PopulationBar2.new(base)
	global_base_pos.x -= len*120/2
	global_base_pos.y += 75
	new_pop_bar.position = global_base_pos
	new_pop_bar.set_size(Vector2(len*120,50))
	new_pop_bar.setPopulation(base.population)
	sprite_holder.add_child(new_pop_bar)
	base.population_bar = new_pop_bar
	new_pop_bar.drawLines()

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

func undrawUnit(unit : LogicEngine.Unit, tile : Vector2i, is_move : bool):
	set_cell(unit_layer_id, tile, -1, Vector2i(-1,-1), 0)
	if !is_move:
		unit.unit_health_label.queue_free()
		unit.unit_health_label = null

func drawUnit(unit : LogicEngine.Unit):
	if unit.canMove():
		set_cell(unit_layer_id, unit.location, unit_set_ready_move, unit.unit_coord, 0)
	elif unit.canAttack() and unit.getUnitsWithinRange() != []:
		set_cell(unit_layer_id, unit.location, unit_set, unit.unit_coord, 0)
	else:
		set_cell(unit_layer_id, unit.location, unit_set_disabled, unit.unit_coord, 0)

	# raster the health indicator
	if !unit.unit_health_label:
		unit.unit_health_label = Label.new()

		unit.unit_health_label.label_settings = load("res://unit-hp-label-settings.tres")
		label_holder.add_child(unit.unit_health_label)

	unit.unit_health_label.text = str(unit.abilities.hp)

	var label_pos = map_to_local(unit.location)
	label_pos.x -= 180
	label_pos.y -= tile_set.tile_size.y - 80
	var global_pos = to_global(label_pos)
	unit.unit_health_label.position = global_pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
