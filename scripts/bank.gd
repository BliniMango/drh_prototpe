class_name Bank
extends StaticBody3D

signal bank_money_changed(new_amount)
signal bank_destroyed()
signal bank_took_damage(damage_amount, money_lost)

@onready var label_3d: Label3D = $Label3D

@export var starting_money: int = 1000
@export var damage_to_money_ratio: float = 10.0

@export var visual_node: NodePath
@export var jiggle_scale: float = 0.1
@export var jiggle_time: float = 0.12

var bank_money: int
var is_destroyed: bool = false
var _visual: Node3D
var _jiggle_lock := false

func _ready() -> void:
	bank_money = starting_money
	if visual_node != NodePath():
		_visual = get_node_or_null(visual_node)
	GameManager.register_bank(self)
	label_3d.text = "${0}".format([starting_money])


func deposit_money(amount: int) -> bool:
	if is_destroyed: return false
	bank_money += amount
	bank_money_changed.emit(bank_money)
	label_3d.text = "${0}".format([bank_money])
	return true

func withdraw_money(amount: int) -> bool:
	if is_destroyed or amount > bank_money: return false
	bank_money -= amount
	bank_money_changed.emit(bank_money)
	label_3d.text = "${0}".format([bank_money])
	return true

func take_damage(damage: float) -> void:
	if is_destroyed: return
	var money_lost := int(damage * damage_to_money_ratio)
	money_lost = min(money_lost, bank_money)
	bank_money -= money_lost
	SFXManager.play_spatial_sfx(SFXManager.Type.BANK_DAMAGE, global_position)
	bank_took_damage.emit(damage, money_lost)
	bank_money_changed.emit(bank_money)
	label_3d.text = "${0}".format([bank_money])
	_jiggle()

	if bank_money <= 0:
		destroy_bank()

func destroy_bank() -> void:
	is_destroyed = true
	bank_destroyed.emit()

func _jiggle() -> void:
	if _visual == null or _jiggle_lock: return
	_jiggle_lock = true
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	var base := Vector3.ONE
	var big := base * (1.0 + jiggle_scale)
	var small := base * (1.0 - jiggle_scale * 0.5)
	t.tween_property(_visual, "scale", big,   jiggle_time * 0.5)
	t.tween_property(_visual, "scale", small, jiggle_time * 0.5)
	t.tween_property(_visual, "scale", base,  jiggle_time * 0.5)
	await t.finished
	_jiggle_lock = false
