extends Camera3D

# The node that the camera should follow.
@export var target: Node3D
# The offset from the target's position.
@export var offset = Vector3(0, 10, 6)
# How quickly the camera catches up to the target. Lower values are slower/smoother.
@export var smoothness = 0.125

func _physics_process(delta):
	if target:
		# Calculate the desired position of the camera.
		var target_position = target.global_position + offset
		# Smoothly interpolate the camera's position towards the target position.
		global_position = global_position.lerp(target_position, smoothness)
		# Make the camera always look at the player's position.
		look_at(target.global_position)
	else:
		# If no target is set, print a warning.
		push_warning("Camera controller does not have a target set.")
