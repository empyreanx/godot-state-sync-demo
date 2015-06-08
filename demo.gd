extends Node

const CONNECT_ATTEMPTS = 20
const ALPHA = 0.1

var timer = 0
var host = true
var ready = false
var start = null
var connect = null
var network_fps = null
var port = null
var ip = null

var packet_peer = PacketPeerUDP.new()

# For server
var clients = []

# For client
var seq = -1
var state = {}

# Boxes in the scene
var boxes = null

func _ready():
	start = get_node("controls/start")
	connect = get_node("controls/connect")
	port = get_node("controls/port")
	ip = get_node("controls/ip")
	network_fps = get_node("controls/network_fps")
	
	boxes = get_node("boxes").get_children()
	
	set_packet_peer_boxes(packet_peer)
	
	load_defaults()
	
	for arg in OS.get_cmdline_args():
		if (arg == "-server"):
			start_server()
			break
	
	set_process(true)
	set_fixed_process(true)
	
# Load default values
func load_defaults():
	var config_file = ConfigFile.new()
	config_file.load("res://defaults.cfg")
	ip.set_text(config_file.get_value("defaults", "ip"))
	port.set_value(config_file.get_value("defaults", "port"))
	network_fps.set_value(config_file.get_value("defaults", "network_fps"))

# Toggle starting/stoping a server
func _on_start_pressed():
	if (not ready):
		start_server()
	else:
		stop_server()
	
# Toggle connecting/disconnecting a client
func _on_connect_pressed():
	if (not ready):
		start_client()
	else:
		stop_client();
		
func _process(delta):
	#Server update
	if (ready and host):
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
		var duration = 1.0 / network_fps.get_value()
		
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
		
	#Client update
	if (ready and not host):
		while (packet_peer.get_available_packet_count() > 0):
			var packet = packet_peer.get_var()
			
			if (packet == null):
				continue
			
			if (packet[0] == "update"):
				handle_update(packet)
			elif (packet[0] == "event"):
				handle_event(packet)

func _fixed_process(delta):
	if (ready and not host):
		for box in boxes:
			if (state.has(box.get_name())):
				var box_state = state[box.get_name()]
				if (box.get_pos().distance_to(box_state[0]) > 1.0):
					box.set_pos(lerp_pos(box.get_pos(), box_state[0], 1.0 - ALPHA))
				
				#box.set_rot(slerp_rot(box.get_rot(), box_state[1], ALPHA))
				
# Start/stop functions for client/server
func start_client():
	# Select a port for the client
	var client_port = port.get_val() + 1
	
	while (packet_peer.listen(client_port) != OK):
		client_port += 1
	
	# Set server address
	packet_peer.set_send_address(ip.get_text(), port.get_val())
	
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
		print("Error connecting to ", ip.get_text(), ":", port.get_val())
		return
	else:
		print("Connected to ", ip.get_text(), ":", port.get_val())
		connect.set_text("Disconnect")
		start.set_disabled(true)
		set_host_boxes(false)
		host = false
		ready = true
	
func stop_client():
	ready = false
	host = true
	packet_peer.close()
	set_host_boxes(true)
	print("Disconnected from ", ip.get_text(), ":", port.get_val())
	connect.set_text("Connect")
	start.set_disabled(false)
	
func start_server():
	if (packet_peer.listen(port.get_val()) != OK):
		print("Error listening on port ", port.get_value())
		return
	else:
		print("Listening on port ", port.get_value())
		start.set_text("Stop Server")
		connect.set_disabled(true)
		set_host_boxes(true)
		host = true
		ready = true
	
func stop_server():
	ready = false
	packet_peer.close()
	print("Stopped listening on ", port.get_value())
	start.set_text("Start Server")
	connect.set_disabled(false)

# Broadcast packet to all clients
func broadcast(packet):
	for client in clients:
		packet_peer.set_send_address(client.ip, client.port)
		packet_peer.put_var(packet)

# Update handler
func handle_update(packet):
	if (packet[1] > seq):
		seq = packet[1]
		for i in range(2, packet.size()):
			var name = packet[i][0]
			var pos = packet[i][1]
			var rot = packet[i][2]
			var lv = packet[i][3]
			var av = packet[i][4]
			state[name] = [pos, rot, lv, av]
			var box = get_node("boxes/" + packet[i][0])
			#box.set_pos(pos)
			#box.set_rot(rot)
			box.set_linear_velocity(lv)
			box.set_angular_velocity(av)

# Event handler
func handle_event(packet):
	var type = packet[1]
	var box = get_node("boxes/" + packet[2])
	
	if (type == "start_drag"):
		box.start_drag()
	elif (type == "drag"):
		box.drag(packet[3])
	elif (type == "stop_drag"):
		box.stop_drag()

# Sets all boxes to host mode
func set_host_boxes(host):
	for box in boxes:
		box.host = host

# Set stream for boxes
func set_packet_peer_boxes(packet_peer):
	for box in boxes:
		box.packet_peer = packet_peer

# Check client is registered
func has_client(ip, port):
	for client in clients:
		if (client.ip == ip and client.port == port):
			return true
	return false

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
	var cos_angle = v1.dot(v2)
	var angle = acos(cos_angle)
	var angle_alpha = angle * alpha
	var v3 = (v2 - (v1.dot(v2) * v1)).normalized()
	return v1 * cos(angle_alpha) + v3 * sin(angle_alpha)