var PlayoutBuffer = load("playoutbuffer.gd")

const CONNECT_ATTEMPTS = 20

var packet_peer = PacketPeerUDP.new()
var playout_buffer = PlayoutBuffer.new(0.1, 40)

var boxes = []

var ip = null
var port = 0
var seq = -1

func connect(ip, port):
	self.ip = ip
	self.port = port
	
	# Select a port for the client
	var client_port = port + 1
	
	while (packet_peer.listen(client_port) != OK):
		client_port += 1
	
	# Set server address
	packet_peer.set_send_address(ip, port)
	
	# Try to connect to server
	var attempts = 0
	var connected = false
	
	while (not connected and attempts < CONNECT_ATTEMPTS):
		attempts += 1
		packet_peer.put_var(["connect"])
		OS.delay_msec(50)
		
		while (packet_peer.get_available_packet_count() > 0):
			var packet = packet_peer.get_var()
			if (packet != null and packet[0] == "accepted"):
				connected = true
				break
	
	if (not connected):
		print("Error connecting to ", ip, ":", port)
		return false
	else:
		print("Connected to ", ip, ":", port)
		playout_buffer.reset()
		return true
	
func disconnect():
	print("Disconnected from ", ip, ":", port)
	packet_peer.close()

func update(delta):
	playout_buffer.update(delta)
	
	if (playout_buffer.ready()):
		handle_update(playout_buffer.pull())
	
	while (packet_peer.get_available_packet_count() > 0):
		var packet = packet_peer.get_var()
		
		if (packet == null):
			continue
		
		if (packet[0] == "update"):
			playout_buffer.push(packet)
		elif (packet[0] == "event"):
			handle_event(packet)

# Register simulated objects with the server
func set_boxes(boxes):
	self.boxes = boxes

# Retrieves a box by name
func get_box(name):
	for box in boxes:
		if (box.get_name() == name):
			return box
	return null

# Update handler
func handle_update(packet):
	if (packet[1] > seq):
		seq = packet[1]
		var state = {}
		for i in range(2, packet.size()):
			var name = packet[i][0]
			var pos = packet[i][1]
			var rot = packet[i][2]
			var lv = packet[i][3]
			var av = packet[i][4]
			var box = get_box(name)
			box.set_state([pos, rot, lv, av])

# Event handler
func handle_event(packet):
	var type = packet[1]
	var box = get_box(packet[2])
	
	if (type == "start_drag"):
		box.start_drag()
	elif (type == "drag"):
		box.drag(packet[3])
	elif (type == "stop_drag"):
		box.stop_drag()

# Send
func send(packet):
	packet_peer.put_var(packet)

