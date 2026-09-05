# mmo_hud.gd
# AAA Glassmorphic MMORPG HUD for Chronicles of Midgard
extends CanvasLayer

signal skill_cast(slot_idx: int)
signal potion_used(type: String)
signal stat_allocated(stat_name: String)

@onready var hp_bar: ProgressBar = $TopBar/PlayerStatus/VBox/HPBar
@onready var mp_bar: ProgressBar = $TopBar/PlayerStatus/VBox/MPBar
@onready var exp_bar: ProgressBar = $TopBar/PlayerStatus/VBox/EXPBar
@onready var jobexp_bar: ProgressBar = $TopBar/PlayerStatus/VBox/JobEXPBar
@onready var hero_name_lbl: Label = $TopBar/PlayerStatus/VBox/HeroMeta/HeroName
@onready var hero_job_lbl: Label = $TopBar/PlayerStatus/VBox/HeroMeta/HeroJob
@onready var lvl_badge: Label = $TopBar/PlayerStatus/AvatarOrb/LvlBadge
@onready var gold_lbl: Label = $TopBar/PlayerStatus/VBox/GoldLabel
@onready var target_frame: PanelContainer = $TopBar/TargetFrame
@onready var target_name: Label = $TopBar/TargetFrame/HBox/VBox/TargetName
@onready var target_element: Label = $TopBar/TargetFrame/HBox/VBox/TargetElement
@onready var target_hp_bar: ProgressBar = $TopBar/TargetFrame/HBox/VBox/TargetHPBar

@onready var inv_window: Panel = $Windows/InventoryWindow
@onready var stats_window: Panel = $Windows/StatsWindow
@onready var skills_window: Panel = $Windows/SkillsWindow
@onready var party_window: Panel = $Windows/PartyWindow
@onready var map_window: Panel = $Windows/MapWindow

@onready var chat_messages: RichTextLabel = $BottomHUD/ChatBox/VBox/ChatMessages
@onready var chat_input: LineEdit = $BottomHUD/ChatBox/VBox/HBox/ChatInput
@onready var emote_bar: PanelContainer = $EmoteBar

var unassigned_stat_pts: int = 15
var stats = { "str": 32, "agi": 28, "vit": 40, "int": 20, "dex": 25, "luk": 18 }

func _ready() -> void:
	target_frame.visible = false
	inv_window.visible = false
	stats_window.visible = false
	skills_window.visible = false
	party_window.visible = false
	map_window.visible = false
	emote_bar.visible = false
	
	add_chat_msg("[color=#fbbf24]⚔️ Welcome to Chronicles of Midgard![/color]")
	add_chat_msg("[color=#38bdf8]🌟 Press [I] for Inventory, [C] for Stats, [K] for Skills, [P] for Party, [M] for Map.[/color]")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if chat_input.has_focus():
			if event.keycode == KEY_ESCAPE:
				chat_input.release_focus()
			return

		match event.keycode:
			KEY_I:
				inv_window.visible = !inv_window.visible
			KEY_C:
				stats_window.visible = !stats_window.visible
				update_stats_display()
			KEY_K:
				skills_window.visible = !skills_window.visible
			KEY_P:
				party_window.visible = !party_window.visible
			KEY_M:
				map_window.visible = !map_window.visible
			KEY_ENTER:
				chat_input.grab_focus()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
				var slot = event.keycode - KEY_1 + 1
				skill_cast.emit(slot)
			KEY_F1:
				potion_used.emit("hp")
			KEY_F2:
				potion_used.emit("mp")
			KEY_F3:
				potion_used.emit("ygg")
			KEY_F4:
				potion_used.emit("speed")

func update_stats(hp: int, max_hp: int, mp: int, max_mp: int, hero_idx: int, gold: int, level: int, xp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	mp_bar.max_value = max_mp
	mp_bar.value = mp
	exp_bar.max_value = 100
	exp_bar.value = xp % 100
	jobexp_bar.value = 45
	
	lvl_badge.text = "Lv. " + str(level)
	gold_lbl.text = "💰 " + str(gold) + " G"

func update_target(enemy_name: String, elem: String, cur_hp: int, max_m_hp: int) -> void:
	target_frame.visible = true
	target_name.text = enemy_name
	target_element.text = elem
	target_hp_bar.max_value = max_m_hp
	target_hp_bar.value = cur_hp

func hide_target() -> void:
	target_frame.visible = false

func add_chat_msg(text: String) -> void:
	chat_messages.append_text(text + "\n")

func _on_chat_input_submitted(new_text: String) -> void:
	if new_text.strip_edges() != "":
		add_chat_msg("[color=#e2e8f0][You]: " + new_text + "[/color]")
		chat_input.clear()
	chat_input.release_focus()

func update_stats_display() -> void:
	var pts_lbl = stats_window.get_node_or_null("VBox/HeaderRow/PointsValue")
	if pts_lbl:
		pts_lbl.text = str(unassigned_stat_pts)

func _on_add_stat_pressed(stat_name: String) -> void:
	if unassigned_stat_pts > 0:
		unassigned_stat_pts -= 1
		stats[stat_name] += 1
		stat_allocated.emit(stat_name)
		update_stats_display()

func show_game_over() -> void:
	add_chat_msg("[color=#f43f5e]💀 You fell in battle! Press [R] to revive.[/color]")
