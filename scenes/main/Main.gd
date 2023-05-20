class_name Main
extends Node2D

var field = preload("res://scenes/main/Field.tscn")
onready var map: Node2D = $Map
onready var camera_2d: Camera2D = $Camera2D

# Still depends on field_dict
const MAX_DIMENSION_FIELD = 4
const APOCALYPSE_FIELD = 100
const FIELD_OFFSET = Vector2(5, 5)

const MIN_TIME_SCALE = 0.1
const DELTA_TIME_SCALE = 0.15
const MAX_TIME_SCALE = 2.1

# Snake can move in 17 directions, so
# direction_additional is essential
# "_a" (additional) suffix in variables 
# means usage of other dimensions
var direction_additional = Vector2.ZERO
var direction = Vector2.RIGHT
var last_direction = direction
var is_making_longer = false
var score = 0
var shader_time_param = 0.0
var time_scale = 0.0
var is_end_of_time = false


var snake_array = [
		[Vector2(1, 5), Vector2(0, 0)],
		[Vector2(0, 5), Vector2(0, 0)]
]

enum Cell{
	NOTHING,
	APPLE,
	BODY,
	HEAD,
}

var field_dict = {
	-4: [],
	-3: [],
	-2: [],
	-1: [],
	0: [],
	1: [],
	2: [],
	3: [],
	4: []
}

var head_on_field: Field

func _process(delta: float) -> void:
	shader_time_param += 0.01 * time_scale
	$Camera2D/DarkMatter.material.set_shader_param("time", shader_time_param) 



func _ready() -> void:
	randomize()
	head_on_field = field.instance()
	map.add_child(head_on_field)
	field_dict[0].append(head_on_field)
	head_on_field.rect_position = Field.FIELD_SIZE / 2
	head_on_field.init_game_start()
	camera_2d.tween_to(head_on_field.rect_position + Field.FIELD_SIZE / 2, true)
	
	if TurboMode.turbo_mode:
		$Ui/MarginContainer/VBoxContainer/HBoxContainer/StrangeLabel.visible = true


func make_turn() -> void:
	var snake_pos = snake_array[0][0]
	var snake_pos_a = snake_array[0][1]
	head_on_field = field_dict[int(snake_pos_a.y)][snake_pos_a.x]
	head_on_field.game_array[snake_pos.x][snake_pos.y] = Cell.BODY
	head_on_field.draw_screen(direction)
	
	if direction_additional.x < 0:
		time_scale = - snake_pos_a.x / APOCALYPSE_FIELD * 4.0
	else:
		time_scale = snake_pos_a.x / APOCALYPSE_FIELD * 4.0
	
	if direction_additional == Vector2.ZERO:
		move_head(snake_pos, snake_pos_a)
	else:
		move_head_a(snake_pos, snake_pos_a)
	
	$Music.volume_db = linear2db(clamp(float(50 - snake_pos_a.x) / 50, 0, 0.4))
	$Music2.volume_db = linear2db(clamp(float(snake_pos_a.x) / 50, 0, 0.5 ))


func move_head_a(snake_pos, snake_pos_a):
	$Camera2D.reveal()
	is_end_of_time = true
	snake_array.push_front(
			[
				Vector2(snake_pos.x + direction.x, snake_pos.y + direction.y),
				Vector2(snake_pos_a.x + direction_additional.x, snake_pos_a.y + direction_additional.y),
			]
	)
	
	if not try_move(snake_array[0][0], snake_array[0][1]):
		return
	
	head_on_field = field_dict[int(snake_array[0][1].y)][snake_array[0][1].x]
	head_on_field.game_array[snake_array[0][0].x][snake_array[0][0].y] = Cell.HEAD
	
	if not is_making_longer:
		var erase_cell = snake_array.pop_back()
		var erase_field = field_dict[int(erase_cell[1].y)][erase_cell[1].x]
		erase_field.game_array[erase_cell[0].x][erase_cell[0].y] = Cell.NOTHING
		erase_field.draw_screen(direction)
	is_making_longer = false
	
	head_on_field.draw_screen(direction)
	last_direction = direction
	camera_2d.tween_to(head_on_field.rect_position + Field.FIELD_SIZE / 2, false)


func move_head(snake_pos, snake_pos_a):
	
	if snake_pos_a.x < field_dict[int(snake_pos_a.y)].size() - 1:
		move_head_from_past(snake_pos, snake_pos_a)
		return
	
	
	snake_array.push_front(
			[
				Vector2(snake_pos.x + direction.x, snake_pos.y + direction.y),
				Vector2(snake_pos_a.x + 1, snake_pos_a.y+ direction_additional.y),
			]
	)
	
	if not try_move(snake_array[0][0], snake_pos_a):
		return
	var new_field = create_field(snake_pos_a.y)
	
	head_on_field = field_dict[int(snake_array[0][1].y)][snake_array[0][1].x]
	head_on_field.game_array[snake_array[0][0].x][snake_array[0][0].y] = Cell.HEAD
	
	if not is_making_longer:
		var erase_cell = snake_array.pop_back()
		var erase_field = new_field
		erase_field.game_array[erase_cell[0].x][erase_cell[0].y] = Cell.NOTHING
		erase_field.draw_screen(direction)
	is_making_longer = false
	
	head_on_field.draw_screen(direction)
	last_direction = direction


func move_head_from_past(snake_pos, snake_pos_a):
	snake_array.push_front(
			[
				Vector2(snake_pos.x + direction.x, snake_pos.y + direction.y),
				Vector2(snake_pos_a.x + 1, snake_pos_a.y + direction_additional.y),
			]
	)
	
	if not try_move(snake_array[0][0], snake_array[0][1]):
		return
	
	head_on_field = field_dict[int(snake_array[0][1].y)][snake_array[0][1].x]
	head_on_field.game_array[snake_array[0][0].x][snake_array[0][0].y] = Cell.HEAD
	
	if not is_making_longer:
		var erase_cell = snake_array.pop_back()
#		var erase_field = field_dict[int(snake_array[0][1].y)][erase_cell[1].x]
		var erase_field = field_dict[int(erase_cell[1].y)][erase_cell[1].x]
		erase_field.game_array[erase_cell[0].x][erase_cell[0].y] = Cell.NOTHING
		erase_field.draw_screen(direction)
	is_making_longer = false
	
	head_on_field.draw_screen(direction)
	last_direction = direction
	
	camera_2d.tween_to(head_on_field.rect_position + Field.FIELD_SIZE / 2, true)


func create_field(new_y: int = 0, offset = Vector2(90 , 0)):
	var new_field = field.instance()
	new_field.game_array = head_on_field.game_array.duplicate()
	new_field.turn = head_on_field.turn
	if new_field.turn == APOCALYPSE_FIELD - 1:
		$Ui/GameOver/Label.text = "R: restart\npass: 0133"
		game_over()
	
	
	new_field.rect_position = head_on_field.rect_position + offset
	field_dict[new_y].append(new_field)
	map.add_child(new_field)
	camera_2d.tween_to(new_field.rect_position + Field.FIELD_SIZE / 2, true)
	return new_field


func create_global_field(additional_pos):
	var new_field = field.instance()
	new_field.init_game_start(false)
	new_field.turn = -1
	new_field.rect_position = Field.FIELD_SIZE / 2 + Vector2(90 * additional_pos.x, 60 * additional_pos.y)
	
	map.add_child(new_field)
	
	field_dict[int(additional_pos.y)][additional_pos.x] = new_field
	camera_2d.tween_to(new_field.rect_position + Field.FIELD_SIZE / 2)
	return new_field


func _input(event: InputEvent) -> void:
	if not TurboMode.turbo_mode and event.is_action_pressed("turbo"):
		TurboMode.turbo_mode = true
		$Ui/MarginContainer/VBoxContainer/HBoxContainer/StrangeLabel.visible = true
		$APPLESound.play()
	
	var new_dir = Vector2.ZERO
	var new_dir_a = Vector2.ZERO
	if event.is_action_pressed("ui_up"):
		new_dir = Vector2.UP
	elif event.is_action_pressed("ui_down"):
		new_dir = Vector2.DOWN
	elif event.is_action_pressed("ui_left"):
		new_dir = Vector2.LEFT
	elif event.is_action_pressed("ui_right"):
		new_dir = Vector2.RIGHT
	elif event.is_action_pressed("ui_page_up"):
		new_dir_a = Vector2.UP
	elif event.is_action_pressed("ui_page_down"):
		new_dir_a = Vector2.DOWN
	elif event.is_action_pressed("forward"):
		new_dir_a = Vector2.ZERO
	elif event.is_action_pressed("past"):
		new_dir_a = Vector2.LEFT
	if new_dir != Vector2.ZERO and new_dir + last_direction != Vector2.ZERO:
		direction = new_dir
		direction_additional = Vector2.ZERO
	elif new_dir_a != Vector2.ZERO and TurboMode.turbo_mode:
		direction_additional = new_dir_a
		direction = Vector2.ZERO
	
	$Ui/MarginContainer/VBoxContainer/HBoxContainer/StrangeLabel.text = str(direction) + " " + str(direction_additional)
	
	if event.is_action_pressed("speedup"):
		$StepTimer.wait_time = clamp($StepTimer.wait_time - DELTA_TIME_SCALE, 
				MIN_TIME_SCALE, 
				MAX_TIME_SCALE
		)
	elif event.is_action_pressed("speeddown"):
		$StepTimer.wait_time = clamp($StepTimer.wait_time + DELTA_TIME_SCALE, 
				MIN_TIME_SCALE, 
				MAX_TIME_SCALE
		)


func is_field_exists(move_to_a):
	return move_to_a.x >= 0 and move_to_a.x < APOCALYPSE_FIELD and\
			move_to_a.y >= -MAX_DIMENSION_FIELD and move_to_a.y <= MAX_DIMENSION_FIELD


func try_move(move_to, move_to_a) -> bool:
	var is_dim_created = false
	if not is_field_exists(move_to_a):
		game_over()
		return false
	
	#if array element not exists on dim
	if field_dict[int(move_to_a.y)].size() <= move_to_a.x:
		create_field_at_dimension(move_to_a)
		is_dim_created = true
	
	var field = field_dict[int(move_to_a.y)][move_to_a.x]
	
	if field == null:
		field = create_global_field(move_to_a)
	
	
	if not field.is_cell_exists(move_to):
		game_over()
		return false
	
	match field.game_array[move_to.x][move_to.y]:
		Cell.APPLE:
			score += 1
			$Ui/MarginContainer/VBoxContainer/HBoxContainer/Score.text = "%04d" % score
			field.create_apple()
			$AppleSound.play()
			is_making_longer = true
		Cell.BODY, Cell.HEAD:
			if not is_dim_created:
				game_over()
				return false
	return true


func create_field_at_dimension(move_to_a: Vector2):
	var new_y = move_to_a.y
	var needed_to_add = 1 + move_to_a.x - field_dict[int(new_y)].size()
	
	for i in needed_to_add - 1:
		field_dict[int(new_y)].append(null)
	create_field(new_y, Vector2(0, 60 * direction_additional.y))


func _on_StepTimer_timeout() -> void:
	make_turn()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func game_over() -> void:
	$GameOverSound.play()
	$StepTimer.stop()
	if is_end_of_time:
		$Music.stop()
		$Music2.stop()
		$Ui.visible = false
		$Camera2D/EndOfTime.end(score)
		$Camera2D.show_progress()
	else:
		$Ui/GameOver/AnimationPlayer.play("KO")
