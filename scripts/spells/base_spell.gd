extends Area3D
## Base spell class. All spell projectiles extend this.
## Movement, collision, impact effects, and cleanup are handled here.

signal spell_hit(target: Node, position: Vector3)

@export var damage: float = 15.0
@export var speed: float = 18.0
@export var lifetime: float = 4.0
@export var spell_color: Color = Color(0.3, 0.9, 0.3)
@export var impact_radius: float = 0.0  # 0 = single target, >0 = AoE

var direction: Vector3 = Vector3.FORWARD
var _spell_power_mult: float = 1.0
var _active: bool = true
var _age: float = 0.0


func initialize(dir: Vector3, spell_power: float) -> void:
	direction = dir.normalized()
	_spell_power_mult = spell_power
	look_at(global_position + direction, Vector3.UP)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_age += delta
	if _age >= lifetime:
		_expire()
		return
	global_position += direction * speed * delta
	_on_update(delta)


func _on_update(_delta: float) -> void:
	pass  # Override in subclass for per-frame effects


func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body.is_in_group("player"):
		return
	if body.is_in_group("spells"):
		return
	_impact(body)


func _on_area_entered(area: Node) -> void:
	if not _active:
		return
	if area.is_in_group("spells"):
		return
	_impact(area)


func _impact(target: Node) -> void:
	_active = false
	spell_hit.emit(target, global_position)
	_deal_damage(target)
	_spawn_impact_effect()
	_expire()


func _deal_damage(target: Node) -> void:
	var final_damage := damage * _spell_power_mult
	if impact_radius > 0.0:
		# AoE – hit all enemies in radius
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_to(enemy.global_position) <= impact_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(final_damage)
	else:
		if target.has_method("take_damage"):
			target.take_damage(final_damage)


func _spawn_impact_effect() -> void:
	var particles := GPUParticles3D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 20
	particles.lifetime = 0.6
	particles.fixed_fps = 30
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.15
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.gravity = Vector3(0, -4, 0)
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0
	pm.scale_min = 0.06
	pm.scale_max = 0.14
	pm.color = spell_color
	particles.process_material = pm
	get_tree().create_timer(1.5).timeout.connect(particles.queue_free)


func _expire() -> void:
	set_physics_process(false)
	hide()
	get_tree().create_timer(0.1).timeout.connect(queue_free)
