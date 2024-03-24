extends CharacterBody2D

var dragging = false
var prev_position : Vector2
var clicked_button : bool = false

#var multiplayer_peer = ENetMultiplayerPeer.new()

@onready var tile_map : IsoTileMap = get_parent().get_node("Tiles")

func _ready():
	set_process_input(true)

	get_tree().get_root().size_changed.connect(resize)
	resize()
#
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	#multiplayer_peer.create_client("127.0.0.1", 9010)
	#multiplayer.multiplayer_peer = multiplayer_peer
	#print(multiplayer_peer.get_connection_status(), multiplayer_peer.CONNECTION_CONNECTING)
	#while multiplayer_peer.get_connection_status() !=  multiplayer_peer.CONNECTION_CONNECTED:
		#print(multiplayer_peer.get_connection_status(), multiplayer_peer.CONNECTION_CONNECTING)
		#pass

#func _on_server_disconnected():
	#multiplayer_peer.close()
	#print("connection lost")

func resize():
	var size = get_tree().get_root().get_viewport().size
	var cr = get_parent().find_child("ColorRect") as ColorRect
	var dcr = get_parent().find_child("DynamicColorRect") as ColorRect
	var tui = get_parent().find_child("TopUI") as ColorRect
	var cc = get_parent().find_child("CenterContainer") as CenterContainer
	cr.set_size(Vector2i(size.x, cr.size.y))
	dcr.set_size(Vector2i(size.x, dcr.size.y))
	tui.set_size(Vector2i(size.x, tui.size.y))
	cc.set_size(Vector2i(size.x, cc.size.y))

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
			prev_position = get_local_mouse_position() + position
		else:
			if clicked_button:
				clicked_button = false
			else:
				dragging = false
				prev_position = Vector2(0,0)

				#var global_pos = get_global_mouse_position()
				#var local_pos = tile_map.to_local(global_pos)
				#var map_pos = tile_map.local_to_map(local_pos)
				#print("global:, ", global_pos, ", local: ", local_pos, ", map: ", map_pos)
				#tile_map.selectCell(map_pos)

	elif event is InputEventMouseMotion and dragging:
		var new_position = get_local_mouse_position()
		position = prev_position - new_position

func _physics_process(delta):
	pass
