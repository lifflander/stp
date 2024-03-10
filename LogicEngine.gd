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
			units.append(SpacemanUnit.new(in_le, tile_map, Vector2i(player_id, player_id)))
		elif player_id == 1:
			units.append(TankUnit.new(in_le, tile_map, Vector2i(player_id, player_id)))
		elif player_id == 2:
			units.append(ColonypodUnit.new(in_le, tile_map, Vector2i(player_id, player_id)))
		elif player_id == 3:
			units.append(SpaceshipUnit.new(in_le, tile_map, Vector2i(player_id, player_id)))

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

class SpacemanUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(2, 0)
		abilities.hp = 10
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)


class TankUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(0, 0)
		abilities.hp = 15
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

class ColonypodUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(4, 0)
		abilities.hp = 5
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

	func hasBuilder() -> bool:
		return true

class SpaceshipUnit extends Unit:
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		var unit_source_id : int = unit_tile_set
		var unit_coords : Vector2i = Vector2i(5, 0)
		abilities.hp = 20
		super(in_le, in_tile_map, in_location, unit_source_id, unit_coords)

var is_initialized : bool = false

func get_base(location : Vector2i) -> Base:
	for p in players:
		for i in range(len(p.bases)):
			if p.bases[i].location == location:
				return p.bases[i]
	return null

func build_city(unit_location : Vector2i):
	for p in players:
		for i in range(len(p.units)):
			print("i=", i, " unit location:", p.units[i].location, " passed loc: ", unit_location)
			if p.units[i].location == unit_location:
				map.getTileVec(unit_location).unit = null
				p.units.remove_at(i)
				p.bases.append(Base.new(self, tile_map, unit_location))
				break

func move_unit(unit_location : Vector2i, new_location : Vector2i):
	for p in players:
		for i in range(len(p.units)):
			if p.units[i].location == unit_location:
				p.units[i].changeLocation(new_location)

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
