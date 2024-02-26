class_name LogicEngine extends Node

@onready var tile_map : IsoTileMap = get_parent().get_node("Tiles")

var turn_counter : int = 0
var players : Array[Player]
var all_units : Array[Unit]

const unit_tile_set : int = 8

class Player:
	var player_id : int = -1
	var last_turn_completed : int = -1
	var units : Array[Unit]
	var tile_map : IsoTileMap
	var le : LogicEngine
	
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_player_id : int):
		tile_map = in_tile_map
		player_id = in_player_id
		le = in_le
		
		# Dummy insertion of a unit

		units.append(Unit.new(in_le, tile_map, Vector2i(player_id, player_id), unit_tile_set, player_id))

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
	var unit_type : int = 0
	
	func _init(in_le : LogicEngine, in_tile_map : IsoTileMap, in_location : Vector2i, in_unit_source_id : int, in_unit_type : int):
		tile_map = in_tile_map
		location = in_location
		unit_source_id = in_unit_source_id
		unit_type = in_unit_type
		
		if unit_type == 3:
			abilities.hp = 20

		if unit_type == 2:
			abilities.hp = 5

		le = in_le
		le.all_units.append(self)
		renderAtLocation()
		
	func changeLocation():
		tile_map.unit_tile_set_layer[tile_map.convertTo1D(location)] = -1
		tile_map.unit_layer_health[tile_map.convertTo1D(location)] = -1
		
	func renderAtLocation():
		print("renderAtLocation location=", location)
		if unit_type == 0:
			tile_map.unit_layer[tile_map.convertTo1D(location)] = Vector2i(0, 0)
		elif unit_type == 1:
			tile_map.unit_layer[tile_map.convertTo1D(location)] = Vector2i(2, 0)
		elif unit_type == 2:
			tile_map.unit_layer[tile_map.convertTo1D(location)] = Vector2i(4, 0)
		else:
			tile_map.unit_layer[tile_map.convertTo1D(location)] = Vector2i(5, 0)
		tile_map.unit_tile_set_layer[tile_map.convertTo1D(location)] = unit_source_id
		tile_map.unit_layer_health[tile_map.convertTo1D(location)] = abilities.hp

var is_initialized : bool = false

func move_unit(unit_location : Vector2i, new_location : Vector2i):
	for u in all_units:
		if u.location == unit_location:
			u.changeLocation()
			u.location = new_location
			u.renderAtLocation()

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
