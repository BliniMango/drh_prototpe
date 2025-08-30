class_name Pickup
extends RigidBody3D

@onready var sprite : Sprite3D = $Sprite3D
@onready var detection_area : Area3D = $Area3D

@export var pickup_type : Type = Type.HEALTH
@export var pickup_value : float = 0.0

@export var health_texture : CompressedTexture2D
@export var pistol_ammo_texture : CompressedTexture2D
@export var shotgun_ammo_texture : CompressedTexture2D
@export var dynamite_texture : CompressedTexture2D
@export var speed_boost_texture : CompressedTexture2D

enum Type {
	HEALTH,
	PISTOL_AMMO,
	SHOTGUN_AMMO,
	DYNAMITE,
	SPEED_BOOST
}

const DEFAULT_VALUES = {
	Type.HEALTH: 25.0,
	Type.PISTOL_AMMO: 12.0,
	Type.SHOTGUN_AMMO: 8.0,
	Type.DYNAMITE: 2.0,
	Type.SPEED_BOOST: 1.5,
}

func _ready() -> void:
	add_to_group("pickup")

	detection_area.area_entered.connect(_on_area_entered)
	pickup_value = DEFAULT_VALUES[pickup_type]
	linear_velocity = Vector3(0, 3, 0)
	update_sprite()

func update_sprite() -> void:
	if not sprite:
		print_debug("Error: sprite is null in update_sprite()")
		return
	match pickup_type:
		Type.HEALTH:
			sprite.texture = health_texture
		Type.PISTOL_AMMO:
			sprite.texture = pistol_ammo_texture
		Type.SHOTGUN_AMMO:
			sprite.texture = shotgun_ammo_texture
		Type.DYNAMITE:
			sprite.texture = dynamite_texture
		Type.SPEED_BOOST:
			sprite.texture = speed_boost_texture

func _on_area_entered(area: Area3D) -> void:
	if area.name == "HurtBox" and area.get_parent().is_in_group("player"):
		SFXManager.play_player_sfx(SFXManager.Type.PLAYER_PICKUP)
		var player = area.get_parent()

		match pickup_type:
			Type.HEALTH:
				player.heal(pickup_value)
				player.update_health_ui()
			Type.PISTOL_AMMO:
				player.revolver.ammo_stock += int(pickup_value)
				player.update_ammo_ui()
			Type.SHOTGUN_AMMO:
				player.shotgun.ammo_stock += int(pickup_value)
				player.update_ammo_ui()
			Type.DYNAMITE:
				for i in range(int(pickup_value)):
					player.throwable_inventory.append(Prefabs.DYNAMITE)
				player.update_dynamite_ui()
			Type.SPEED_BOOST:
				pass
				# TODO?

		player.pickup_flash()
		queue_free()

func set_pickup_type(type: Type) -> void:
	pickup_type = type
	pickup_value = DEFAULT_VALUES[type]
