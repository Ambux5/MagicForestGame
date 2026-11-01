extends Node3D
## Healing Spell – instantaneous heal that spawns on the player position.
## Not a projectile; plays an effect and heals directly.

@export var heal_amount: float = 35.0
@export var mana_cost: float = 20.0

var direction: Vector3 = Vector3.ZERO
var _spell_power_mult: float = 1.0


func initialize(dir: Vector3, spell_power: float) -> void:
	direction = dir
	_spell_power_mult = spell_power


func _ready() -> void:
	var final_heal := heal_amount * _spell_power_mult
	GameManager.heal(final_heal)
	AudioManager.play_sfx("healing")
	_spawn_effect()
	get_tree().create_timer(1.5).timeout.connect(queue_free)


func _spawn_effect() -> void:
	# Rising green healing particles around the player
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.2
	particles.amount = 24
	particles.lifetime = 1.2
	particles.fixed_fps = 30
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.5
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 40.0
	pm.gravity = Vector3(0, 1.5, 0)
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 2.0
	pm.scale_min = 0.06
	pm.scale_max = 0.14
	pm.color = Color(0.3, 1.0, 0.4, 0.85)
	particles.process_material = pm
	add_child(particles)

	# Green glow flash
	var light := OmniLight3D.new()
	light.light_color = Color(0.2, 1.0, 0.3)
	light.light_energy = 3.0
	light.omni_range = 3.0
	add_child(light)
	get_tree().create_timer(0.3).timeout.connect(light.queue_free)
