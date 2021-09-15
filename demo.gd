extends Node

const CONNECT_ATTEMPTS = 20

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

			var packet_ip = packet_peer.get_packet_ip()
			var packet_port = packet_peer.get_packet_port()

			if (packet[0] == "connect"):
				if (not has_client(packet_ip, packet_port)):
					print("Client connected from ", packet_ip, ":", packet_port)
					clients.append({ ip = packet_ip, port = packet_port, seq = 0 })

				packet_peer.set_dest_address(packet_ip, packet_port)
				packet_peer.put_var(["accepted"])
			elif (packet[0] == "event"):
				# Handle event locally
				handle_event(packet)

				# Broadcast event to clients
				for client in clients:
					if (client.ip != packet_ip and client.port != packet_port):
						packet_peer.set_dest_address(packet_ip, packet_port)
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
					packet.append([box.get_name(), box.get_position(), box.get_rotation(), box.get_linear_velocity(), box.get_angular_velocity()])
				packet_peer.set_dest_address(client.ip, client.port)
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

# Start/stop functions for client/server
func start_client():
	# Select a port for the client
	var client_port = int(port.get_value()) + 1

	while (packet_peer.listen(client_port) != OK):
		client_port += 1

	# Set server address
	packet_peer.set_dest_address(ip.get_text(), port.get_value())

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
		print("Error connecting to ", ip.get_text(), ":", port.get_value())
		return
	else:
		print("Connected to ", ip.get_text(), ":", port.get_value())
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
	print("Disconnected from ", ip.get_text(), ":", port.get_value())
	connect.set_text("Connect")
	start.set_disabled(false)

func start_server():
	if (packet_peer.listen(int(port.get_value())) != OK):
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
		packet_peer.set_dest_address(client.ip, client.port)
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
			var box = get_node("boxes/" + name)
			box.set_state([pos, rot, lv, av])

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
func set_host_boxes(p_host):
	for box in boxes:
		box.host = p_host

# Set stream for boxes
func set_packet_peer_boxes(p_packet_peer):
	for box in boxes:
		box.packet_peer = p_packet_peer

# Check client is registered
func has_client(p_ip, p_port):
	for client in clients:
		if (client.ip == p_ip and client.port == p_port):
			return true
	return false
