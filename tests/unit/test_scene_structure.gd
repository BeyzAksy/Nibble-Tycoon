## test_scene_structure.gd
## Tüm UI sahnelerinin node hiyerarşisini ve script path eşleşmesini doğrular.
## Hem script→tscn (referans edilen node var mı) hem tscn→script
## (kritik node referans edilmiş mi) yönünde kontrol eder.

extends GutTest

var _node : Node = null


func after_each() -> void:
	if _node:
		_node.queue_free()
		_node = null


# ══════════════════════════════════════════════════════════════════════════════
# CUSTOMER NODE
# ══════════════════════════════════════════════════════════════════════════════

func test_customer_node_loads() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node)


func test_customer_node_direct_child_count() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_eq(_node.get_child_count(), 4,
		"CustomerNode: 4 direct children (Sprite, OrderBubble, PatienceBarContainer, EmotionLabel)")


func test_customer_node_sprite() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("Sprite"))


func test_customer_node_order_bubble() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble"))


func test_customer_node_bubble_bg() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble/BubbleBG"))


func test_customer_node_hbox() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble/BubbleBG/HBox"))


func test_customer_node_status_icon() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble/BubbleBG/HBox/StatusIcon"))


func test_customer_node_timer_label() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("OrderBubble/BubbleBG/HBox/TimerLabel"))


func test_customer_node_patience_bar_container() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("PatienceBarContainer"))


func test_customer_node_queue_bar() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("PatienceBarContainer/QueueBar"))


func test_customer_node_food_bar() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("PatienceBarContainer/FoodBar"))


func test_customer_node_emotion_label() -> void:
	_node = load("res://scenes/CustomerNode.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("EmotionLabel"))


# ══════════════════════════════════════════════════════════════════════════════
# HUD BAR
# ══════════════════════════════════════════════════════════════════════════════

func test_hudbar_loads() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node)


## script→tscn: HUDBar.gd @onready path'leri
func test_hudbar_coin_label() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/CoinChip/CoinHBox/CoinLabel"))


func test_hudbar_gem_label() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/GemChip/GemHBox/GemLabel"))


func test_hudbar_level_label() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/LevelBadge/LvHBox/LevelLabel"))


func test_hudbar_xp_level_lbl() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/LevelBadge/LvHBox/XPVBox/XPLbl"))


func test_hudbar_xp_bar() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/LevelBadge/LvHBox/XPVBox/XPBar"))


func test_hudbar_settings_btn() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/SettingsBtn"))


func test_hudbar_coin_chip() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/CoinChip"))


func test_hudbar_boost_badge() -> void:
	_node = load("res://scenes/ui/HUDBar.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("BoostBadge"))


# ══════════════════════════════════════════════════════════════════════════════
# WELCOME MODAL
# ══════════════════════════════════════════════════════════════════════════════

func test_welcome_modal_loads() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node)


## script→tscn: WelcomeModal.gd @onready path'leri
func test_welcome_modal_chef_label() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/ChefLabel"))


func test_welcome_modal_title_label() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/TitleLabel"))


func test_welcome_modal_sub_label() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/SubLabel"))


func test_welcome_modal_amount_label() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/AmountBox/VBox2/AmountLabel"))


func test_welcome_modal_amount_sub_label() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/AmountBox/VBox2/AmountSubLabel"))


func test_welcome_modal_storage_warn() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/StorageWarnLabel"))


func test_welcome_modal_xp_bar() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/XPBar"))


func test_welcome_modal_xp_left_label() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/XPLabels/LeftLabel"))


func test_welcome_modal_xp_right_label() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/XPLabels/RightLabel"))


func test_welcome_modal_collect_btn() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/CollectBtn"))


func test_welcome_modal_watch_ad_btn() -> void:
	_node = load("res://scenes/ui/WelcomeModal.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("ModalPanel/VBox/WatchAdBtn"))


# ══════════════════════════════════════════════════════════════════════════════
# BOTTOM NAV
# ══════════════════════════════════════════════════════════════════════════════

func test_bottom_nav_loads() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node)


func test_bottom_nav_tab_count() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	var hbox := _node.get_node_or_null("HBox")
	assert_not_null(hbox)
	assert_eq(hbox.get_child_count(), 4,
		"HBox must have 4 tabs: Restaurant, Menu, Upgrade, Achievement")


## script→tscn: BottomNav.gd @onready path'leri
func test_bottom_nav_tab_restaurant() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/TabRestaurant"))


func test_bottom_nav_tab_menu() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/TabMenu"))


func test_bottom_nav_tab_upgrade() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/TabUpgrade"))


func test_bottom_nav_tab_achievement() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/TabAchievement"))


func test_bottom_nav_upgrade_dot() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	assert_not_null(_node.get_node_or_null("HBox/TabUpgrade/NewDot"))


## tscn→script: TabRestoran/TabBasarim (Turkish) adı kalmamış olmalı
func test_bottom_nav_no_turkish_tab_restoran() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	assert_null(_node.get_node_or_null("HBox/TabRestoran"),
		"TabRestoran must be renamed to TabRestaurant")


func test_bottom_nav_no_turkish_tab_basarim() -> void:
	_node = load("res://scenes/ui/BottomNav.tscn").instantiate()
	add_child_autofree(_node)
	assert_null(_node.get_node_or_null("HBox/TabBasarim"),
		"TabBasarim must be renamed to TabAchievement")
