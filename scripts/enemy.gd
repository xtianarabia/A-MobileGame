extends CharacterBody2D

@export var speed = 75
@export var patrol_distance = 200

var direction = 1
var start_x

func _ready():
    start_x = position.x

func _physics_process(delta):
    velocity.x = direction * speed
    move_and_slide()

    if abs(position.x - start_x) >= patrol_distance:
        direction *= -1
        # To make the patrol exact, clamp the position
        position.x = start_x + patrol_distance * sign(position.x - start_x)
        start_x = position.x
