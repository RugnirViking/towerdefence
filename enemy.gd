extends CharacterBody2D


@export var speed: float = 8000
var target: Vector2
@export var navigation: NavigationAgent2D
@export var drill: Node2D
var nav_velocity: Vector2
@export var hp_max: int
@export var money_drop_base: int
var hp_current: int
var ded: bool = false
var world: Node2D
var lifetime: float

func _ready():
	lifetime = 0
	if drill:
		set_target(drill.global_position)
	
	hp_current = hp_max
	$TextureProgressBar.value = hp_current
	$TextureProgressBar.max_value = hp_max
	$TextureProgressBar.visible = false
	
	$Label.visible=false

func set_target(new_target: Vector2):
	target = new_target
	navigation.set_target_position(target)
	$Line2D.points = navigation.get_current_navigation_path()
	$Line2D.visible = true
	$Timer.start()

func remaining_distance():
	return navigation.distance_to_target()
	
func _deth() -> void:
	queue_free()
func hit(body):
	if not ded:
		if body.is_in_group("bullet"):
			hp_current -= body.damage
			$TextureProgressBar.value = hp_current
			$TextureProgressBar.visible = true
			if hp_current <= 0:
				$Sprite2D.visible=false
				$DeathParticles.visible=true
				$DeathParticles.emitting=true
				$DeathParticles.restart()
				var deathTimer = Timer.new()
				deathTimer.set_wait_time(2)
				deathTimer.set_one_shot(true)
				deathTimer.connect("timeout", _deth)
				# remove self from the enemies group
				remove_from_group("enemies")
				# hide the health bar
				$TextureProgressBar.visible = false
				world.add_money(money_drop_base)
				$Label.text = str(money_drop_base)+" $"
				$Label.visible=true
				add_child(deathTimer)
				deathTimer.start()
				ded = true
			
			

func _physics_process(delta):
	lifetime += delta
	if not ded:
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
	else:
		$Label.position.y-=100*delta
		$Label.position.x = sin(lifetime*2)*15
		



func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()


func _on_timer_timeout():
	# recalculate path
	navigation.set_target_position(target)
