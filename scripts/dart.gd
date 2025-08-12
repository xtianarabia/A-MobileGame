extends Area3D

@export var speed = 20.0
@export var lifespan = 2.0 # seconds

func _ready():
	# Connect the body_entered signal to our handler function
	body_entered.connect(_on_body_entered)
	# Set a timer to delete the dart after its lifespan
	var timer = get_tree().create_timer(lifespan)
	timer.timeout.connect(queue_free)

func _physics_process(delta):
	# Move the dart forward
	global_position -= transform.basis.z * speed * delta

func _on_body_entered(body):
	# Check if the body we hit is an enemy
	if body.is_in_group("enemy"):
		# Call the enemy's choke_out function to disable it
		body.choke_out()

	# The dart should disappear after hitting anything solid, not just enemies.
	# We also check it's not another area or something without collision.
	if body is CollisionObject3D:
		queue_free()
