extends Area2D

# 子弹基础属性
var damage: int = 1
var speed: float = 300.0
var target: Node2D = null

# 附加属性
var additional_effects: Dictionary = {
	"burn": {"damage": 0, "duration": 0.0},
	"slow": {"factor": 1.0, "duration": 0.0},
	"freeze": false,
	"poison": {"damage": 0, "duration": 0.0}
}

var sprite

func _ready():
	# 手动获取 Sprite2D 节点
	sprite = get_node_or_null("Sprite2D")
	
	# 如果节点不存在，动态创建
	if not sprite:
		print("Bullet 场景中没有 Sprite2D 节点，正在动态创建...")
		sprite = Sprite2D.new()
		add_child(sprite)
	
	# 设置子弹碰撞层和掩码
	collision_layer = 4  # 子弹在第4层
	collision_mask = 2   # 检测第2层（敌人）
	
	# 设置子弹碰撞 - 使用 area_entered
	var connect_result = connect("area_entered", _on_area_entered)
	print("子弹信号连接结果: ", connect_result)
	
	# 加载子弹图片
	var texture = load("res://assets/bullet.png")
	if texture:
		sprite.texture = texture
		# 调整子弹大小
		sprite.scale = Vector2(0.1, 0.1)
	else:
		print("警告：无法加载子弹图片资源")

func _process(delta):
	if target and is_instance_valid(target):
		# 向目标移动
		var direction = (target.global_position - global_position).normalized()
		position += direction * speed * delta
		
		# 旋转子弹朝向目标
		rotation = direction.angle()
		
		# 如果离目标很近，直接命中
		if global_position.distance_to(target.global_position) < 10:
			_on_area_entered(target)
	else:
		# 如果没有目标，直线前进
		position += Vector2.RIGHT.rotated(rotation) * speed * delta
		
		# 如果子弹超出屏幕，销毁
		if position.x > get_viewport_rect().size.x + 50 or position.x < -50 or \
		   position.y > get_viewport_rect().size.y + 50 or position.y < -50:
			queue_free()

func set_target(enemy: Node2D):
	target = enemy

func set_properties(bullet_damage: int, bullet_speed: float, effects: Dictionary = {}):
	damage = bullet_damage
	speed = bullet_speed
	additional_effects = effects

func _on_area_entered(area):
	print("=== 子弹碰撞检测开始 ===")
	print("子弹碰撞到区域: ", area.name)
	
	# 多种方式检测敌人
	var hit_enemy = null
	
	# 方法1：直接检测区域
	if area.has_method("take_damage"):
		hit_enemy = area
		print("通过方法1检测到敌人")
	
	# 方法2：检测区域的父节点
	if not hit_enemy and area.get_parent() and area.get_parent().has_method("take_damage"):
		hit_enemy = area.get_parent()
		print("通过方法2检测到敌人")
	
	# 方法3：通过组检测
	if not hit_enemy:
		var enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			if area == enemy or (area.get_parent() and area.get_parent() == enemy):
				hit_enemy = enemy
				print("通过方法3检测到敌人")
				break
	
	if hit_enemy:
		handle_enemy_hit(hit_enemy)
	else:
		print("未检测到有效的敌人")
		print("区域名称: ", area.name)
		print("区域父节点: ", area.get_parent().name if area.get_parent() else "无父节点")
		print("区域是否有take_damage方法: ", area.has_method("take_damage"))
		if area.get_parent():
			print("区域父节点是否有take_damage方法: ", area.get_parent().has_method("take_damage"))
	
	print("=== 子弹碰撞检测结束 ===")

func handle_enemy_hit(enemy):
	print("检测到敌人，造成伤害: ", damage)
	print("敌人当前血量: ", enemy.health)
	enemy.take_damage(damage)
	print("敌人受伤后血量: ", enemy.health)
	apply_additional_effects(enemy)
	queue_free()

func apply_additional_effects(enemy):
	# 应用所有附加效果
	for effect_name in additional_effects:
		match effect_name:
			"burn":
				if additional_effects[effect_name]["damage"] > 0:
					enemy.apply_burn(additional_effects[effect_name])
			"slow":
				if additional_effects[effect_name]["factor"] < 1.0:
					enemy.apply_slow(additional_effects[effect_name])
			"freeze":
				if additional_effects[effect_name]:
					enemy.apply_freeze(additional_effects[effect_name])
			"poison":
				if additional_effects[effect_name]["damage"] > 0:
					enemy.apply_poison(additional_effects[effect_name])
