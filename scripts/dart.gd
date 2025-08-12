extends RigidBody3D

@export var speed = 20.0
@export var lifespan = 3.0 # Increased lifespan for better visibility

func _ready():
	# Set the initial velocity to move the dart forward.
	# -transform.basis.z is the local "forward" direction.
	linear_velocity = -transform.basis.z * speed

	# Connect the body_entered signal to our handler function.
	body_entered.connect(_on_body_entered)

	# Set a timer to delete the dart after its lifespan.
	get_tree().create_timer(lifespan).timeout.connect(queue_free)

func _on_body_entered(body):
	# When the dart hits something...

	# Check if the body we hit is an enemy.
	if body.is_in_group("enemy"):
		# Call the enemy's choke_out function to disable it.
		body.choke_out()

	# The dart should disappear after hitting any solid physics body.
	if body is StaticBody3D or body is CharacterBody3D:
		queue_free()
