extends ColorRect


func end(score):
	$AnimationPlayer.play("End")
	$Label.text = "score: %d" % score
