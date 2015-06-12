var packet_peer = PacketPeerUDP.new()

var clients = []
var boxes = []

var port = 0
var timer = 0
var fps = 0

func start(port, fps):
	self.port = port
	self.fps = fps
	
	if (packet_peer.listen(port) != OK):
		print("Error listening on port ", port)
		return false
	else:
		print("Listening on port ", port)
		return true
	
func stop():
	packet_peer.close()
	print("Stopped listening on ", port)
	
func update(delta):
	# Handle incoming
	while (packet_peer.get_available_packet_count() > 0):
		var packet = packet_peer.get_var()
		
		if (packet == null):
			continue
		
		var ip = packet_peer.get_packet_ip()
		var port = packet_peer.get_packet_port()
		
		if (packet[0] == "connect"):
			if (not has_client(ip, port)):
				print("Client connected from ", ip, ":", port)
				clients.append({ ip = ip, port = port, seq = 0 })
			
			packet_peer.set_send_address(ip, port)
			packet_peer.put_var(["accepted"])
		elif (packet[0] == "event"):
			# Handle event locally
			handle_event(packet)
			
			# Broadcast event to clients
			for client in clients:
				if (client.ip != ip and client.port != port):
					packet_peer.set_send_address(ip, port)
					packet_peer.put_var(packet)
					
	# Send outgoing
	var duration = 1.0 / fps
	
	if (timer < duration):
		timer += delta
	else:
		timer = 0
		for client in clients:
			var packet = ["update", client.seq]
			client.seq += 1
			for box in boxes:
				packet.append([box.get_name(), box.get_pos(), box.get_rot(), box.get_linear_velocity(), box.get_angular_velocity()])
			packet_peer.set_send_address(client.ip, client.port)
			packet_peer.put_var(packet)

# Register simulated objects with the server
func set_boxes(boxes):
	self.boxes = boxes

# Retrieves a box by name
func get_box(name):
	for box in boxes:
		if (box.get_name() == name):
			return box
	return null

# Checks if a client is registered with the server
func has_client(ip, port):
	for client in clients:
		if (client.ip == ip and client.port == port):
			return true
	return false

# Broadcast packet to all clients
func broadcast(packet):
	for client in clients:
		packet_peer.set_send_address(client.ip, client.port)
		packet_peer.put_var(packet)

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
