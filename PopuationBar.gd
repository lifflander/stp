class_name PopulationBar2 extends ProgressBar

var divisions : int = 3
var divisions_filled : int = 0
var base : LogicEngine.Base

func _init(in_base : LogicEngine.Base):
	base = in_base
	divisions = base.level + 1
	rounded = true
	show_percentage = false

func setPopulation(population : int):
	print("setPopulation: ", population / float(divisions) * 100)
	divisions_filled = population
	drawLines()

func unitAdded():
	drawLines()

func unitRemoved():
	drawLines()

func setLevel(level : int):
	divisions = level + 1

func drawLines():
	for child in get_children():
		remove_child(child)

	var num_supported_units : int = base.getNumberOfSupportedUnits()

	for i in divisions:
		var len = size.x;
		var wid = size.y;
		var div_start_x = len/divisions*i
		var div_stop_x = len/divisions*(i+1)
		var rect : Polygon2D = Polygon2D.new()
		var pack_array : PackedVector2Array = PackedVector2Array([Vector2(div_start_x, 0), Vector2(div_stop_x, 0), Vector2(div_stop_x, wid), Vector2(div_start_x, wid)])
		rect.set_polygon(pack_array)
		if i < divisions_filled:
			rect.set_color(Color(0,0,1,1))
		else:
			rect.set_color(Color(0.5,0.5,0.5,1))

		add_child(rect)

		if num_supported_units > i:
			var circle : Circle2D = Circle2D.new()
			circle.color = Color(0.7, 0.7, 0.7, 1)
			circle.set_position(Vector2(div_start_x + (div_stop_x - div_start_x)/2.0,wid/2))
			circle.radius = 10
			add_child(circle)

	for i in divisions:
		if i == 0:
			continue
		var val = 100/divisions
		var len = size.x;
		var wid = size.y;
		var line : Line2D = Line2D.new()
		line.set_default_color(Color(1,1,1,1))
		print("drawing line for:", i)
		line.add_point(Vector2(len/divisions*i, 0))
		line.add_point(Vector2(len/divisions*i, wid))
		line.set_width(5)
		add_child(line)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
