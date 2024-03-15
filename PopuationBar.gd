class_name PopulationBar2 extends ProgressBar

var divisions : int = 3

func _init(in_divisions : int):
	divisions = in_divisions
	rounded = true


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in divisions:
		if i == 0:
			continue
		var val = 100/divisions
		var len = size.x;
		var wid = size.y;
		var line : Line2D = Line2D.new()
		line.add_point(Vector2(len/divisions*i, 0))
		line.add_point(Vector2(len/divisions*i,  wid))
		add_child(line)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
