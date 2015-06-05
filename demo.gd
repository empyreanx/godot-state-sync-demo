extends Node

var timer = 0
var host = true
var ready = false
var start_btn = null
var connect_btn = null
var network_fps = null
var port = null
var ip = null

# For server
var clients = []

# For client
var packet_peer = PacketPeerUDP.new()

# Boxes in the scene
var boxes = null

func _ready():
	start_btn = get_node("controls/start")
	connect_btn = get_node("controls/connect")
	port = get_node("controls/port")
	ip = get_node("controls/ip")
	network_fps = get_node("controls/network_fps")
	
	boxes = get_node("boxes").get_children()
	
	load_defaults()
	set_process(true)
	
	for arg in OS.get_cmdline_args():
		if (arg == "-server"):
			start_server()
			break

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
		pass
	#Client update
	if (ready and not host):
		pass

# Start/stop functions for client/server
func start_client():
	if (stream_peer.connect(ip.get_text(), port.get_val()) != OK):
		print("Error connecting to ", ip.get_text(), ":", port.get_val())
	else:
		print("Connected to ", ip.get_text(), ":", port.get_val())
		connect_btn.set_text("Disconnect")
		start_btn.set_disabled(true)
		set_host_boxes(false)
		set_stream_boxes(packet_peer)
		host = false
		ready = true
	
func stop_client():
	ready = false
	host = true
	set_host_boxes(true)
	print("Disconnected from ", ip.get_text(), ":", port.get_val())
	connect_btn.set_text("Connect")
	start_btn.set_disabled(false)
	
func start_server():
	if (server.listen(port.get_val()) != OK):
		print("Error listening on port ", port.get_value())
	else:
		print("Listening on port ", port.get_value())
		start_btn.set_text("Stop Server")
		connect_btn.set_disabled(true)
		set_host_boxes(true)
		host = true
		ready = true
	
func stop_server():
	print("Stopped listening on ", port.get_value())
	start_btn.set_text("Start Server")
	connect_btn.set_disabled(false)
	ready = false

# Sets all boxes to host mode
func set_host_boxes(host):
	for box in boxes:
		box.host = host

# Set stream for boxes
func set_stream_boxes(stream):
	for box in boxes:
		box.stream = stream
