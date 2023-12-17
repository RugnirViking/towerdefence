extends CharacterBody2D


@export var speed: float = 8000
var target: Vector2
@export var navigation: NavigationAgent2D
@export var drill: Node2D
var nav_velocity: Vector2
@export var hp_max: int
var hp_current: int

func _ready():
	if drill:
		set_target(drill.global_position)
	
	hp_current = hp_max
	$TextureProgressBar.value = hp_current
	$TextureProgressBar.max_value = hp_max
	$TextureProgressBar.visible = false

func set_target(new_target: Vector2):
	target = new_target
	navigation.set_target_position(target)
	$Line2D.points = navigation.get_current_navigation_path()
	$Line2D.visible = true
	$Timer.start()

func remaining_distance():
	return navigation.distance_to_target()
	
func hit(body):
	if body.is_in_group("bullet"):
		hp_current -= body.damage
		$TextureProgressBar.value = hp_current
		$TextureProgressBar.visible = true
		if hp_current <= 0:
			queue_free()

func _physics_process(delta):
	
	if not navigation.is_navigation_finished():
		var movement_delta = speed * delta
		var current_agent_position = global_position
		var next_path_position = navigation.get_next_path_position()
		
		$Line2D.points = navigation.get_current_navigation_path()
		var intended_velocity = (next_path_position - current_agent_position).normalized() * movement_delta
		velocity = intended_velocity
		
		move_and_slide()
		#navigation.set_velocity(intended_velocity)
	
	# calc distance to target
	var distance_to_target = (target - global_position).length()
	if distance_to_target < 30:
		print("target reached")
		queue_free()



func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()


func _on_timer_timeout():
	# recalculate path
	navigation.set_target_position(target)
