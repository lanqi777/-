extends Area2D

var max_health: int = 5
var health: int
var reward: int = 10
var speed: float = 50.0
var target_position: Vector2

# 效果状态
var is_burning: bool = false
var burn_damage: int = 0
var burn_duration: float = 0.0
var burn_timer: float = 0.0

var is_slowed: bool = false
var slow_factor: float = 1.0
var slow_duration: float = 0.0
var slow_timer: float = 0.0

var is_frozen: bool = false
var freeze_duration: float = 0.0
var freeze_timer: float = 0.0

var is_poisoned: bool = false
var poison_damage: int = 0
var poison_duration: float = 0.0
var poison_timer: float = 0.0

var original_speed: float = 50.0

# 将 @onready 改为在 _ready 中手动获取
var health_bar
var sprite

func _ready():
	# 手动获取节点
	health_bar = get_node_or_null("HealthBar")
	sprite = get_node_or_null("Sprite2D")
	
	# 检查节点是否存在
	if not sprite:
		print("错误：Enemy 场景中没有 Sprite2D 节点")
		return
		
	if not health_bar:
		print("警告：Enemy 场景中没有 HealthBar 节点")

	health = max_health
	original_speed = speed
	
	# 设置碰撞层
	collision_layer = 2  # 敌人在第2层
	collision_mask = 1   # 检测第1层（主角）
	
	# 添加到敌人组
	add_to_group("enemy")
	
	update_health_bar()
	
	# 设置随机位置
	var screen_size = get_viewport().get_visible_rect().size
	position = Vector2(
		randf_range(50, screen_size.x - 50),
		-50
	)
	
	# 加载敌人图片
	var texture = load("res://assets/enemy.png")
	if texture:
		sprite.texture = texture
	else:
		print("警告：无法加载敌人图片资源")

func _process(delta):
	# 如果 sprite 为 null，直接返回
	if not sprite:
		return
		
	# 处理效果计时器
	process_effects(delta)
	
	# 如果被冻结，不移动
	if is_frozen:
		return
	
	# 寻找主角位置
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		target_position = player.global_position
	
	# 应用减速效果
	var current_speed = speed
	if is_slowed:
		current_speed = original_speed * slow_factor
	
	# 向主角位置移动
	var direction = (target_position - position).normalized()
	position += direction * current_speed * delta
	
	# 如果超出屏幕下方，自动销毁
	if position.y > get_viewport().get_visible_rect().size.y + 100:
		queue_free()

func process_effects(delta):
	# 如果 sprite 为 null，直接返回
	if not sprite:
		return
	
	# 处理灼烧效果
	if is_burning:
		burn_timer += delta
		if burn_timer >= 1.0:  # 每秒造成一次伤害
			take_damage(burn_damage)
			burn_timer = 0.0
		
		if burn_duration > 0:
			burn_duration -= delta
			if burn_duration <= 0:
				is_burning = false
				sprite.modulate = Color.WHITE
	
	# 处理减速效果
	if is_slowed:
		slow_timer += delta
		if slow_timer >= slow_duration:
			is_slowed = false
			speed = original_speed
	
	# 处理冻结效果
	if is_frozen:
		freeze_timer += delta
		if freeze_timer >= freeze_duration:
			is_frozen = false
			sprite.modulate = Color.WHITE
	
	# 处理中毒效果
	if is_poisoned:
		poison_timer += delta
		if poison_timer >= 2.0:  # 每2秒造成一次伤害
			take_damage(poison_damage)
			poison_timer = 0.0
		
		if poison_duration > 0:
			poison_duration -= delta
			if poison_duration <= 0:
				is_poisoned = false
				sprite.modulate = Color.WHITE

func take_damage(damage: int):
	print("敌人受到伤害: ", damage, "，当前血量: ", health)
	health -= damage
	print("敌人剩余血量: ", health)
	update_health_bar()
	
	# 通知主游戏脚本更新总伤害
	if get_parent() and get_parent().has_method("add_total_damage"):
		get_parent().add_total_damage(damage)
	
	# 如果 sprite 为 null，跳过视觉效果
	if not sprite:
		return
		
	# 受伤效果
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		print("敌人死亡")
		die()

func update_health_bar():
	if health_bar:
		var health_ratio = float(health) / max_health
		health_bar.scale.x = health_ratio

func die():
	get_parent().enemy_died(reward)
	queue_free()

# 效果应用函数
func apply_burn(effect_data: Dictionary):
	if not sprite:
		return
		
	is_burning = true
	burn_damage = effect_data["damage"]
	burn_duration = effect_data["duration"]
	burn_timer = 0.0
	sprite.modulate = Color.ORANGE_RED

func apply_slow(effect_data: Dictionary):
	is_slowed = true
	slow_factor = effect_data["factor"]
	slow_duration = effect_data["duration"]
	slow_timer = 0.0
	speed = original_speed * slow_factor

func apply_freeze(duration: float):
	if not sprite:
		return
		
	is_frozen = true
	freeze_duration = duration
	freeze_timer = 0.0
	sprite.modulate = Color.CYAN

func apply_poison(effect_data: Dictionary):
	if not sprite:
		return
		
	is_poisoned = true
	poison_damage = effect_data["damage"]
	poison_duration = effect_data["duration"]
	poison_timer = 0.0
	sprite.modulate = Color.PURPLE
