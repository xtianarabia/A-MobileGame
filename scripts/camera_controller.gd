extends Camera3D

# A path to the node that the camera should follow.
@export var target_path: NodePath
# The actual target node.
var target: Node3D

# The offset from the target's position.
@export var offset = Vector3(0, 10, 6)
# How quickly the camera catches up to the target. Lower values are slower/smoother.
@export var smoothness = 0.125

func _ready():
	# Find the target node at runtime.
	if target_path:
		target = get_node(target_path)

	if not target:
		push_error("Camera controller could not find target node at path: " + str(target_path))

func _physics_process(delta):
	if target:
		# Calculate the desired position of the camera.
		var target_position = target.global_position + offset
		# Smoothly interpolate the camera's position towards the target position.
		global_position = global_position.lerp(target_position, smoothness)
		# Make the camera always look at the player's position.
		look_at(target.global_position)
