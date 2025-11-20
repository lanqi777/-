extends Area2D

var damage: int = 1
var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var penetration: int = 1  # 穿透次数
var hit_enemies: Array = []  # 已击中的敌人

func _ready():
	# 设置碰撞层和掩码
	collision_layer = 4  # 箭矢在第4层
	collision_mask = 2   # 检测第2层（敌人）
	
	# 设置碰撞信号
	var connect_result = area_entered.connect(_on_area_entered)
	print("箭矢碰撞信号连接结果: ", connect_result)
	
	# 旋转箭矢朝向移动方向
	rotation = direction.angle()

func _process(delta):
	# 直线移动
	position += direction * speed * delta
	
	# 如果箭矢超出屏幕，销毁
	if position.x > get_viewport_rect().size.x + 50 or position.x < -50 or \
	   position.y > get_viewport_rect().size.y + 50 or position.y < -50:
		queue_free()

func set_properties(arrow_damage: int, arrow_speed: float, arrow_direction: Vector2, arrow_penetration: int):
	damage = arrow_damage
	speed = arrow_speed
	direction = arrow_direction
	penetration = arrow_penetration
	
	# 旋转箭矢朝向移动方向
	rotation = direction.angle()

func _on_area_entered(area):
	print("=== 箭矢碰撞检测开始 ===")
	print("箭矢碰撞到区域: ", area.name)
	
	var enemy = null
	
	# 检测敌人
	if area.has_method("take_damage"):
		enemy = area
		print("通过方法1检测到敌人")
	elif area.get_parent() and area.get_parent().has_method("take_damage"):
		enemy = area.get_parent()
		print("通过方法2检测到敌人")
	
	if enemy and enemy not in hit_enemies:
		hit_enemies.append(enemy)
		enemy.take_damage(damage)
		print("箭矢击中敌人！造成伤害: ", damage, " 穿透剩余: ", penetration - hit_enemies.size())
		
		# 检查穿透次数
		if hit_enemies.size() >= penetration:
			queue_free()
	
	print("=== 箭矢碰撞检测结束 ===")
