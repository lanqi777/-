extends CanvasLayer

signal class_selected

func _ready():
	show_class_selection()

func show_class_selection():
	var panel = Panel.new()
	panel.size = Vector2(400, 500)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(400, 500)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "选择职业"
	vbox.add_child(title)
	
	create_class_button(vbox, "法师", 0)
	create_class_button(vbox, "剑士", 1)
	create_class_button(vbox, "召唤师", 2)
	create_class_button(vbox, "射手", 3)

func create_class_button(parent, name, type):
	var button = Button.new()
	button.text = name
	button.pressed.connect(_on_button_pressed.bind(type))
	parent.add_child(button)

func _on_button_pressed(class_type):
	class_selected.emit(class_type)
	queue_free()
