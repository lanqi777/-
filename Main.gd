extends Node2D

# 玩家数据
var resources: int = 0
var total_damage: int = 0
var click_damage: int = 1
var click_resource: int = 1

# 主角属性
var player_health: int = 100
var player_max_health: int = 100
var player_attack_interval: float = 1.0
var player_damage_per_attack: int = 5

# 经验系统
var experience: int = 0
var experience_multiplier: float = 1.0
var level: int = 1
var exp_to_next_level: int = 10

# 职业系统
enum CLASS {MAGE, WARRIOR, SUMMONER, ARCHER}
var current_class: CLASS = CLASS.MAGE
var player_position: Vector2 = Vector2(400, 300)
var game_started: bool = false

# 职业特定属性
var warrior_damage: int = 5
var summon_count: int = 0
var max_summon_count: int = 3
var summon_duration: float = 10.0
var archer_penetration: int = 1

# 子弹系统
var bullet_scene: PackedScene
var slash_effect_scene: PackedScene
var summon_unit_scene: PackedScene
var archer_arrow_scene: PackedScene

var auto_shoot: bool = false
var shoot_timer: float = 0.0
var shoot_interval: float = 0.5

# 子弹属性
var bullet_damage: int = 1
var bullet_speed: float = 300.0
var bullet_effects: Dictionary = {
	"burn": {"damage": 0, "duration": 0.0},
	"slow": {"factor": 1.0, "duration": 0.0},
	"freeze": false,
	"poison": {"damage": 0, "duration": 0.0}
}

# UI 节点引用
var resources_label: Label
var damage_label: Label
var stats_label: Label
var experience_label: Label
var class_label: Label
var player_health_label: Label

# 敌人生成相关
var enemy_scene: PackedScene
var spawn_timer: Timer
var spawn_interval: float = 3.0

# 主角节点引用
var player_node: Node2D

# 职业选择界面
var class_selection_scene: PackedScene

func _ready():
	# 预加载职业选择界面
	class_selection_scene = preload("res://ClassSelection.tscn")
	
	# 显示职业选择界面
	show_class_selection()
	
	# 先不初始化游戏内容，等待职业选择
	print("等待职业选择...")

func show_class_selection():
	var selection = class_selection_scene.instantiate()
	selection.class_selected.connect(_on_class_selected)
	add_child(selection)

func _on_class_selected(class_type: CLASS):
	current_class = class_type
	game_started = true
	
	# 初始化游戏
	initialize_game()
	
	print("游戏开始！职业: ", get_class_name(current_class))

func initialize_game():
	# 重置游戏状态
	reset_game_state()
	
	# 设置UI和游戏系统
	setup_ui_nodes()
	setup_enemy_spawning()
	setup_bullet_system()
	setup_class_specific_scenes()
	setup_player()
	update_ui()

func reset_game_state():
	resources = 0
	total_damage = 0
	experience = 0
	level = 1
	exp_to_next_level = 10
	player_health = player_max_health
	
	# 清除所有现有的敌人、子弹等
	cleanup_existing_objects()

func cleanup_existing_objects():
	# 清除所有敌人
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_free()
	
	# 清除所有子弹
	for bullet in get_tree().get_nodes_in_group("bullet"):
		bullet.queue_free()
	
	# 清除所有召唤物
	for summon in get_tree().get_nodes_in_group("summon"):
		summon.queue_free()

func setup_enemy_spawning():
	enemy_scene = preload("res://Enemy.tscn")
	
	if spawn_timer and is_instance_valid(spawn_timer):
		spawn_timer.stop()
		spawn_timer.queue_free()
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func setup_bullet_system():
	bullet_scene = preload("res://Bullet/Bullet.tscn")

func setup_class_specific_scenes():
	# 根据职业预加载特定场景
	slash_effect_scene = preload("res://Bullet/SlashEffect.tscn")
	summon_unit_scene = preload("res://Bullet/SummonUnit.tscn")
	archer_arrow_scene = preload("res://Bullet/ArcherArrow.tscn")

func setup_player():
	# 如果主角已存在，先移除
	if player_node and is_instance_valid(player_node):
		player_node.queue_free()
	
	# 创建新主角
	player_node = Node2D.new()
	player_node.name = "Player"
	add_child(player_node)
	
	# 设置主角位置
	var screen_size = get_viewport().get_visible_rect().size
	player_position = Vector2(screen_size.x / 2, screen_size.y - 100)
	player_node.position = player_position
	
	# 添加主角精灵
	var player_sprite = Sprite2D.new()
	var texture = load("res://assets/protagonist.png")
	if not texture:
		texture = create_placeholder_texture()
	
	player_sprite.texture = texture
	player_sprite.scale = Vector2(0.1, 0.1)
	player_node.add_child(player_sprite)
	
	# 添加碰撞区域
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50  # 增大碰撞半径，确保敌人能接触到
	
	var player_area = Area2D.new()
	player_area.name = "PlayerArea"
	player_area.collision_layer = 1  # 主角在第1层
	player_area.collision_mask = 2   # 检测第2层（敌人）
	
	var area_collision = CollisionShape2D.new()
	area_collision.shape = shape
	area_collision.position = Vector2.ZERO
	
	player_area.add_child(area_collision)
	player_node.add_child(player_area)
	
	# 连接信号
	player_area.area_entered.connect(_on_player_area_entered)
	player_area.area_exited.connect(_on_player_area_exited)
	
	# 添加主角血条
	var health_bar = TextureProgressBar.new()
	health_bar.name = "PlayerHealthBar"
	health_bar.max_value = player_max_health
	health_bar.value = player_health
	health_bar.offset_top = -30
	health_bar.offset_right = 40
	health_bar.offset_bottom = -25
	player_node.add_child(health_bar)
	
	# 将主角添加到"player"组
	player_node.add_to_group("player")
	
	print("主角初始化完成，职业: ", get_class_name(current_class))

func create_placeholder_texture() -> Texture2D:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.8, 0.2))
	var texture = ImageTexture.create_from_image(image)
	return texture

func _process(delta):
	if not game_started:
		return
	
	# 自动射击逻辑（仅法师）
	if auto_shoot and current_class == CLASS.MAGE:
		shoot_timer += delta
		if shoot_timer >= shoot_interval:
			shoot_timer = 0.0
			auto_shoot_nearest()

func _on_spawn_timer_timeout():
	if game_started:
		spawn_enemy()

func spawn_enemy():
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		print("生成新的敌人")

func enemy_died(reward_amount: int):
	resources += reward_amount
	var exp_gained = int(1 * experience_multiplier)
	experience += exp_gained
	print("敌人被击败！获得资源: ", reward_amount, " 经验: ", exp_gained)
	
	check_level_up()
	update_ui()

func setup_ui_nodes():
	# 获取或创建UI节点
	resources_label = get_node_or_null("CanvasLayer/ResourcesLabel")
	damage_label = get_node_or_null("CanvasLayer/DamageLabel")
	stats_label = get_node_or_null("CanvasLayer/StatsLabel")
	experience_label = get_node_or_null("CanvasLayer/ExperienceLabel")
	class_label = get_node_or_null("CanvasLayer/ClassLabel")
	
	if resources_label == null or damage_label == null or stats_label == null or experience_label == null or class_label == null:
		create_ui_nodes()

func create_ui_nodes():
	var canvas = get_node_or_null("CanvasLayer")
	if canvas == null:
		canvas = CanvasLayer.new()
		canvas.name = "CanvasLayer"
		add_child(canvas)
	
	# 创建各个UI标签
	var labels = {
		"ResourcesLabel": Vector2(50, 50),
		"DamageLabel": Vector2(50, 90),
		"StatsLabel": Vector2(50, 130),
		"ExperienceLabel": Vector2(50, 170),
		"ClassLabel": Vector2(50, 210),
		"PlayerHealthLabel": Vector2(50, 250)
	}
	
	for label_name in labels:
		if get_node_or_null("CanvasLayer/" + label_name) == null:
			var label = Label.new()
			label.name = label_name
			label.position = labels[label_name]
			label.add_theme_font_size_override("font_size", 20)
			canvas.add_child(label)
	
	# 设置引用
	resources_label = get_node("CanvasLayer/ResourcesLabel")
	damage_label = get_node("CanvasLayer/DamageLabel")
	stats_label = get_node("CanvasLayer/StatsLabel")
	experience_label = get_node("CanvasLayer/ExperienceLabel")
	class_label = get_node("CanvasLayer/ClassLabel")
	player_health_label = get_node("CanvasLayer/PlayerHealthLabel")
	
	# 创建升级按钮
	create_upgrade_buttons()

func create_upgrade_buttons():
	var canvas = get_node("CanvasLayer")
	
	# 基础升级按钮
	var upgrades = [
		{"name": "升级子弹伤害", "cost": 10, "callback": upgrade_bullet_damage},
		{"name": "升级子弹速度", "cost": 15, "callback": upgrade_bullet_speed},
		{"name": "经验倍率+0.1", "cost": 30, "callback": upgrade_experience_multiplier}
	]
	
	# 职业特定升级
	match current_class:
		CLASS.WARRIOR:
			upgrades.append({"name": "剑士伤害+2", "cost": 20, "callback": upgrade_warrior_damage})
		CLASS.SUMMONER:
			upgrades.append({"name": "召唤数量+1", "cost": 25, "callback": upgrade_summon_count})
		CLASS.ARCHER:
			upgrades.append({"name": "穿透次数+1", "cost": 15, "callback": upgrade_archer_penetration})
	
	var y_offset = 300
	for upgrade in upgrades:
		var button = Button.new()
		button.text = upgrade["name"] + " (" + str(upgrade["cost"]) + ")"
		button.position = Vector2(50, y_offset)
		button.pressed.connect(upgrade["callback"])
		canvas.add_child(button)
		y_offset += 40

func _input(event):
	if not game_started:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			on_screen_clicked(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if current_class == CLASS.MAGE:
				auto_shoot = !auto_shoot
				print("自动射击: ", auto_shoot)

func on_screen_clicked(position: Vector2):
	resources += click_resource
	
	match current_class:
		CLASS.MAGE:
			shoot_nearest_enemy(position)
		CLASS.WARRIOR:
			warrior_slash(position)
		CLASS.SUMMONER:
			summon_unit()
		CLASS.ARCHER:
			archer_shoot(position)
	
	update_ui()
	print("点击！获得资源: ", click_resource)

func shoot_nearest_enemy(click_position: Vector2):
	var nearest_enemy = find_nearest_enemy(click_position)
	if nearest_enemy:
		create_bullet(click_position, nearest_enemy)

func warrior_slash(click_position: Vector2):
	var hit_enemy = find_enemy_at_position(click_position, 50.0)
	if hit_enemy:
		create_slash_effect(click_position)
		hit_enemy.take_damage(warrior_damage)
		print("剑士斩击！造成伤害: ", warrior_damage)
	else:
		print("未击中敌人")

func summon_unit():
	if summon_count < max_summon_count:
		var summon = summon_unit_scene.instantiate()
		if summon:
			var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			summon.position = player_node.position + offset
			summon.set_properties(bullet_damage, summon_duration)
			summon.summoner = self
			add_child(summon)
			summon_count += 1
			print("召唤单位！当前召唤物数量: ", summon_count)
	else:
		print("已达到最大召唤数量")

func summon_unit_died():
	summon_count -= 1
	print("召唤物消失，当前召唤物数量: ", summon_count)

func archer_shoot(click_position: Vector2):
	if archer_arrow_scene:
		var arrow = archer_arrow_scene.instantiate()
		if arrow:
			arrow.position = player_node.position
			var direction = (click_position - player_node.position).normalized()
			
			if arrow.has_method("set_properties"):
				arrow.set_properties(bullet_damage, bullet_speed, direction, archer_penetration)
				add_child(arrow)
				print("射手射击！穿透次数: ", archer_penetration)
			else:
				print("错误：箭矢实例没有 set_properties 方法")
				arrow.queue_free()

func auto_shoot_nearest():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		var nearest_enemy = find_nearest_enemy(player_node.position)
		if nearest_enemy:
			create_bullet(player_node.position, nearest_enemy)

func find_nearest_enemy(from_position: Vector2) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest_enemy: Node2D = null
	var min_distance = INF
	
	for enemy in enemies:
		var distance = from_position.distance_to(enemy.position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy

func find_enemy_at_position(position: Vector2, radius: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if position.distance_to(enemy.position) <= radius:
			return enemy
	return null

func create_bullet(start_position: Vector2, target_enemy: Node2D):
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		if bullet and bullet.has_method("set_target"):
			bullet.position = start_position
			bullet.set_target(target_enemy)
			bullet.set_properties(bullet_damage, bullet_speed, bullet_effects)
			add_child(bullet)
			print("子弹创建成功")

func create_slash_effect(position: Vector2):
	if slash_effect_scene:
		var slash = slash_effect_scene.instantiate()
		slash.position = position
		add_child(slash)
		print("创建斩击效果")

func update_ui():
	if resources_label != null:
		resources_label.text = "资源: %d" % resources
	if damage_label != null:
		damage_label.text = "总伤害: %d" % total_damage
	if stats_label != null:
		stats_label.text = "子弹伤害: %d | 点击资源: %d" % [bullet_damage, click_resource]
	if experience_label != null:
		experience_label.text = "等级: %d | 经验: %d/%d (倍率: %.1fx)" % [level, experience, exp_to_next_level, experience_multiplier]
	if class_label != null:
		class_label.text = "职业: %s" % get_class_name(current_class)
	if player_health_label != null:
		player_health_label.text = "主角血量: %d/%d" % [player_health, player_max_health]

func get_class_name(class_type: CLASS) -> String:
	match class_type:
		CLASS.MAGE:
			return "法师"
		CLASS.WARRIOR:
			return "剑士"
		CLASS.SUMMONER:
			return "召唤师"
		CLASS.ARCHER:
			return "射手"
	return "未知"

func check_level_up():
	if experience >= exp_to_next_level:
		level_up()

func level_up():
	level += 1
	experience -= exp_to_next_level
	exp_to_next_level = int(exp_to_next_level * 1.5)
	
	print("升级！当前等级: ", level)
	
	resources += 5
	bullet_damage += 1
	
	check_level_up()
	update_ui()

func upgrade_bullet_damage():
	if resources >= 10:
		resources -= 10
		bullet_damage += 1
		update_ui()

func upgrade_bullet_speed():
	if resources >= 15:
		resources -= 15
		bullet_speed += 50
		update_ui()

func upgrade_experience_multiplier():
	if resources >= 30:
		resources -= 30
		experience_multiplier += 0.1
		update_ui()

func upgrade_warrior_damage():
	if resources >= 20:
		resources -= 20
		warrior_damage += 2
		update_ui()

func upgrade_summon_count():
	if resources >= 25:
		resources -= 25
		max_summon_count += 1
		update_ui()

func upgrade_archer_penetration():
	if resources >= 15:
		resources -= 15
		archer_penetration += 1
		update_ui()

func add_total_damage(damage_amount: int):
	total_damage += damage_amount
	update_ui()

func _on_player_area_entered(area):
	if area.is_in_group("enemy"):
		print("敌人进入主角区域，开始攻击")
		var timer = Timer.new()
		timer.wait_time = player_attack_interval
		timer.one_shot = false
		timer.timeout.connect(_on_player_attacked.bind(area))
		add_child(timer)
		timer.start()
		
		area.set_meta("attack_timer", timer)

func _on_player_area_exited(area):
	if area.is_in_group("enemy"):
		print("敌人离开主角区域，停止攻击")
		var timer = area.get_meta("attack_timer", null)
		if timer and is_instance_valid(timer):
			timer.stop()
			timer.queue_free()

func _on_player_attacked(enemy):
	if player_health > 0 and is_instance_valid(enemy):
		player_health -= player_damage_per_attack
		print("主角受到攻击！剩余血量: ", player_health)
		update_player_health_bar()
		
		#更新UI显示
		update_ui()
		
		var player_sprite = player_node.get_child(0)
		if player_sprite:
			var tween = create_tween()
			tween.tween_property(player_sprite, "modulate", Color.RED, 0.1)
			tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.1)
		
		if player_health <= 0:
			player_died()

func update_player_health_bar():
	var health_bar = player_node.get_node_or_null("PlayerHealthBar")
	if health_bar:
		health_bar.value = player_health

func player_died():
	print("主角死亡！游戏结束")
	
	# 停止所有敌人攻击计时器
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var timer = enemy.get_meta("attack_timer", null)
		if timer and is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	
	# 停止敌人生成
	if spawn_timer and is_instance_valid(spawn_timer):
		spawn_timer.stop()
	
	# 显示游戏结束界面
	show_game_over()

func show_game_over():
	var canvas = get_node("CanvasLayer")
	
	var game_over_panel = Panel.new()
	game_over_panel.size = Vector2(400, 300)
	game_over_panel.position = Vector2(200, 150)
	canvas.add_child(game_over_panel)
	
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(400, 300)
	game_over_panel.add_child(vbox)
	
	# 游戏结束标题
	var title = Label.new()
	title.text = "游戏结束"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 统计信息
	var stats = Label.new()
	stats.text = "最终等级: %d\n总伤害: %d\n获得资源: %d" % [level, total_damage, resources]
	stats.add_theme_font_size_override("font_size", 20)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)
	
	# 重新选择职业按钮
	var restart_button = Button.new()
	restart_button.text = "重新选择职业"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.pressed.connect(restart_game)
	vbox.add_child(restart_button)
	
	# 重置游戏状态
	game_started = false

func restart_game():
	# 清除游戏结束界面
	var canvas = get_node("CanvasLayer")
	for child in canvas.get_children():
		if child is Panel:
			child.queue_free()
	
	# 显示职业选择界面
	show_class_selection()
