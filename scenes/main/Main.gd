class_name Main
extends Node2D

onready var map: Node2D = $Map
onready var camera_2d: Camera2D = $Camera2D

# Still depends on field_dict
const MAX_DIMENSION_FIELD = 4
const APOCALYPSE_FIELD = 100
const FIELD_OFFSET = Vector2(6, 6)

const MIN_TIME_SCALE = 0.1
const DELTA_TIME_SCALE = 0.15
const MAX_TIME_SCALE = 2.1

const IS_CAM_REVEALED = true

enum Cell{
	NOTHING,
	APPLE,
	BODY,
	HEAD,
}

var field = preload("res://scenes/main/Field.tscn")

const SHADER_SPEED = 0.015
var shader_time_param = 0.0
var shader_time_scale = 0.0
# Snake can move in 17 directions, so
# direction_additional is essential
# "_a" (additional) suffix in variables 
# means usage of other dimensions
var direction_additional = Vector2.ZERO
var direction = Vector2.RIGHT
var last_direction = direction
var is_making_longer = false
var score = 0
var is_end_of_time = false
var head_on_field: Field

var snake_array = [
		[Vector2(1, 5), Vector2(0, 0)],
		[Vector2(0, 5), Vector2(0, 0)]
]

var field_dict: Dictionary = {
}


func _ready() -> void:
	randomize()
	head_on_field = get_or_create_field(Vector2.ZERO)
	head_on_field.init_game_start()
	
	if TurboMode.turbo_mode:
		$Ui/MarginContainer/VBoxContainer/HBoxContainer/StrangeLabel.visible = true
	if IS_CAM_REVEALED:
		$Camera2D.reveal()


func _process(delta: float) -> void:
	shader_time_param += SHADER_SPEED * shader_time_scale
	$Camera2D/DarkMatter.material.set_shader_param("time", shader_time_param) 


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


func _on_StepTimer_timeout() -> void:
	make_turn()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func make_turn() -> void:
	var snake_pos = snake_array[0][0]
	var snake_pos_a = snake_array[0][1]
	head_on_field = field_dict[int(snake_pos_a.y)][snake_pos_a.x]
	head_on_field.game_array[snake_pos.x][snake_pos.y] = Cell.BODY
	head_on_field.draw_screen(direction)
	
	if direction_additional.x < 0:
		shader_time_scale = - snake_pos_a.x / APOCALYPSE_FIELD * 4.0
	else:
		shader_time_scale = snake_pos_a.x / APOCALYPSE_FIELD * 4.0
	
	if direction_additional == Vector2.ZERO:
		move_head()
	else:
		move_head_a()
	
	$Music.volume_db = linear2db(clamp(float(50 - snake_pos_a.x) / 50, 0, 0.4))
	$Music2.volume_db = linear2db(clamp(float(snake_pos_a.x) / 50, 0, 0.5 ))


func move_head():
	var snake_pos = snake_array[0][0]
	var snake_pos_a = snake_array[0][1]
	
	if snake_pos_a.x < field_dict[int(snake_pos_a.y)].size() - 1:
		# if call move_head_a with same direction as before
		# snake moves in same field only
		# looks cool ;)
		direction_additional.x = 1.0
		move_head_a()
		return
	
	
	snake_array.push_front(
			[
				Vector2(snake_pos.x + direction.x, snake_pos.y + direction.y),
				Vector2(snake_pos_a.x + 1, snake_pos_a.y + direction_additional.y),
			]
	)
	
	if not try_move(snake_array[0][0], snake_pos_a):
		return
	var new_field = get_or_create_field(snake_array[0][1], head_on_field)
	
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


func move_head_a():
	var snake_pos = snake_array[0][0]
	var snake_pos_a = snake_array[0][1]
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
	
	head_on_field = get_or_create_field(snake_array[0][1])
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


func get_or_create_field(additional_pos: Vector2, duplicate_field: Field = null) -> Field:
	var dimension: int = additional_pos.y
	if not field_dict.has(dimension):
		field_dict[dimension] = []
	
	if field_dict[dimension].size() <= additional_pos.x or \
			field_dict[dimension][additional_pos.x] == null:
		return create_field_at(additional_pos, duplicate_field)
	
	return field_dict[dimension][additional_pos.x]


func create_field_at(additional_pos: Vector2, duplicate_field: Field = null) -> Field:
	var new_field = field.instance()
	new_field.init_game_start(false)
	new_field.turn = additional_pos.x
	new_field.rect_position = (Field.FIELD_SIZE + FIELD_OFFSET) * additional_pos
	
	if duplicate_field:
		new_field.game_array = duplicate_field.game_array.duplicate()
	add_field_to_dict(additional_pos, new_field)
	map.add_child(new_field)
	camera_2d.tween_to(new_field.rect_position + Field.FIELD_SIZE / 2, true)
	return new_field


func add_field_to_dict(additional_pos: Vector2, field: Field):
	var dimension: int = additional_pos.y
	
	var dimension_size = field_dict[dimension].size()
	
	if dimension_size == additional_pos.x:
		field_dict[dimension].append(field)
	
	elif dimension_size < additional_pos.x:
		var needed_to_add = 1 + additional_pos.x - dimension_size
		for i in needed_to_add - 1:
			field_dict[dimension].append(null)
	else:
		field_dict[dimension][additional_pos.x] = field


func is_field_within_boundaries(move_to_a):
	return move_to_a.x >= 0 and move_to_a.x < APOCALYPSE_FIELD and\
			move_to_a.y >= -MAX_DIMENSION_FIELD and move_to_a.y <= MAX_DIMENSION_FIELD


func try_move(move_to, move_to_a, duplicate_field: Field = null) -> bool:
	var is_dim_created = false
	
	if not is_field_within_boundaries(move_to_a):
		game_over()
		return false
	
	var field = get_or_create_field(move_to_a, duplicate_field)
	
	if not field.is_cell_within_boundaries(move_to):
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
			pass
			if not is_dim_created:
				game_over()
				return false
	return true


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

