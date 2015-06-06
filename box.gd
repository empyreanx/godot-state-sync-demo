extends RigidBody2D

const EVENT_START_DRAG = 0
const EVENT_END_DRAG = 1
const EVENT_DRAGGING = 2

const SCALE_FACTOR = 25

var dragging = false
var host = true;
var packet_peer = null

func _ready():
	set_process_input(true)

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
