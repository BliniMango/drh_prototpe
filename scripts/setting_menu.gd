# settings menu
extends Control

@onready var back_button = $VBoxContainer/BackButton
@onready var sfx_label = $VBoxContainer/SFXContainer/SFXLabel
@onready var sfx_slider = $VBoxContainer/SFXContainer/SFXSlider
@onready var music_label = $VBoxContainer/MusicContainer/MusicLabel
@onready var music_slider = $VBoxContainer/MusicContainer/MusicSlider

const SFX_BUS = "sfx"
const MUSIC_BUS = "music"

func _ready():
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)

func _on_sfx_volume_changed(value: float):
	var db_value = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), db_value)
	sfx_label.text = "SFX Volume: " + str(int(value)) + "%"
	save_audio_settings()
	
func _on_music_volume_changed(value: float):
	var db_value = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), db_value)
	sfx_label.text = "Music Volume: " + str(int(value)) + "%"
	save_audio_settings()
	
func save_audio_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.save("user://settings.cfg")

	
func load_audio_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		var sfx_vol = config.get_value("audio", "sfx_volume", 75.0)
		var music_vol = config.get_value("audio", "music_volume", 75.0)
		sfx_slider.value = sfx_vol
		music_slider.value = music_vol
		
		_on_sfx_volume_changed(sfx_vol)
		_on_music_volume_changed(music_vol)
		
	else:
		sfx_slider.value = 75.0
		music_slider.value = 75.0
		_on_music_volume_changed(75.0)
		_on_sfx_volume_changed(75.0)
		
#func _on_back_button_pressed():
	#get_parent()._on_back_button_pressed()
