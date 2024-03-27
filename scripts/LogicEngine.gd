class_name LogicEngine extends Node

@onready var tile_map : IsoTileMap = get_parent().get_node("Tiles")
@onready var map : Map = get_parent().get_node("Map")

var turn_counter : int = 0
var players : Array[Player]

const unit_tile_set : int = 8

static func getBasicDirections() -> Array[Vector2i]:
	var basic_directions : Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1),
		Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, 1)
		]
	return basic_directions

class Player:
	var player_id : int = -1
	var last_turn_completed : int = -1
	var units : Array[Unit]
	var bases : Array[Base]
	var tile_map : IsoTileMap
	var le : LogicEngine
	var num_credits : int = 0
	var num_credits_per_turn : int = 0
	var score : int = 0
	
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_player_id : int):
		tile_map = in_tile_map
		player_id = in_player_id
		le = in_le

		# Dummy insertion of a unit
		if player_id == 0:
			units.append(SpacemanUnit.new(in_le, tile_map, Vector2i(player_id+5, player_id+5)))
			units.append(SatelliteUnit.new(in_le, tile_map, Vector2i(player_id+1, player_id+1)))
		#elif player_id == 1:
			#units.append(TankUnit.new(in_le, tile_map, Vector2i(player_id+5, player_id+5)))
		elif player_id == 2:
			units.append(ColonypodUnit.new(in_le, tile_map, Vector2i(player_id+5, player_id+5)))

		for u in units:
			tile_map.drawUnit(u)
		#elif player_id == 3:
			#units.append(SpaceshipUnit.new(in_le, tile_map, Vector2i(player_id+5, player_id+5)))

class TileImprovement:
	var location : Vector2i
	var tile_map : IsoTileMap
	var le : LogicEngine
	var base : Base
	var ident : Map.AtlasIdent

	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_base : Base, in_location : Vector2i, in_ident : Map.AtlasIdent):
		tile_map = in_tile_map
		location = in_location
		le = in_le
		base = in_base
		ident = in_ident

	func isWormhole() -> bool:
		return false

	func isSpacedock() -> bool:
		return false

class WormholeImprovement extends TileImprovement:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_base : Base, in_location : Vector2i):
		var ident = Map.AtlasIdent.new(8, Vector2i(1,1))
		super(in_le, in_tile_map, in_base, in_location, ident)

	func isWormhole() -> bool:
		return true

class GreenhouseImprovement extends TileImprovement:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_base : Base, in_location : Vector2i):
		var ident = Map.AtlasIdent.new(14, Vector2i(1,0))
		super(in_le, in_tile_map, in_base, in_location, ident)

class SpacedockImprovement extends TileImprovement:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_base : Base, in_location : Vector2i):
		var ident = Map.AtlasIdent.new(14, Vector2i(0,0))
		super(in_le, in_tile_map, in_base, in_location, ident)

	func isSpacedock() -> bool:
		return true

class SolarfarmImprovement extends TileImprovement:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_base : Base, in_location : Vector2i):
		var ident = Map.AtlasIdent.new(14, Vector2i(4,0))
		super(in_le, in_tile_map, in_base, in_location, ident)

class Base:
	var location : Vector2i
	var tile_map : IsoTileMap
	var le : LogicEngine
	var name : String = "Atari"
	var level : int = 1
	var population : int = 0
	var base_source_id = 5
	var base_coord : Vector2i = Vector2i(level - 1, 0)
	var tiles_inside : Array[Vector2i]
	var tiles_inside_outer : Array[Vector2i]
	var border_lines : Array[Line2D] = []
	var highlight_border_lines : Array[Line2D] = []
	var population_bar : PopulationBar2 = null
	var supported_units : Array[Unit] = []
	var improvements : Array[TileImprovement] = []

	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		tile_map = in_tile_map
		location = in_location
		le = in_le
		le.map.getTileVec(location).base = self
		
		calculateBorder(1)
		
		le.map.getTileVec(location).owned_by_base = self
		for tile in tiles_inside:
			le.map.getTileVec(tile).owned_by_base = self

	func makeTextureForButton(ident : Map.AtlasIdent) -> AtlasTexture:
		var source = tile_map.tile_set.get_source(ident.source_id) as TileSetAtlasSource
		#var origin = source.get_tile_data(ident.atlas_coord, 0).texture_origin
		var texture = source.get_texture()
		var t : AtlasTexture = AtlasTexture.new()
		t.set_atlas(texture)
		t.set_region(source.get_tile_texture_region(ident.atlas_coord))
		return t

	func setupSelectBaseDiaglog(ui : BaseSelectUI):
		var city_name : Label = ui.find_child("CityName")
		city_name.set_text(name)

		var pop_bar : ChunkedProgressBar = ui.find_child("PopulationBar")
		pop_bar.num_chunks = level+1
		pop_bar.num_chunks_filled = population

		var city_level : Label = ui.find_child("CityLevel")
		city_level.set_text("Level " + str(level))

		var cred_per_turn : Label = ui.find_child("CreditsPerTurn")
		cred_per_turn.set_text(str(creditsPerTurn()))
		
		var city_image : TextureRect = ui.find_child("CityImage")
		city_image.set_texture(makeTextureForButton(Map.AtlasIdent.new(base_source_id, base_coord)))

		var units : Array[Unit] = [
			ColonypodUnit.new(le, tile_map),
			SpacemanUnit.new(le, tile_map),
			NukeUnit.new(le, tile_map),
			HoverSaberUnit.new(le, tile_map),
			SatelliteUnit.new(le, tile_map),
			TankUnit.new(le, tile_map),
			HackerUnit.new(le, tile_map),
			MissileUnit.new(le, tile_map),
			WormholeUnit.new(le, tile_map),
			SpaceshipUnit.new(le, tile_map),
			CapitalShipUnit.new(le, tile_map)
		]

		var unit_list : ItemList = ui.find_child("UnitListItem")
		for u in units:
			var item_id = unit_list.add_item(u.getName(), makeTextureForButton(u.getSmallImage()))
			unit_list.set_item_metadata(item_id, u)

		unit_list.item_selected.connect(_unit_item_list_changed.bind(ui))
		
		var close_button : Button = ui.find_child("CloseButton")
		close_button.pressed.connect(_back_button_pressed.bind(ui))
		#var unit_label = ui.find_child("UnitLabel", true) as Label
		#unit_label.set_text(getName())
		#var cost_label = ui.find_child("CostLabel", true) as Label
		#cost_label.set_text(str(credits_cost))
		#var unit_icon = ui.find_child("UnitIcon", true) as TextureRect
		#unit_icon.set_texture(tile_map.makeTextureForButton(getSmallImage()))
		#
		#var ability_container = ui.find_child("AbilityContainer", true) as HBoxContainer
		#var spacer_node = ability_container.find_child("Spacer")
		#for c in ability_container.get_children():
			#ability_container.remove_child(c)
		#for ability in abilities.special:
			#var b : Button = Button.new()
			#b.set_text(ability.getName())
			#ability_container.add_child(b)
		#ability_container.add_child(spacer_node)
#
		#var health_value = ui.find_child("HealthValue", true) as Label
		#health_value.set_text(str(abilities.hp))
		#var attack_value = ui.find_child("AttackValue", true) as Label
		#attack_value.set_text(str(abilities.attack))
		#var defense_value = ui.find_child("DefenseValue", true) as Label
		#defense_value.set_text(str(abilities.defense))
		#var movement_value = ui.find_child("MovementValue", true) as Label
		#movement_value.set_text(str(abilities.distance))
		#var range_value = ui.find_child("RangeValue", true) as Label
		#range_value.set_text(str(abilities.range))

	func _back_button_pressed(ui : BaseSelectUI):
		ui.set_visible(false)

	func _unit_item_list_changed(index : int, ui : BaseSelectUI):
		print("changed: ", index)
		var max_health = 20
		var max_defense = 5
		var max_attack = 5
		var max_movement = 4
		var max_range = 3
		
		var unit_list : ItemList = ui.find_child("UnitListItem")
		var u : Unit = unit_list.get_item_metadata(index)
		var unit_level : TabBar = ui.find_child("UnitLevel")
		if not u.isAbleToAttack():
			unit_level.set_current_tab(0)
		unit_level.set_tab_disabled(0, not u.isAbleToAttack())
		unit_level.set_tab_disabled(1, not u.isAbleToAttack())
		unit_level.set_tab_disabled(2, not u.isAbleToAttack())
		var health_bar : ChunkedProgressBar = ui.find_child("HealthBar")
		health_bar.num_chunks = max_health
		health_bar.num_chunks_filled = u.abilities.hp
		var defense_bar : ChunkedProgressBar = ui.find_child("DefenseBar")
		defense_bar.num_chunks = max_defense
		defense_bar.num_chunks_filled = u.abilities.defense
		var attack_bar : ChunkedProgressBar = ui.find_child("AttackBar")
		attack_bar.num_chunks = max_attack
		attack_bar.num_chunks_filled = u.abilities.attack
		var movement_bar : ChunkedProgressBar = ui.find_child("MovementBar")
		movement_bar.num_chunks = max_movement
		movement_bar.num_chunks_filled = u.abilities.distance
		var range_bar : ChunkedProgressBar = ui.find_child("RangeBar")
		range_bar.num_chunks = max_range
		range_bar.num_chunks_filled = u.abilities.range

	func creditsPerTurn() -> int:
		return level + 2

	func hasSpacedock():
		for i in improvements:
			if i is SpacedockImprovement:
				return true
		return false

	func addWormhole(location : Vector2i) -> TileImprovement:
		var i = WormholeImprovement.new(le, tile_map, self, location)
		improvements.append(i)
		increasePopulation()
		return i

	func addGreenhouse(location : Vector2i) -> TileImprovement:
		var i = GreenhouseImprovement.new(le, tile_map, self, location)
		improvements.append(i)
		increasePopulation()
		return i

	func addSpacedock(location : Vector2i) -> TileImprovement:
		var i = SpacedockImprovement.new(le, tile_map, self, location)
		improvements.append(i)
		increasePopulation()
		return i

	func addSolarfarm(location : Vector2i) -> TileImprovement:
		var i = SolarfarmImprovement.new(le, tile_map, self, location)
		improvements.append(i)
		increasePopulation()
		return i

	func addSupportedUnit(unit : Unit):
		supported_units.append(unit)
		population_bar.unitAdded()

	func removeSupportedUnit(unit : Unit):
		supported_units.erase(unit)
		population_bar.unitRemoved()

	func canSupportMoreUnits():
		return supported_units.size() < level + 1

	func getNumberOfSupportedUnits() -> int:
		print("getNumberOfSupportedUnits:", supported_units.size())
		return supported_units.size()

	func increasePopulation():
		print("increasePopulation")
		population += 1
		population_bar.setPopulation(population)

		if population == level+1:
			level += 1
			population_bar.setLevel(level)
			population = 0
			population_bar.setPopulation(population)
			base_coord = Vector2i(level-1, 0)
			tile_map.updateCity(self)

		tile_map.drawCity(self)
		le.updatePlusEnergy()

	func calculateBorder(distance : int = 1):
		tiles_inside = calculateBorderImpl([location], 1, distance)
		tiles_inside.append(location)
		tiles_inside_outer.append(location)

	func calculateBorderImpl(positions_at_dist : Array[Vector2i], cur_dist : int, total_dist : int) -> Array[Vector2i]:
		var border_tiles : Array[Vector2i] = []
		
		for position in positions_at_dist:
			for d in le.getBasicDirections():
				var loc_to_check : Vector2i = position + d
				var tile : Map.Tile = le.map.getTileVec(loc_to_check)
				if not tile.isOownedByBase():
					var new_pos = position+d
					border_tiles.append(new_pos)
					#if (new_pos.x == location.x + total_dist or
						#new_pos.y == location.y + total_dist or
						#new_pos.x == location.x - total_dist or
						#new_pos.y == location.y - total_dist):
					tiles_inside_outer.append(new_pos)

		if cur_dist < total_dist:
			return calculateBorderImpl(border_tiles, cur_dist+1, total_dist)
		else:
			return border_tiles

class BaseAbility:
	func getName() -> String:
		return "None"

	func getDescription() -> String:
		return "Write something longer here"

class DashAbility extends BaseAbility:
	func getName() -> String:
		return "Dash"

	func getDescription() -> String:
		return "After moving this unit, you may attack."
		
class BounceAbility extends BaseAbility:
	func getName() -> String:
		return "Bounce"

	func getDescription() -> String:
		return "After moving this unit, you may attack and then you can move it again."

class UnitAbilities:
	var distance : int = 1
	var attack : int = 1
	var hp : int = 10
	var max_hp : int = 10
	var defense : int = 1
	var range : int = 1

	var special : Array[BaseAbility] = []

	func hasDash() -> bool:
		for ability in special:
			if ability is DashAbility:
				return true
		return false

	func hasBounce() -> bool:
		for ability in special:
			if ability is BounceAbility:
				return true
		return false

class Unit:
	var location : Vector2i
	var turn_completed : bool = false
	var selected : bool = false
	var abilities : UnitAbilities = UnitAbilities.new()
	var tile_map : IsoTileMap
	var unit_source_id : int
	var le : LogicEngine
	var unit_coord : Vector2i
	var credits_cost : int = 2
	var base_supporting : Base = null
	var unit_health_label : Label = null
	var moved_counter = 0
	var attack_counter = 0

	func canMove() -> bool:
		if abilities.hasBounce():
			return (moved_counter == 0 and attack_counter == 0) or (moved_counter == 1 and attack_counter == 1)
		else:
			return moved_counter == 0 and attack_counter == 0
	
	func canAttack() -> bool:
		print("canAttack: attack=", attack_counter, " moved=", moved_counter)
		if abilities.hasDash():
			return attack_counter == 0
		else:
			return attack_counter == 0 and moved_counter == 0

	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i, in_unit_source_id : int, in_unit_coord : Vector2i):
		tile_map = in_tile_map
		location = in_location
		unit_source_id = in_unit_source_id
		unit_coord = in_unit_coord
		le = in_le
		if location.x != -1 and location.y != -1:
			le.map.getTileVec(location).unit = self

	func setSupportingBase(b : Base):
		base_supporting = b

	func getName():
		return "Unknown"

	func setupSelectDiaglog(ui : UnitSelectUI):
		var unit_label = ui.find_child("UnitLabel", true) as Label
		unit_label.set_text(getName())
		var cost_label = ui.find_child("CostLabel", true) as Label
		cost_label.set_text(str(credits_cost))
		var unit_icon = ui.find_child("UnitIcon", true) as TextureRect
		unit_icon.set_texture(tile_map.makeTextureForButton(getSmallImage()))
		
		var ability_container = ui.find_child("AbilityContainer", true) as HBoxContainer
		var spacer_node = ability_container.find_child("Spacer")
		for c in ability_container.get_children():
			ability_container.remove_child(c)
		for ability in abilities.special:
			var b : Button = Button.new()
			b.set_text(ability.getName())
			ability_container.add_child(b)
		ability_container.add_child(spacer_node)

		var health_value = ui.find_child("HealthValue", true) as Label
		health_value.set_text(str(abilities.hp))
		var attack_value = ui.find_child("AttackValue", true) as Label
		attack_value.set_text(str(abilities.attack))
		var defense_value = ui.find_child("DefenseValue", true) as Label
		defense_value.set_text(str(abilities.defense))
		var movement_value = ui.find_child("MovementValue", true) as Label
		movement_value.set_text(str(abilities.distance))
		var range_value = ui.find_child("RangeValue", true) as Label
		range_value.set_text(str(abilities.range))

	func setLocation(new_location : Vector2i):
		le.map.getTileVec(new_location).unit = self
		location = new_location

	func changeLocation(new_location : Vector2i):
		moved_counter += 1
		le.map.getTileVec(location).unit = null
		le.map.getTileVec(new_location).unit = self
		location = new_location

	func hasBuilder() -> bool:
		return false

	func getValidMoves() -> Array[Vector2i]:
		return getValidMovesImpl([location])

	func getValidMovesImpl(positions_at_dist : Array[Vector2i], dist : int = 1) -> Array[Vector2i]:
		var valid_moves : Array[Vector2i] = []

		for position in positions_at_dist:
			for d in le.getBasicDirections():
				var loc_to_check : Vector2i = position + d
				var tile : Map.Tile = le.map.getTileVec(loc_to_check)
				if not tile.hasUnit() and loc_to_check != location:
					if tile.type in getValidTypes():
						valid_moves.append(loc_to_check)

		if dist == abilities.distance:
			return valid_moves
		else:
			return getValidMovesImpl(valid_moves, dist+1)

	func getUnitsWithinRange() -> Array[Unit]:
		return getUnitsWithinRangeImpl([location])
		
	func getUnitsWithinRangeImpl(positions_at_dist : Array[Vector2i], dist : int = 1, cur_units : Array[Unit] = []) -> Array[Unit]:
		var valid_moves : Array[Vector2i] = []
		var units : Array[Unit] = cur_units
		for position in positions_at_dist:
			for d in le.getBasicDirections():
				var loc_to_check : Vector2i = position + d
				var tile : Map.Tile = le.map.getTileVec(loc_to_check)
				if tile.hasUnit() and loc_to_check != location:
					units.append(tile.unit)
				valid_moves.append(loc_to_check)

		if dist == abilities.range:
			return units
		else:
			return getUnitsWithinRangeImpl(valid_moves, dist+1, units)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return []

	func getSmallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(-1, Vector2i(-1,-1))

	func isAbleToAttack() -> bool:
		return true

	func setHP(hp : int):
		abilities.hp = hp
		abilities.max_hp = hp

	func attack(tile : Vector2i):
		var defending_unit = le.map.getTileVec(tile).unit
		assert(defending_unit != null)

func unitAttack(attacking : Unit, defending : Unit):
	attacking.attack_counter += 1
	assert(attacking != null)
	assert(defending != null)
	var attackForce : float = attacking.abilities.attack * (float(attacking.abilities.hp) / attacking.abilities.max_hp)
	var defenseForce : float = defending.abilities.defense * (float(defending.abilities.hp) / defending.abilities.max_hp)
	var totalDamage : float = attackForce + defenseForce
	var attackResult : int = round(attackForce / totalDamage * attacking.abilities.attack * 4.5 + 0.49)
	var defenseResult : int = round(attackForce / totalDamage * defending.abilities.defense * 4.5 + 0.49)
	print("attackForce=", attackForce, ", defenseForce=", defenseForce, ", totalDamage=", totalDamage, ", attackResult=", attackResult, ", defenseResult=", defenseResult)
	defending.abilities.hp -= attackResult
	tile_map.drawUnit(defending)
	if defending.abilities.hp <= 0:
		removeUnit(defending)
	else:
		var defending_unit_range = defending.getUnitsWithinRange()
		if attacking in defending_unit_range:
			attacking.abilities.hp -= defenseResult
			tile_map.drawUnit(attacking)
			if attacking.abilities.hp <= 0:
				removeUnit(attacking)
		else:
			tile_map.drawUnit(attacking)

class SpacemanUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(2, 0)
		setHP(10)
		abilities.attack = 2
		abilities.defense = 2
		abilities.special.append(DashAbility.new())
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "Spaceman"

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(2,0))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

class TankUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(0, 0)
		setHP(15)
		abilities.range = 3
		abilities.attack = 3
		credits_cost = 8
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)
	
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "Tank"

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(0,0))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

class ColonypodUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(4, 0)
		setHP(5)
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func hasBuilder() -> bool:
		return true
		
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "Colonypod"
		
	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(4,0))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

	func isAbleToAttack() -> bool:
		return false

class SpaceshipUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(5, 0)
		setHP(20)
		abilities.distance = 2
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)
		
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND, Map.TileTypeEnum.MOUNTAIN, Map.TileTypeEnum.ATMOSPHERE]

	func getName():
		return "Spaceship"

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(5,0))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

class SatelliteUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(7, 0)
		setHP(5)
		abilities.distance = 2
		abilities.range = 2
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND, Map.TileTypeEnum.MOUNTAIN, Map.TileTypeEnum.ATMOSPHERE, Map.TileTypeEnum.SPACE]

	func getName():
		return "Satellite"

	func isAbleToAttack() -> bool:
		return false

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(7,0))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

	func getUnitsWithinRange() -> Array[Unit]:
		return []

class WormholeUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(3, 1)
		setHP(10)
		abilities.distance = 2
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.ATMOSPHERE, Map.TileTypeEnum.SPACE]

	func getName():
		return "Wormhole"

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(3,1))

	func isAbleToAttack() -> bool:
		return false

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

class NukeUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(6, 2)
		setHP(5)
		abilities.distance = 2
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND, Map.TileTypeEnum.MOUNTAIN, Map.TileTypeEnum.ATMOSPHERE, Map.TileTypeEnum.SPACE]

	func getName():
		return "Nuke"

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(6,2))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

class HoverSaberUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(3, 2)
		setHP(5)
		abilities.distance = 2
		abilities.special.append(BounceAbility.new())
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "HoverSaber"

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(3,2))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

class CapitalShipUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(6, 1)
		setHP(20)
		abilities.distance = 2
		abilities.range = 3
		abilities.attack = 3
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.ATMOSPHERE, Map.TileTypeEnum.SPACE]

	func getName():
		return "CapitalShip"

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(6,1))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

class MissileUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(7, 1)
		setHP(10)
		abilities.distance = 1
		abilities.range = 3
		abilities.attack = 1
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "Missile"

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(7,1))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

class HackerUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i = Vector2i(-1,-1)):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(1, 2)
		setHP(10)
		abilities.distance = 1
		abilities.range = 1
		abilities.attack = 1
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "Hacker"

	func isAbleToAttack() -> bool:
		return true

	static func smallImage() -> Map.AtlasIdent:
		return Map.AtlasIdent.new(13, Vector2i(1,2))

	func getSmallImage() -> Map.AtlasIdent:
		return smallImage()

var is_initialized : bool = false

func removeUnit(u : Unit):
	for p in players:
		for i in range(len(p.units)):
			if p.units[i] == u:
				map.getTileVec(u.location).unit = null
				if u.base_supporting:
					u.base_supporting.removeSupportedUnit(u)
				p.units.remove_at(i)
				tile_map.undrawUnit(u, u.location, false)
				break

func buildCity(unit_location : Vector2i):
	for p in players:
		for i in range(len(p.units)):
			print("i=", i, " unit location:", p.units[i].location, " passed loc: ", unit_location)
			if p.units[i].location == unit_location:
				removeUnit(p.units[i])
				var base = Base.new(self, tile_map, unit_location)
				p.bases.append(base)
				tile_map.drawCity(base)
				break
	updatePlusEnergy()

func moveUnit(unit : Unit, unit_location : Vector2i, new_location : Vector2i):
	unit.changeLocation(new_location)
	tile_map.drawUnit(unit)

func initialize(num_players : int):
	for i in num_players:
		players.append(Player.new(self, tile_map, i))

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Logic Engine is ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print("process engine: ", tile_map)
	if tile_map != null and not is_initialized:
		is_initialized = true
		initialize(4)

func _on_turn_complete_button_pressed():
	for p in players:
		for u in p.units:
			u.moved_counter = 0
			u.attack_counter = 0
			tile_map.drawUnit(u)
	var total_credits_label = get_parent().find_child("EnergyCreditsField") as Label
	var total_credit_turn : int = 0
	for p in players:
		for b in p.bases:
			total_credit_turn += b.creditsPerTurn()
	total_credits_label.set_text(str(int(total_credits_label.get_text()) + total_credit_turn))

func updatePlusEnergy():
	var plus_credits_label = get_parent().find_child("EnergyPlus") as Label
	var total_credit_turn : int = 0
	for p in players:
		for b in p.bases:
			total_credit_turn += b.creditsPerTurn()
	plus_credits_label.set_text("+" + str(int(total_credit_turn)))
