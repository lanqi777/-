extends Node2D

var duration: float = 0.3

func _ready():
	# 创建斩击动画效果
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
	
	# 加载斩击图片
	var sprite = Sprite2D.new()
	var texture = load("res://assets/slash.png")
	if texture:
		sprite.texture = texture
		sprite.scale = Vector2(0.1, 0.1)
		add_child(sprite)
