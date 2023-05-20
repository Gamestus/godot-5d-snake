extends Camera2D


var is_end_of_time = false


func tween_to(pos: Vector2, is_instant = false) -> void:
	if is_instant:
		position = pos
		return
	var tween = $Tween
	tween.interpolate_property(self, "position",
			self.position, pos, 0.3,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func reveal():
	if zoom == Vector2(2, 2):
		return
	var tween = $Tween
	tween.interpolate_property(self, "zoom",
			self.zoom, Vector2(2, 2), 1.0,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	tween.interpolate_property($DarkMatter, "modulate:a",
			$DarkMatter.modulate.a, 1.0, 0.5,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _process(delta: float) -> void:
	if not is_end_of_time:
		return
	position += Vector2(55, 0) * delta
	if position.x > 10000:
		position = Vector2(-500, 57)


func show_progress():
	var tween = $Tween
	tween.stop_all()
	zoom = Vector2(5, 5)
	is_end_of_time = true
	position = Vector2(-700, 57)
