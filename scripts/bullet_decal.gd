extends Sprite3D

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)  
	tween.tween_callback(queue_free)  

func _on_timer_timeout() -> void:
	queue_free()
