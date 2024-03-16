class_name PopulationBar2 extends ProgressBar

var divisions : int = 3
var divisions_filled : int = 0

func _init(base : LogicEngine.Base):
	divisions = base.level + 1
	rounded = true
	show_percentage = false
	#set_value(base.population / divisions * 100)
	drawLines()

func setPopulation(population : int):
	print("setPopulation: ", population / float(divisions) * 100)
	set_value(population / float(divisions) * 100)
	divisions_filled = population
	drawLines()

func setLevel(level : int):
	divisions = level + 1

func drawLines():
	for child in get_children():
		remove_child(child)

	for i in divisions_filled:
		var len = size.x;
		var wid = size.y;
		var div_start_x = len/divisions*i
		var div_stop_x = len/divisions*(i+1)
		var rect : Polygon2D = Polygon2D.new()
		var pack_array : PackedVector2Array = PackedVector2Array([Vector2(div_start_x, 0), Vector2(div_stop_x, 0), Vector2(div_stop_x, wid), Vector2(div_start_x, wid)])
		rect.set_polygon(pack_array)
		rect.set_color(Color(0,0,1,1))
		add_child(rect)

	for i in divisions:
		if i == 0:
			continue
		var val = 100/divisions
		var len = size.x;
		var wid = size.y;
		var line : Line2D = Line2D.new()
		line.set_default_color(Color(1,1,1,1))
		line.add_point(Vector2(len/divisions*i, 0))
		line.add_point(Vector2(len/divisions*i, wid))
		add_child(line)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
