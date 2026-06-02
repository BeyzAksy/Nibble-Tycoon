## test_scene_structure.gd
## .tscn dosyalarının node hiyerarşisini doğrular.
## Godot parser'ının ## yorumları veya UID bozukluğu nedeniyle
## node'ları sessizce düşürmesini yakalar.

extends GutTest

var _node : Node = null


func after_each() -> void:
	if _node:
		_node.queue_free()
		_node = null


# ── CUSTOMER NODE ─────────────────────────────────────────────────────────────

func test_customer_node_scene_loads() -> void:
	var scene : PackedScene = load("res://scenes/CustomerNode.tscn")
	assert_not_null(scene, "CustomerNode.tscn must load")
	_node = scene.instantiate()
	assert_not_null(_node, "CustomerNode must instantiate")
	add_child_autofree(_node)


func test_customer_node_order_bubble_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble"),
		"OrderBubble must exist as direct child")


func test_customer_node_bubble_bg_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble/BubbleBG"),
		"BubbleBG must be nested under OrderBubble")


func test_customer_node_hbox_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble/BubbleBG/HBox"),
		"HBox must be nested under OrderBubble/BubbleBG")


func test_customer_node_status_icon_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble/BubbleBG/HBox/StatusIcon"),
		"StatusIcon must exist at full path")


func test_customer_node_timer_label_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble/BubbleBG/HBox/TimerLabel"),
		"TimerLabel must exist at full path")


func test_customer_node_patience_bar_container_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("PatienceBarContainer"),
		"PatienceBarContainer must exist")


func test_customer_node_queue_bar_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("PatienceBarContainer/QueueBar"),
		"QueueBar must be child of PatienceBarContainer")


func test_customer_node_food_bar_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("PatienceBarContainer/FoodBar"),
		"FoodBar must be child of PatienceBarContainer")


func test_customer_node_emotion_label_exists() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("EmotionLabel"),
		"EmotionLabel must exist as direct child")


func test_customer_node_child_count_at_root() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	## Beklenen direkt çocuklar: Sprite, OrderBubble, PatienceBarContainer, EmotionLabel
	assert_eq(_node.get_child_count(), 4,
		"CustomerNode must have exactly 4 direct children")
