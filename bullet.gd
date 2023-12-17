extends Area2D

var speed: float = 500  # Bullet speed
var linear_velocity
var damage: int = 10
var parent = null

func _ready():
	# Set the bullet's velocity
	linear_velocity = Vector2(cos(rotation), sin(rotation)) * speed
	var lifetime = 5  # Lifetime of the bullet in seconds
	$Timer.wait_time = lifetime
	$Timer.one_shot = true
	$Timer.start()
	add_to_group("bullet")

func _process(delta):
	# Move the bullet
	translate(linear_velocity * delta)

func _on_Timer_timeout():
	queue_free()  # Remove the bullet from the scene

func _on_body_entered(body):
	# check if the body is in the group "enemy"
	if body.is_in_group("enemy"):
		# if it is, call the function "hit" on the body
		body.hit(self)
		parent.lifetime_damage += damage
		# remove the bullet from the scene
		queue_free()


