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
	
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_player_id : int):
		tile_map = in_tile_map
		player_id = in_player_id
		le = in_le

		# Dummy insertion of a unit
		if player_id == 0:
			units.append(SpacemanUnit.new(in_le, tile_map, Vector2i(player_id+5, player_id+5)))
			units.append(SatelliteUnit.new(in_le, tile_map, Vector2i(player_id+1, player_id+1)))
		elif player_id == 1:
			units.append(TankUnit.new(in_le, tile_map, Vector2i(player_id+5, player_id+5)))
		elif player_id == 2:
			units.append(ColonypodUnit.new(in_le, tile_map, Vector2i(player_id+5, player_id+5)))
		elif player_id == 3:
			units.append(SpaceshipUnit.new(in_le, tile_map, Vector2i(player_id+5, player_id+5)))

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

	func addWormhole(location : Vector2i) -> TileImprovement:
		var i = TileImprovement.new(le, tile_map, self, location, Map.AtlasIdent.new(8, Vector2i(0,1)))
		improvements.append(i)
		return i
		
	func addGreenhouse(location : Vector2i) -> TileImprovement:
		var i = TileImprovement.new(le, tile_map, self, location, Map.AtlasIdent.new(11, Vector2i(0,0)))
		improvements.append(i)
		return i

	func addSupportedUnit(unit : Unit):
		supported_units.append(unit)
		population_bar.unitAdded()

	func canSupportMoreUnits():
		return supported_units.size() < level + 1
		
	func getNumberOfSupportedUnits() -> int:
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

class UnitAbilities:
	var distance : int = 1
	var attack : int = 1
	var hp : int = 10
	var defense : int = 1

class Unit:
	var location : Vector2i
	var turn_completed : bool = false
	var selected : bool = false
	var abilities : UnitAbilities = UnitAbilities.new()
	var tile_map : IsoTileMap
	var unit_source_id : int
	var le : LogicEngine
	var unit_coord : Vector2i
	
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i, in_unit_source_id : int, in_unit_coord : Vector2i):
		tile_map = in_tile_map
		location = in_location
		unit_source_id = in_unit_source_id
		unit_coord = in_unit_coord
		le = in_le
		le.map.getTileVec(location).unit = self
		
	func getName():
		return "Unknown"

	func changeLocation(new_location : Vector2i):
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
				if not tile.hasUnit():
					if tile.type in getValidTypes():
						valid_moves.append(loc_to_check)

		if dist == abilities.distance:
			return valid_moves
		else:
			return getValidMovesImpl(valid_moves, dist+1)
		
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return []

class SpacemanUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(2, 0)
		abilities.hp = 10
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "Spaceman"

class TankUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(0, 0)
		abilities.hp = 15
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)
	
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "Tank"

class ColonypodUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(4, 0)
		abilities.hp = 5
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func hasBuilder() -> bool:
		return true
		
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

	func getName():
		return "Colonypod"

class SpaceshipUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(5, 0)
		abilities.hp = 20
		abilities.distance = 2
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)
		
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND, Map.TileTypeEnum.MOUNTAIN, Map.TileTypeEnum.ATMOSPHERE]

	func getName():
		return "Spaceship"
		
class SatelliteUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(7, 0)
		abilities.hp = 5
		abilities.distance = 2
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)
		
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND, Map.TileTypeEnum.MOUNTAIN, Map.TileTypeEnum.ATMOSPHERE, Map.TileTypeEnum.SPACE]

	func getName():
		return "Satellite"
		
class WormholeUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(2, 1)
		abilities.hp = 10
		abilities.distance = 2
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)
		
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND, Map.TileTypeEnum.MOUNTAIN, Map.TileTypeEnum.ATMOSPHERE, Map.TileTypeEnum.SPACE]

	func getName():
		return "Wormhole"

var is_initialized : bool = false

func buildCity(unit_location : Vector2i):
	for p in players:
		for i in range(len(p.units)):
			print("i=", i, " unit location:", p.units[i].location, " passed loc: ", unit_location)
			if p.units[i].location == unit_location:
				map.getTileVec(unit_location).unit = null
				p.units.remove_at(i)
				var base = Base.new(self, tile_map, unit_location)
				p.bases.append(base)
				tile_map.drawCity(base)
				break

func moveUnit(unit : Unit, unit_location : Vector2i, new_location : Vector2i):
	unit.changeLocation(new_location)

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
