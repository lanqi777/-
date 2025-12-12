extends Area2D

# 箭矢类型枚举
enum ARROW_TYPE {
	NORMAL,      # 普通箭矢
	MULTI_SHOT,  # 多重箭矢
	SPLIT,       # 分裂箭矢
	EXPLOSIVE,   # 爆炸箭矢
	POISON       # 毒箭
}

# 基础属性
var damage: int = 1
var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var penetration: int = 1
var arrow_type: ARROW_TYPE = ARROW_TYPE.NORMAL

# 物理系统 - 重命名以避免与 Area2D 的内置 gravity 冲突
var arrow_gravity: float = 0.0  # 重命名
var arrow_drag: float = 0.0     # 重命名
var velocity: Vector2 = Vector2.ZERO
var initial_speed: float = 0.0

# 分裂机制
var split_count: int = 3
var split_angle: float = 30.0
var can_split: bool = false

# 爆炸机制
var explosion_radius: float = 100.0
var explosion_damage: int = 2

# 状态效果
var poison_damage: int = 1
var poison_duration: float = 3.0

# 视觉效果
var trail_particles: GPUParticles2D
var hit_particles: GPUParticles2D
var explosion_particles: GPUParticles2D

# 跟踪系统
var hit_enemies: Array = []
var has_hit: bool = false

# 调试支持
@export var debug_draw: bool = false
var collision_shape: CollisionShape2D

# 信号系统
signal arrow_created(arrow_instance)
signal arrow_hit(enemy, damage, arrow_type)
signal arrow_split(original_arrow, new_arrows)
signal arrow_exploded(position, radius, damage)

func _ready():
	# 初始化物理系统
	velocity = direction * speed
	initial_speed = speed
	
	# 设置碰撞层和掩码
	collision_layer = 4
	collision_mask = 2
	
	# 连接碰撞信号
	var connect_result = area_entered.connect(_on_area_entered)
	print("箭矢碰撞信号连接结果: ", connect_result)
	
	# 初始化视觉效果
	initialize_visual_effects()
	
	# 设置箭矢旋转
	update_rotation()
	
	# 获取碰撞形状用于调试
	collision_shape = get_node_or_null("CollisionShape2D")

func _process(delta):
	# 应用物理模拟
	apply_physics(delta)
	
	# 更新位置
	position += velocity * delta
	
	# 更新旋转以匹配移动方向
	update_rotation()
	
	# 边界检查
	check_boundaries()
	
	# 调试绘制
	if debug_draw:
		queue_redraw()

func _draw():
	if debug_draw:
		# 绘制碰撞形状
		if collision_shape and collision_shape.shape:
			var shape = collision_shape.shape
			if shape is RectangleShape2D:
				var rect = Rect2(-shape.size / 2, shape.size)
				draw_rect(rect, Color.YELLOW, false)
			elif shape is CircleShape2D:
				draw_circle(Vector2.ZERO, shape.radius, Color.YELLOW)
		
		# 根据箭矢类型绘制不同颜色的轮廓
		var outline_color = get_arrow_color()
		draw_set_transform_matrix(Transform2D())
		draw_arc(Vector2.ZERO, 10, 0, TAU, 8, outline_color)

func initialize_visual_effects():
	# 创建轨迹粒子效果
	trail_particles = GPUParticles2D.new()
	trail_particles.emitting = true
	trail_particles.one_shot = false
	trail_particles.lifetime = 0.5
	trail_particles.explosiveness = 0.0
	trail_particles.amount = 16
	
	var trail_process_material = ParticleProcessMaterial.new()
	trail_process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	trail_process_material.spread = 180.0
	trail_process_material.gravity = Vector3(0, 0, 0)
	trail_process_material.initial_velocity_min = 10.0
	trail_process_material.initial_velocity_max = 20.0
	trail_process_material.linear_accel_min = -5.0
	trail_process_material.linear_accel_max = -10.0
	trail_process_material.color = get_arrow_color()
	trail_particles.process_material = trail_process_material
	
	add_child(trail_particles)

func apply_physics(delta):
	# 应用重力
	velocity.y += arrow_gravity * delta  # 使用重命名的变量
	
	# 应用阻力
	if arrow_drag > 0:  # 使用重命名的变量
		var current_speed = velocity.length()
		if current_speed > 0:
			var drag_force = velocity.normalized() * arrow_drag * delta  # 使用重命名的变量
			velocity -= drag_force
			
			# 确保速度不会反向
			if velocity.length() < 10.0:
				velocity = Vector2.ZERO

func update_rotation():
	if velocity.length() > 0:
		rotation = velocity.angle()

func check_boundaries():
	var viewport_rect = get_viewport_rect()
	if position.x > viewport_rect.size.x + 50 or position.x < -50 or \
	   position.y > viewport_rect.size.y + 50 or position.y < -50:
		cleanup_and_free()

func set_properties(arrow_damage: int, arrow_speed: float, arrow_direction: Vector2, 
				   arrow_penetration: int, arrow_type: ARROW_TYPE = ARROW_TYPE.NORMAL,
				   custom_gravity: float = 0.0, custom_drag: float = 0.0):  # 修改参数名
	damage = arrow_damage
	speed = arrow_speed
	initial_speed = arrow_speed
	direction = arrow_direction
	velocity = direction * speed
	penetration = arrow_penetration
	self.arrow_type = arrow_type
	arrow_gravity = custom_gravity  # 使用重命名的变量
	arrow_drag = custom_drag        # 使用重命名的变量
	
	# 根据箭矢类型设置特殊属性
	match arrow_type:
		ARROW_TYPE.SPLIT:
			can_split = true
			split_count = 3
			split_angle = 30.0
		ARROW_TYPE.EXPLOSIVE:
			explosion_damage = damage * 2
			explosion_radius = 100.0
		ARROW_TYPE.POISON:
			poison_damage = max(1, damage / 2)
			poison_duration = 3.0
	
	# 更新视觉效果颜色
	update_visual_effects()
	update_rotation()

func update_visual_effects():
	if trail_particles and trail_particles.process_material:
		var material = trail_particles.process_material
		material.color = get_arrow_color()

func get_arrow_color() -> Color:
	match arrow_type:
		ARROW_TYPE.NORMAL:
			return Color.WHITE
		ARROW_TYPE.MULTI_SHOT:
			return Color.CYAN
		ARROW_TYPE.SPLIT:
			return Color.YELLOW
		ARROW_TYPE.EXPLOSIVE:
			return Color.ORANGE_RED
		ARROW_TYPE.POISON:
			return Color.PURPLE
	return Color.WHITE

func _on_area_entered(area):
	print("=== 箭矢碰撞检测开始 ===")
	print("箭矢类型: ", ARROW_TYPE.keys()[arrow_type])
	print("箭矢碰撞到区域: ", area.name)
	
	var enemy = detect_enemy(area)
	
	if enemy and enemy not in hit_enemies:
		handle_enemy_hit(enemy)
	
	print("=== 箭矢碰撞检测结束 ===")

func detect_enemy(area) -> Node:
	# 方法1：直接检测区域
	if area.has_method("take_damage"):
		print("通过方法1检测到敌人")
		return area
	
	# 方法2：检测区域的父节点
	if area.get_parent() and area.get_parent().has_method("take_damage"):
		print("通过方法2检测到敌人")
		return area.get_parent()
	
	# 方法3：通过组检测
	if area.is_in_group("enemy"):
		print("通过方法3检测到敌人")
		return area
	
	print("未检测到有效的敌人")
	return null

func handle_enemy_hit(enemy):
	hit_enemies.append(enemy)
	
	# 发射命中信号
	arrow_hit.emit(enemy, damage, arrow_type)
	
	# 应用基础伤害
	enemy.take_damage(damage)
	print("箭矢击中敌人！造成伤害: ", damage, " 穿透剩余: ", penetration - hit_enemies.size())
	
	# 应用特殊效果
	apply_special_effects(enemy)
	
	# 创建命中粒子效果
	create_hit_effect(enemy.global_position)
	
	# 检查特殊机制
	check_special_mechanics(enemy.global_position)
	
	# 检查穿透次数
	if hit_enemies.size() >= penetration:
		cleanup_and_free()

func apply_special_effects(enemy):
	match arrow_type:
		ARROW_TYPE.POISON:
			apply_poison_effect(enemy)
		ARROW_TYPE.EXPLOSIVE:
			# 爆炸效果在check_special_mechanics中处理
			pass

func apply_poison_effect(enemy):
	if enemy.has_method("apply_poison"):
		var poison_data = {
			"damage": poison_damage,
			"duration": poison_duration
		}
		enemy.apply_poison(poison_data)
		print("施加中毒效果: ", poison_damage, " 伤害/秒, 持续 ", poison_duration, " 秒")

func check_special_mechanics(hit_position):
	match arrow_type:
		ARROW_TYPE.SPLIT:
			if can_split:
				split_arrow(hit_position)
				can_split = false
		ARROW_TYPE.EXPLOSIVE:
			create_explosion(hit_position)

func split_arrow(position):
	print("箭矢分裂！分裂数量: ", split_count)
	
	var new_arrows = []
	
	for i in range(split_count):
		var angle = deg_to_rad(-split_angle / 2 + (split_angle / (split_count - 1)) * i)
		var split_direction = direction.rotated(angle)
		
		# 创建分裂箭矢
		var split_arrow = duplicate()
		split_arrow.position = position
		split_arrow.set_properties(
			max(1, damage / 2),  # 分裂箭矢伤害减半
			initial_speed * 0.8, # 分裂箭矢速度降低
			split_direction,
			1,                   # 分裂箭矢无法穿透
			ARROW_TYPE.NORMAL,   # 分裂箭矢变为普通类型
			arrow_gravity,       # 使用重命名的变量
			arrow_drag           # 使用重命名的变量
		)
		
		get_parent().add_child(split_arrow)
		new_arrows.append(split_arrow)
	
	# 发射分裂信号
	arrow_split.emit(self, new_arrows)

func create_explosion(position):
	print("创建爆炸！半径: ", explosion_radius, " 伤害: ", explosion_damage)
	
	# 发射爆炸信号
	arrow_exploded.emit(position, explosion_radius, explosion_damage)
	
	# 检测范围内的敌人
	var explosion_area = get_explosion_area(position)
	var enemies_in_range = explosion_area.get_overlapping_areas()
	
	for area in enemies_in_range:
		var enemy = detect_enemy(area)
		if enemy and enemy not in hit_enemies:
			# 对范围内的敌人造成爆炸伤害
			enemy.take_damage(explosion_damage)
			print("爆炸击中敌人！造成伤害: ", explosion_damage)
	
	# 创建爆炸粒子效果
	create_explosion_effect(position)
	
	# 爆炸后销毁箭矢
	cleanup_and_free()

func get_explosion_area(position) -> Area2D:
	# 创建一个临时区域来检测爆炸范围内的敌人
	var explosion_area = Area2D.new()
	explosion_area.position = position
	explosion_area.collision_layer = 0
	explosion_area.collision_mask = 2
	
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	collision_shape.shape = circle_shape
	
	explosion_area.add_child(collision_shape)
	get_parent().add_child(explosion_area)
	
	# 下一帧移除检测区域
	call_deferred("remove_explosion_area", explosion_area)
	
	return explosion_area

func remove_explosion_area(area):
	if is_instance_valid(area):
		area.queue_free()

func create_hit_effect(position):
	# 创建命中粒子效果
	hit_particles = GPUParticles2D.new()
	hit_particles.position = position
	hit_particles.emitting = true
	hit_particles.one_shot = true
	hit_particles.lifetime = 0.3
	hit_particles.amount = 8
	
	var hit_material = ParticleProcessMaterial.new()
	hit_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	hit_material.spread = 360.0
	hit_material.gravity = Vector3(0, 0, 0)
	hit_material.initial_velocity_min = 20.0
	hit_material.initial_velocity_max = 50.0
	hit_material.color = get_arrow_color()
	hit_particles.process_material = hit_material
	
	get_parent().add_child(hit_particles)
	
	# 设置自动清除
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if is_instance_valid(hit_particles):
			hit_particles.queue_free()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func create_explosion_effect(position):
	# 创建爆炸粒子效果
	explosion_particles = GPUParticles2D.new()
	explosion_particles.position = position
	explosion_particles.emitting = true
	explosion_particles.one_shot = true
	explosion_particles.lifetime = 0.5
	explosion_particles.amount = 32
	explosion_particles.explosiveness = 0.8
	
	var explosion_material = ParticleProcessMaterial.new()
	explosion_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	explosion_material.spread = 360.0
	explosion_material.gravity = Vector3(0, 100, 0)
	explosion_material.initial_velocity_min = 50.0
	explosion_material.initial_velocity_max = 150.0
	explosion_material.color = Color.ORANGE_RED
	explosion_particles.process_material = explosion_material
	
	get_parent().add_child(explosion_particles)
	
	# 设置自动清除
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if is_instance_valid(explosion_particles):
			explosion_particles.queue_free()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func cleanup_and_free():
	# 停止轨迹粒子
	if trail_particles:
		trail_particles.emitting = false
		
		# 延迟清除粒子，让它们自然消失
		var timer = Timer.new()
		timer.wait_time = 1.0
		timer.one_shot = true
		timer.timeout.connect(func(): 
			if is_instance_valid(trail_particles):
				trail_particles.queue_free()
			timer.queue_free()
		)
		add_child(timer)
		timer.start()
	
	queue_free()

# 工具方法
func get_arrow_type_name() -> String:
	return ARROW_TYPE.keys()[arrow_type]

func is_active() -> bool:
	return is_inside_tree() and not has_hit

# 调试方法
func enable_debug_draw():
	debug_draw = true
	queue_redraw()

func disable_debug_draw():
	debug_draw = false
	queue_redraw()
