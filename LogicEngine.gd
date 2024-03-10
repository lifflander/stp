class_name LogicEngine extends Node

@onready var tile_map : IsoTileMap = get_parent().get_node("Tiles")

var turn_counter : int = 0
var players : Array[Player]

const unit_tile_set : int = 8

class AtlasIdent:
	var source_id : int
	var atlas_coord : Array[Vector2i]
	
	func _init(in_source_id : int, in_altas_coord : Array[Vector2i]):
		source_id = in_source_id
		atlas_coord = in_altas_coord
	
	func hasCoord(coord : Vector2i) -> bool:
		for c in atlas_coord:
			if c == coord:
				return true
		return false

var land = [
		AtlasIdent.new(6, [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]),
		AtlasIdent.new(7, [Vector2i(4,0), Vector2i(5,0), Vector2i(6,0)])
	]
	
func isLand(source_id : int, atlas_coord : Vector2i) -> bool:
	for x in land:
		if x.source_id == source_id && x.hasCoord(atlas_coord):
			return true
	return false

class Tile:
	var unit : Unit = null
	var base : Base = null
	
	func hasUnit() -> bool:
		return unit != null
	
	func hasBase() -> bool:
		return base != null

class Map:
	var width : int = 20
	var height : int = 20
	
	var tiles : Array[Tile]
	
	func convertTo1D(vec : Vector2i) -> int:
		return vec.x * width + vec.y
	
	func getTileXY(x : int, y : int) -> Tile:
		return tiles[convertTo1D(Vector2i(x, y))]
		
	func getTileVec(vec : Vector2i) -> Tile:
		return tiles[convertTo1D(vec)]
		
	func _init(in_tile_map : IsoTileMap):
		var base_layer_id : int = -1
		var resource_layer_id : int = -1
		
		for i in in_tile_map.get_layers_count():
			if in_tile_map.get_layer_name(i) == "Base layer":
				base_layer_id = i
			if in_tile_map.get_layer_name(i) == "Resources":
				resource_layer_id = i
	
		for x in width:
			for y in height:
				var coord : Vector2i = Vector2i(x,y)
				#var td : TileData = in_tile_map.get_cell_tile_data(base_layer_id, coord)
				var atlas_coord = in_tile_map.get_cell_atlas_coords(base_layer_id, coord)
				var source_id = in_tile_map.get_cell_source_id(base_layer_id, coord)
				var atlas_source = in_tile_map.tile_set.get_source(source_id) as TileSetAtlasSource



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

	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i):
		tile_map = in_tile_map
		location = in_location
		le = in_le
		
		renderAtLocation()
		
	func renderAtLocation():
		tile_map.base_layer[tile_map.convertTo1D(location)] = Vector2i(level - 1, 0)

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
		renderAtLocation()
		
	func changeLocation():
		tile_map.unit_tile_set_layer[tile_map.convertTo1D(location)] = -1
		tile_map.unit_layer_health[tile_map.convertTo1D(location)] = -1
		tile_map.unit_layer_build[tile_map.convertTo1D(location)] = -1
		
	func renderAtLocation():
		print("renderAtLocation location=", location)
		tile_map.unit_layer[tile_map.convertTo1D(location)] = unit_coord
		tile_map.unit_tile_set_layer[tile_map.convertTo1D(location)] = unit_source_id
		tile_map.unit_layer_health[tile_map.convertTo1D(location)] = abilities.hp
		renderBuilders()

	func renderBuilders():
		pass

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

	func renderBuilders():
		tile_map.unit_layer_build[tile_map.convertTo1D(location)] = 1

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
				p.units[i].changeLocation()
				p.units.remove_at(i)
				p.bases.append(Base.new(self, tile_map, unit_location))
				break

func move_unit(unit_location : Vector2i, new_location : Vector2i):
	for p in players:
		for i in range(len(p.units)):
			if p.units[i].location == unit_location:
				p.units[i].changeLocation()
				p.units[i].location = new_location
				p.units[i].renderAtLocation()

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
