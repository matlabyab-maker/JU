extends CharacterBody3D

var speed: float = 34.0
var pitch_rate: float = 0.0
var roll_rate: float = 0.0
var yaw_rate: float = 0.0
var controls: Dictionary = {}

func set_control(action: String, pressed: bool) -> void:
    controls[action] = pressed

func _physics_process(delta: float) -> void:
    var pitch_input := _axis("up", "down", KEY_W, KEY_S, KEY_UP, KEY_DOWN)
    var roll_input := _axis("right", "left", KEY_D, KEY_A, KEY_RIGHT, KEY_LEFT)
    var throttle := _axis("faster", "slower", KEY_SHIFT, KEY_CTRL, KEY_NONE, KEY_NONE)
    speed = clamp(speed + throttle * 18.0 * delta, 16.0, 78.0)
    # Aircraft forward is local -Z. Bank into turns and let pitch change altitude.
    rotation.x = clamp(rotation.x + pitch_input * 0.42 * delta, -0.62, 0.62)
    rotation.z = lerp(rotation.z, -roll_input * 0.58, 2.2 * delta)
    rotation.y += -roll_input * 0.28 * delta
    var forward := -global_basis.z
    velocity = forward * speed + Vector3(0, sin(rotation.x) * speed * 0.42, 0)
    move_and_slide()
    # Gentle gravity-like sink when nearly stalled.
    if speed < 22.0:
        position.y -= 5.0 * delta
    position.y = max(position.y, 8.0)

func _axis(positive_action: String, negative_action: String, key_positive: Key, key_negative: Key, key_alt_positive: Key, key_alt_negative: Key) -> float:
    var result := 0.0
    if controls.get(positive_action, false) or Input.is_key_pressed(key_positive) or (key_alt_positive != KEY_NONE and Input.is_key_pressed(key_alt_positive)):
        result += 1.0
    if controls.get(negative_action, false) or Input.is_key_pressed(key_negative) or (key_alt_negative != KEY_NONE and Input.is_key_pressed(key_alt_negative)):
        result -= 1.0
    return result
