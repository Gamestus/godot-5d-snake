class_name Field
extends ColorRect

const COLUMNS = 16
const ROWS = 9

onready var tile_map: TileMap = $MarginContainer/VBoxContainer/Panel/TileMap
onready var turn_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Turn

enum Cell{
	nothing,
	apple,
	body,
	head,
}

var game_array: Array = []

var turn = 0

func _ready() -> void:
	turn += 1
	turn_label.text = "%02d" % turn
	if turn >= 80:
		color.r += float(turn - 80)/12
		color.g -= float(turn - 80)/12
		color.b -= float(turn - 80)/12
	if rect_position.y >= 220 or rect_position.y <= -190:
		color = Color.gray



func init_game_start(is_create_apple = true):
	var line: PoolIntArray = []
	for i in ROWS:
		line.append(0)
	for i in COLUMNS:
		game_array.append(line)
	if is_create_apple:
		create_apple()



func is_cell_exists(index : Vector2) -> bool:
	return index.x >= 0 and index.x < COLUMNS and\
			index.y >= 0 and index.y < ROWS


func draw_screen(direction) -> void:
	if not is_instance_valid(tile_map):
		yield(self, "ready")
	
	for y in ROWS:
		for x in COLUMNS:
			if game_array[x][y] == Cell.head:
				tile_map.set_cell(
						x,
						y,
						game_array[x][y],
						direction == Vector2.UP,
						direction == Vector2.LEFT or direction == Vector2.RIGHT,
						direction == Vector2.LEFT or direction == Vector2.RIGHT
				)
			else:
				tile_map.set_cell(x, y, game_array[x][y])


func create_apple():
	var counter = 0
	while true or counter < 200:
		var spawn_position = Vector2(randi() % COLUMNS, randi() % ROWS)
		counter += 1
		if game_array[spawn_position.x][spawn_position.y] == Cell.nothing:
			game_array[spawn_position.x][spawn_position.y] = Cell.apple
			return
	printerr("Wow")
