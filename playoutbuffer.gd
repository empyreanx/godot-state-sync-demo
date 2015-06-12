const BUFFERING = 0
const PLAYING = 1

var state = BUFFERING
var delay = 0.0
var rate = 0.0
var time = 0.0
var last_pull_time = 0.0
var buffer = []

func _init(delay, rate):
	self.delay = delay
	self.rate = rate
	
func reset():
	time = 0.0
	last_pull_time = 0.0
	buffer = []
	state = BUFFERING

func push(packet):
	buffer.push_back({ time = time, packet = packet })

func pull():
	var packet = buffer[0].packet
	buffer.remove(0)
	last_pull_time = time
	return packet
	
func ready():
	return (state == PLAYING and buffer.size() > 0 and (time - last_pull_time) > (1.0 / rate))

func update(delta):
	if (state == BUFFERING and buffer.size() > 0 and time > delay):
		state = PLAYING
	elif (state == PLAYING and buffer.size() == 0):
		state = BUFFERING
	
	while (buffer.size() > 0 and (time - buffer[0].time) > delay):
		buffer.remove(0)
	
	time += delta
