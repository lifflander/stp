class_name LogicEngine extends Node

@onready var tile_map : IsoTileMap = get_parent().get_node("Tiles")

var turn_counter : int = 0
var players : Array[Player]

const unit_tile_set : int = 8

class Player:
	var player_id : int = -1
	var last_turn_completed : int = -1
	var units : Array[Unit]
	var tile_map : IsoTileMap
	
	func _init(in_tile_map : IsoTileMap, in_player_id : int):
		tile_map = in_tile_map
		player_id = in_player_id
		
		# Dummy insertion of a unit
		if player_id == 0:
			units.append(Unit.new(tile_map, Vector2i(player_id, player_id), unit_tile_set))
		else:
			units.append(Unit.new(tile_map, Vector2i(player_id, player_id), unit_tile_set))

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
	
	func _init(in_tile_map : IsoTileMap, in_location : Vector2i, in_unit_source_id : int):
		tile_map = in_tile_map
		location = in_location
		unit_source_id = in_unit_source_id
		renderAtLocation()
		
	func renderAtLocation():
		print("renderAtLocation location=", location)
		if location.x == 0:
			tile_map.unit_layer[tile_map.convertTo1D(location)] = Vector2i(0, 0)
		else:
			tile_map.unit_layer[tile_map.convertTo1D(location)] = Vector2i(2, 0)
		tile_map.unit_tile_set_layer[tile_map.convertTo1D(location)] = unit_source_id

var is_initialized : bool = false

func initialize(num_players : int):
	for i in num_players:
		players.append(Player.new(tile_map, i))

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Logic Engine is ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print("process engine: ", tile_map)
	if tile_map != null and not is_initialized:
		is_initialized = true
		initialize(2)
