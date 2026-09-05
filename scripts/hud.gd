# hud.gd
extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/VBox/TopRow/Bars/HPBar
@onready var mp_bar: ProgressBar = $MarginContainer/VBox/TopRow/Bars/MPBar
@onready var hp_label: Label = $MarginContainer/VBox/TopRow/Bars/HPBar/HPLabel
@onready var mp_label: Label = $MarginContainer/VBox/TopRow/Bars/MPBar/MPLabel
@onready var hero_name_lbl: Label = $MarginContainer/VBox/TopRow/HeroInfo/HeroName
@onready var gold_label: Label = $MarginContainer/VBox/TopRow/Stats/GoldLabel
@onready var level_label: Label = $MarginContainer/VBox/TopRow/Stats/LevelLabel
@onready var game_over_panel: Panel = $GameOverPanel

var hero_names = ["Knight (Paladin)", "Mage (Arch-Wizard)", "Rogue (Shadow Blade)", "Cleric (High Priest)"]

func _ready() -> void:
	game_over_panel.visible = false

func update_stats(hp: int, max_hp: int, mp: int, max_mp: int, hero_idx: int, gold: int, level: int, xp: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	if mp_bar:
		mp_bar.max_value = max_mp
		mp_bar.value = mp
	if hp_label:
		hp_label.text = "HP: %d / %d" % [hp, max_hp]
	if mp_label:
		mp_label.text = "MP: %d / %d" % [mp, max_mp]
	if hero_name_lbl:
		hero_name_lbl.text = hero_names[hero_idx % hero_names.size()]
	if gold_label:
		gold_label.text = "Gold: %d G" % gold
	if level_label:
		level_label.text = "Lv. %d (XP: %d)" % [level, xp]

func show_game_over() -> void:
	game_over_panel.visible = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
