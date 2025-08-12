extends Node

# Signal to broadcast a noise event to all listeners (like enemies).
# @param position: Vector3 - The world location where the noise originated.
# @param loudness: float - The distance the noise travels. Enemies farther than this won't hear it.
signal noise_made(position, loudness)

# Call this function from any node that wants to make a noise.
func broadcast_noise(position: Vector3, loudness: float):
	emit_signal("noise_made", position, loudness)
