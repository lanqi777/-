extends Area2D

var damage: int = 1
var attack_interval: float = 1.0
var attack_timer: float = 0.0
var lifetime: float = 10.0
var lifetime_timer: float = 0.0
var summoner: Node = null  # 召唤者引用

func _ready():
	# 设置碰撞
	collision_layer = 4
	collision_mask = 2
	
	# 添加到召唤物组
	add_to_group("summon")
	
	# 加载召唤物图片
	var sprite = Sprite2D.new()
	var texture = load("res://assets/summon.png")
	if texture:
		sprite.texture = texture
		sprite.scale = Vector2(0.1, 0.1)
		add_child(sprite)
	
	# 设置碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	add_child(collision)

func _process(delta):
	attack_timer += delta
	lifetime_timer += delta
	
	# 自动攻击最近的敌人
	if attack_timer >= attack_interval:
		attack_timer = 0.0
		attack_nearest_enemy()
	
	# 持续时间结束
	if lifetime_timer >= lifetime:
		die()

# 添加 set_properties 方法
func set_properties(unit_damage: int, unit_lifetime: float):
	damage = unit_damage
	lifetime = unit_lifetime

func attack_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		var nearest_enemy = null
		var min_distance = INF
		
		for enemy in enemies:
			var distance = position.distance_to(enemy.position)
			if distance < min_distance:
				min_distance = distance
				nearest_enemy = enemy
		
		if nearest_enemy and min_distance < 100:  # 攻击范围
			nearest_enemy.take_damage(damage)
			print("召唤物攻击！造成伤害: ", damage)

func die():
	if summoner and summoner.has_method("summon_unit_died"):
		summoner.summon_unit_died()
	queue_free()
