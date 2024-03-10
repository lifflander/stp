class_name LogicEngine extends Node

@onready var tile_map : IsoTileMap = get_parent().get_node("Tiles")
@onready var map : Map = get_parent().get_node("Map")

var turn_counter : int = 0
var players : Array[Player]

const unit_tile_set : int = 8

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
			units.append(SpacemanUnit.new(in_le, tile_map, Vector2i(player_id+2, player_id+2)))
		elif player_id == 1:
			units.append(TankUnit.new(in_le, tile_map, Vector2i(player_id+2, player_id+2)))
		elif player_id == 2:
			units.append(ColonypodUnit.new(in_le, tile_map, Vector2i(player_id+2, player_id+2)))
		elif player_id == 3:
			units.append(SpaceshipUnit.new(in_le, tile_map, Vector2i(player_id+2, player_id+2)))

class Base:
	var location : Vector2i
	var tile_map : IsoTileMap
	var le : LogicEngine
	var name : String = "Atari"
	var level : int = 1
	var base_source_id = 12
	var base_coord : Vector2i = Vector2i(level - 1, 0)

	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		tile_map = in_tile_map
		location = in_location
		le = in_le
		le.map.getTileVec(location).base = self

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
		
	func changeLocation(new_location : Vector2i):
		le.map.getTileVec(location).unit = null
		le.map.getTileVec(new_location).unit = self
		location = new_location

	func hasBuilder() -> bool:
		return false

	var basic_directions : Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1),
		Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, 1)
		]

	func getValidMoves() -> Array[Vector2i]:
		return getValidMovesImpl([location])

	func getValidMovesImpl(positions_at_dist : Array[Vector2i], dist : int = 1) -> Array[Vector2i]:
		var valid_moves : Array[Vector2i] = []
		
		for position in positions_at_dist:
			for d in basic_directions:
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

class TankUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(0, 0)
		abilities.hp = 15
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)
	
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND]

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

class SpaceshipUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(5, 0)
		abilities.hp = 20
		abilities.distance = 2
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)
		
	func getValidTypes() -> Array[Map.TileTypeEnum]:
		return [Map.TileTypeEnum.LAND, Map.TileTypeEnum.MOUNTAIN]

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
