extends Node

enum Type {
	# not-spatial
	PLAYER_REVOLVER_SHOOT,
	PLAYER_SHOTGUN_SHOOT,
	PLAYER_DASH,
	PLAYER_HURT,
	PLAYER_DIE,
	PLAYER_BULLET_HIT,
	PLAYER_PICKUP,
	PLAYER_RELOAD,
	PLAYER_WEAPON_SWAP,
	WAVE_START,
	SHOP_TIMER,
	CASHOUT,
	NO_AMMO,

	# spatial
	BRUTE_ATTACK,
	BRUTE_DIE,
	BRUTE_HURT,

	GUNNER_SHOOT,
	GUNNER_DIE,
	GUNNER_HURT,

	BOMBER_THROW,
	BOMBER_DIE,
	BOMBER_HURT,

	EXPLOSION,
	FUSE
}

@onready var player_audio = {
	Type.PLAYER_REVOLVER_SHOOT: $PlayerRevolverShoot,
	Type.PLAYER_SHOTGUN_SHOOT: $PlayerShotgunShoot,
	Type.PLAYER_DASH: $PlayerDash,
	Type.PLAYER_HURT: $PlayerHurt,
	Type.PLAYER_DIE: $PlayerDie,
	Type.PLAYER_BULLET_HIT: $PlayerBulletHit,
	Type.PLAYER_PICKUP: $PlayerPickup,
	Type.PLAYER_RELOAD: $PlayerReload,
	Type.PLAYER_WEAPON_SWAP: $PlayerWeaponSwap,
	Type.WAVE_START: $WaveStart,
	Type.SHOP_TIMER: $ShopTimer,
	Type.CASHOUT: $Cashout,
	Type.NO_AMMO: $NoAmmo,
}

@onready var spatial_audio = {
	Type.BRUTE_ATTACK: $BruteAttack,
	Type.BRUTE_DIE: $BruteDie,
	Type.BRUTE_HURT: $BruteHurt,
	Type.GUNNER_SHOOT: $GunnerShoot,
	Type.GUNNER_DIE: $GunnerDie,
	Type.GUNNER_HURT: $GunnerHurt,
	Type.BOMBER_THROW: $BomberThrow,
	Type.BOMBER_DIE: $BomberDie,
	Type.BOMBER_HURT: $BomberHurt,
	Type.EXPLOSION: $Explosion,
	Type.FUSE: $Fuse,
}

func play_player_sfx(sfx_type: Type, volume: float = 0.0) -> void:
	if player_audio.has(sfx_type):
		var player = player_audio[sfx_type]
		player.volume_db = volume
		player.play()

func play_spatial_sfx(sfx_type: Type, world_position: Vector3, volume: float = 0.0) -> void:
	if spatial_audio.has(sfx_type):
		var player = spatial_audio[sfx_type]
		player.global_position = world_position
		player.volume_db = volume
		player.play()

func stop_player_sfx(sfx_type: Type) -> void:
	if player_audio.has(sfx_type):
		var p: AudioStreamPlayer = player_audio[sfx_type]
		if p.playing:
			p.stop()
