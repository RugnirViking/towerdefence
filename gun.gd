extends Node2D

@export var gun: Sprite2D
@export var bullet: PackedScene
@export var damge: int
@export var firing_interval: float
@export var range: int
@export var bulletSize: float
@export var bulletColor: Color
var lockedEnemy: Node2D = null
var selected: bool
var bullet_speed = 500
var lifetime_damage = 0
var lifetime_engage_time: float = 0
var lifetime: float = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	$shotTimer.wait_time = firing_interval
	$shotTimer.start()
	selected = false

func get_radius():
	return range

func sort_by_distance(a: Node2D, b: Node2D) -> int:
	if a.remaining_distance() < b.remaining_distance():
		return true
	return false

	
func _process(delta):
	lifetime += delta
	var enemies = get_tree().get_nodes_in_group("enemy")
	# put all enemies in range in a list then sort by distance
	var enemiesInRange = []
	for enemy in enemies:
		if get_global_position().distance_to(enemy.get_global_position()) < get_radius():
			enemiesInRange.append(enemy)
		else:
			lockedEnemy = null
	
	if enemiesInRange.size() > 0:
		enemiesInRange.sort_custom(sort_by_distance)
		lockedEnemy = enemiesInRange[0] 

	if lockedEnemy != null:
		lifetime_engage_time += delta
		$shotTimer.paused = false
		var target_position = predict_intersection(lockedEnemy, delta)
		gun.look_at(target_position)
		gun.rotate(deg_to_rad(90))
	else:
		gun.look_at(get_global_mouse_position())
		gun.rotate(deg_to_rad(90))
		$shotTimer.paused = true

func predict_intersection(enemy: Node2D, delta: float) -> Vector2:
	var future_position = enemy.get_global_position()
	var time_to_impact = get_global_position().distance_to(future_position) / bullet_speed
	var iteration_count = 0

	while iteration_count < 5:  # Limit iterations to prevent infinite loops
		future_position = enemy.get_global_position() + enemy.velocity * time_to_impact
		time_to_impact = get_global_position().distance_to(future_position) / bullet_speed
		iteration_count += 1

	return future_position



func _on_shot_timer_timeout():
	# create a bullet
	var bullet_instance = bullet.instantiate()
	# set the bullet's position to the gun's position
	bullet_instance.set_global_position(gun.get_global_position())
	# set the bullet's rotation to the gun's rotation
	bullet_instance.set_rotation(gun.get_rotation()-deg_to_rad(90))
	# set the bullet's color
	bullet_instance.set_modulate(bulletColor)
	# set the bullet's size
	bullet_instance.set_scale(Vector2(bulletSize, bulletSize))
	# set the bullet's damage
	bullet_instance.damage = damge
	# set the bullet's parent
	bullet_instance.parent = self
	# add it to the scene
	get_parent().add_child(bullet_instance)
	# start the shot timer again
	$shotTimer.start()

func _draw():
	if selected:
		draw_circle(Vector2(0,0), get_radius(), Color(1,0,0,0.2))

func set_selected(value):
	selected = value
	# trigger redraw
	queue_redraw()
