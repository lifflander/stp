class_name ChunkedProgressBar extends ProgressBar

@export var num_chunks = 3
@export var num_chunks_filled = 1:
	get: return num_chunks_filled
	set(value):
		num_chunks_filled = value
		drawChunks()
@export var unfilled_color = Color(0.5,0.5,0.5,1)
@export var filled_color = Color(0,0,1,1)
@export var buffer_x = 5
@export var buffer_y = 5

func _init():
	set_show_percentage(false)
	drawChunks()

func drawChunks():
	for child in get_children():
		remove_child(child)

	for i in num_chunks:
		var len = get_size().x;
		var wid = get_size().y;
		var div_start_x = len/num_chunks*i + buffer_x
		var div_stop_x = len/num_chunks*(i+1) - buffer_x
		var rect : Polygon2D = Polygon2D.new()
		var pack_array : PackedVector2Array = PackedVector2Array([Vector2(div_start_x, buffer_y), Vector2(div_stop_x, buffer_y), Vector2(div_stop_x, wid - buffer_y), Vector2(div_start_x, wid - buffer_y)])
		rect.set_polygon(pack_array)
		if i < num_chunks_filled:
			rect.set_color(filled_color)
		else:
			rect.set_color(unfilled_color)

		add_child(rect)

# Called when the node enters the scene tree for the first time.
func _ready():
	drawChunks()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	drawChunks()
