class_name Map extends Node

class AtlasIdent:
	var source_id : int
	var atlas_coord : Vector2i
	
	func _init(in_source_id : int, in_altas_coord : Vector2i):
		source_id = in_source_id
		atlas_coord = in_altas_coord
	
	func hasCoord(coord : Vector2i) -> bool:
		if atlas_coord == coord:
			return true
		return false

enum TileTypeEnum {
	EMPTY = -1, LAND = 0, MOUNTAIN = 1, SPACE = 2, ATMOSPHERE = 3
}

class Tile:
	var atlas : AtlasIdent
	var atlas_space : AtlasIdent
	var unit : LogicEngine.Unit = null
	var base : LogicEngine.Base = null
	var type : TileTypeEnum = TileTypeEnum.EMPTY
	var owned_by_base : LogicEngine.Base = null
	var resource : AtlasIdent = AtlasIdent.new(-1, Vector2i(-1,-1))
	var loc : Vector2i

	func getXY() -> Vector2i:
		return loc

	func _init(in_loc : Vector2i):
		atlas = AtlasIdent.new(-1, Vector2i(-1,-1))
		loc = in_loc
	
	func hasUnit() -> bool:
		return unit != null
	
	func hasBase() -> bool:
		return base != null
		
	func isOownedByBase() -> bool:
		return owned_by_base != null
		
	func baseOwnedBy() -> LogicEngine.Base:
		return owned_by_base

class Circle:
	var pos : Vector2
	var radius : float
	var x1 : int
	var x2 : int
	var y1 : int
	var y2 : int
	var planet = 0

	func getSquareLen(rad : float) -> float:
		return sqrt(2) * rad
	
	func _init(p : Vector2, in_radius : float, in_planet : int):
		pos = p
		radius = in_radius
		planet = in_planet

		var len = getSquareLen(radius)

		x1 = int(p.x-len/2)
		x2 = int(p.x+len/2)
		y1 = int(p.y-len/2)
		y2 = int(p.y+len/2)

	func inCircle(p : Vector2i) -> bool:
		return (p.x - pos.x) * (p.x - pos.x) + (p.y - pos.y) * (p.y - pos.y) < radius * radius

	func inSquare(p : Vector2i) -> bool:
		return p.x >= x1 and p.x <= x2 and p.y >= y1 and p.y <= y2
		
	func onBottomBoundary(p : Vector2i) -> bool:
		return p.x >= x1 and p.x == x2+1 and p.y >= y1 and p.y <= y2
	func onTopBoundary(p : Vector2i) -> bool:
		return p.x == x1-1 and p.x <= x2 and p.y >= y1 and p.y <= y2
	func onLeftBoundary(p : Vector2i) -> bool:
		return p.x >= x1 and p.x <= x2 and p.y == y1-1 and p.y <= y2
	func onRightBoundary(p : Vector2i) -> bool:
		return p.x >= x1 and p.x <= x2 and p.y >= y1 and p.y == y2+1

	func onBottomLeftBoundary(p : Vector2i) -> bool:
		return p.x >= x1 and p.x == x2+1 and p.y == y1-1 and p.y <= y2
	func onBottomRightBoundary(p : Vector2i) -> bool:
		return p.x >= x1 and p.x == x2+1 and p.y >= y1 and p.y == y2+1
	func onTopLeftBoundary(p : Vector2i) -> bool:
		return p.x == x1-1 and p.x <= x2 and p.y == y1-1 and p.y <= y2
	func onTopRightBoundary(p : Vector2i) -> bool:
		return p.x == x1-1 and p.x <= x2 and p.y >= y1 and p.y == y2+1

var altitude = FastNoiseLite.new()
var width : int = 200
var height : int = 200
var circles = [Circle.new(Vector2(9,8), 5, 0), Circle.new(Vector2(8,20), 5, 1)]

var tiles : Array[Tile]

func convertTo1D(vec : Vector2i) -> int:
	return vec.x * width + vec.y

func getTileXY(x : int, y : int) -> Tile:
	return tiles[convertTo1D(Vector2i(x, y))]
	
func getTileVec(vec : Vector2i) -> Tile:
	return tiles[convertTo1D(vec)]
	
	#var base_layer_id : int = -1
	#var resource_layer_id : int = -1

	#for i in in_tile_map.get_layers_count():
		#if in_tile_map.get_layer_name(i) == "Base layer":
			#base_layer_id = i
		#if in_tile_map.get_layer_name(i) == "Resources":
			#resource_layer_id = i

	#for x in width:
		#for y in height:
			#var coord : Vector2i = Vector2i(x,y)
			##var td : TileData = in_tile_map.get_cell_tile_data(base_layer_id, coord)
			#var atlas_coord = in_tile_map.get_cell_atlas_coords(base_layer_id, coord)
			#var source_id = in_tile_map.get_cell_source_id(base_layer_id, coord)
			#var atlas_source = in_tile_map.tile_set.get_source(source_id) as TileSetAtlasSource

# Called when the node enters the scene tree for the first time.
func _ready():
	altitude.seed = randi()
	tiles.resize(width*height)

	for x in width:
		for y in height:
			tiles[convertTo1D(Vector2i(x, y))] = Tile.new(Vector2i(x, y))
			var tile = getTileXY(x, y)
			tile.type = TileTypeEnum.SPACE
			tile.atlas_space = AtlasIdent.new(1, Vector2i(0,0))
			for c in circles:
				if c.inSquare(Vector2i(x,y)):
					#print("planet=" + str(c.planet) + ", x=", str(x), ", y=", str(y))
					var alt = altitude.get_noise_2d(float(x)*50.0, float(y)*50.0)*10
					var mountain = alt > 1

					if c.planet == 0:
						if mountain:
							tile.type = TileTypeEnum.MOUNTAIN
							tile.atlas = AtlasIdent.new(7, Vector2i(5,0))
						else:
							tile.type = TileTypeEnum.LAND
							tile.atlas = AtlasIdent.new(6, Vector2i(1,0))
					elif c.planet == 1:
						if mountain:
							tile.type = TileTypeEnum.MOUNTAIN
							tile.atlas = AtlasIdent.new(7, Vector2i(6,0))
						else:
							tile.type = TileTypeEnum.LAND
							tile.atlas = AtlasIdent.new(6, Vector2i(2,0))
					else:
						print("ERROR")

					var prob = randi_range(1,4)
					if prob == 2:
						if c.planet == 0:
							if tile.type == TileTypeEnum.MOUNTAIN:
								tile.resource = AtlasIdent.new(9, Vector2i(0,1))
							else:
								tile.resource = AtlasIdent.new(9, Vector2i(8,0))
						elif c.planet == 1:
							if tile.type == TileTypeEnum.MOUNTAIN:
								tile.resource = AtlasIdent.new(9, Vector2i(2,1))
							else:
								tile.resource = AtlasIdent.new(9, Vector2i(1,1))

				elif c.onBottomBoundary(Vector2i(x,y)) or c.onTopBoundary(Vector2i(x,y)):
					tile.type = TileTypeEnum.ATMOSPHERE
					tile.atlas = AtlasIdent.new(0, Vector2i(0,0))
				elif c.onLeftBoundary(Vector2i(x,y)) or c.onRightBoundary(Vector2i(x,y)):
					tile.type = TileTypeEnum.ATMOSPHERE
					tile.atlas = AtlasIdent.new(0, Vector2i(1,0))
				elif c.onBottomLeftBoundary(Vector2i(x,y)):
					tile.type = TileTypeEnum.ATMOSPHERE
					tile.atlas = AtlasIdent.new(0, Vector2i(3,0))
				elif c.onBottomRightBoundary(Vector2i(x,y)):
					tile.type = TileTypeEnum.ATMOSPHERE
					tile.atlas = AtlasIdent.new(0, Vector2i(5,0))
				elif c.onTopLeftBoundary(Vector2i(x,y)):
					tile.type = TileTypeEnum.ATMOSPHERE
					tile.atlas = AtlasIdent.new(0, Vector2i(2,0))
				elif c.onTopRightBoundary(Vector2i(x,y)):
					tile.type = TileTypeEnum.ATMOSPHERE
					tile.atlas = AtlasIdent.new(0, Vector2i(4,0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
