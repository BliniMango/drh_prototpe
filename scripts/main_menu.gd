# mainmenu
extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var setting_menu = $SettingMenu

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# settings visability
	setting_menu.visible = false

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_settings_button_pressed():
	setting_menu.visible = true

func _on_quit_button_pressed():
	get_tree().quit()

func _on_back_button_pressed():
	setting_menu.visible = false
