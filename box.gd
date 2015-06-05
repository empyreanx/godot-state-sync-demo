extends RigidBody2D

const EVENT_START_DRAG = 0
const EVENT_END_DRAG = 1
const EVENT_DRAGGING = 2

const SCALE_FACTOR = 25

var dragging = false
var host = true;
var stream = null

func _ready():
	set_process_input(true)
	pass

func _input_event(viewport, event, shape_idx):
	if (event.type == InputEvent.MOUSE_BUTTON and event.pressed):
		start_dragging()

func _input(event):
		if (event.type == InputEvent.MOUSE_MOTION and dragging):
			var rect = get_tree().get_root().get_rect()
			var pos = event.pos
			
			if (pos.x <= 0 or pos.y <= 0 or pos.x >= (rect.size.x - 1) or pos.y >= (rect.size.y - 1)):
				stop_dragging()
			else:
				drag(pos)
				
		elif (event.type == InputEvent.MOUSE_BUTTON and not event.pressed and dragging):
			stop_dragging()

func start_dragging():
	dragging = true

	if (host):
		set_gravity_scale(0)
		set_linear_velocity(Vector2(0,0))
		

func stop_dragging():
	dragging = false
	
	if (host):
		set_gravity_scale(1)
		set_applied_force(Vector2(0,0))
	else:
		stream.put_var(["stop_drag", get_name()])

func drag(pos):
	if (host):
		set_applied_force((pos - get_pos()) * SCALE_FACTOR)
	else:
		stream.put_var(["drag", get_name(), pos])