extends CharacterBody3D

@export var speed = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
    # Apply gravity.
    if not is_on_floor():
        velocity.y -= gravity * delta

    # Use Godot's built-in input handling for arrow keys.
    var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

    # Apply direction to velocity.
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    move_and_slide()
