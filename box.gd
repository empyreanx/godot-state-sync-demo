extends RigidBody2D

const EVENT_START_DRAG = 0
const EVENT_END_DRAG = 1
const EVENT_DRAGGING = 2

const ALPHA = 0.1
const EPSILON = 0.0005
const SCALE_FACTOR = 25

var dragging = false
var host = true;
var packet_peer = null

var box_state = null

func _ready():
	set_process_input(true)
	set_fixed_process(true)
	
#func _integrate_forces(s):
#	if (not host and box_state != null):
#		var transform = s.get_transform()
#		var pos = lerp_pos(transform.get_origin(), box_state[0], 1.0 - ALPHA)
#		var rot = slerp_rot(transform.get_rotation(), box_state[1], ALPHA)
#		s.set_transform(Matrix32(rot, pos))
#		s.set_linear_velocity(box_state[2])
#		s.set_angular_velocity(box_state[3])

func _fixed_process(delta):
	if (not host and box_state != null):
		var pos = lerp_pos(get_pos(), box_state[0], 1.0 - ALPHA)
		var rot = slerp_rot(get_rot(), box_state[1], ALPHA)
		set_pos(pos)
		set_rot(rot)
		set_linear_velocity(box_state[2])
		set_angular_velocity(box_state[3])

func _input_event(viewport, event, shape_idx):
	if (event.type == InputEvent.MOUSE_BUTTON and event.pressed):
		dragging = true
		start_drag()
		broadcast(["event", "start_drag", get_name()])

func _input(event):
	if (event.type == InputEvent.MOUSE_MOTION and dragging):
		var rect = get_tree().get_root().get_rect()
		var pos = event.pos
		
		if (pos.x <= 0 or pos.y <= 0 or pos.x >= (rect.size.x - 1) or pos.y >= (rect.size.y - 1)):
			dragging = false
			stop_drag()
			broadcast(["event", "stop_drag", get_name()])
		else:
			drag(pos)
			broadcast(["event", "drag", get_name(), pos])
			
	elif (event.type == InputEvent.MOUSE_BUTTON and not event.pressed and dragging):
		dragging = false
		stop_drag()
		broadcast(["event", "stop_drag", get_name()])

func start_drag():
	set_gravity_scale(0)
	set_linear_velocity(Vector2(0,0))

func stop_drag():
	set_gravity_scale(1)
	set_applied_force(Vector2(0,0))

func drag(pos):
	set_applied_force((pos - get_pos()) * SCALE_FACTOR)

func broadcast(packet):
	if (host):
		get_node("/root/demo").broadcast(packet)
	else:
		packet_peer.put_var(packet)

func set_box_state(box_state):
	self.box_state = box_state
	
# Lerp vector
func lerp_pos(v1, v2, alpha):
	return v1 * alpha + v2 * (1.0 - alpha)

# Spherically linear interpolation of rotation
func slerp_rot(r1, r2, alpha):
	var v1 = Vector2(cos(r1), sin(r1))
	var v2 = Vector2(cos(r2), sin(r2))
	var v = slerp(v1, v2, alpha)
	return atan2(v.y, v.x)

# Spherical linear interpolation of two 2D vectors
func slerp(v1, v2, alpha):
	var cos_angle = clamp(v1.dot(v2), -1.0, 1.0)
	
	if (cos_angle > 1.0 - EPSILON):
		return lerp_pos(v1, v2, alpha).normalized()
	
	var angle = acos(cos_angle)
	var angle_alpha = angle * alpha
	var v3 = (v2 - (cos_angle * v1)).normalized()
	return v1 * cos(angle_alpha) + v3 * sin(angle_alpha)
