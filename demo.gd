extends Node

var Server = load("server.gd")
var Client = load("client.gd")

var host = true
var ready = false
var start = null
var connect = null
var network_fps = null
var port = null
var ip = null

var client = Client.new()
var server = Server.new()

var boxes = null

func _ready():
	start = get_node("controls/start")
	connect = get_node("controls/connect")
	port = get_node("controls/port")
	ip = get_node("controls/ip")
	network_fps = get_node("controls/network_fps")
	
	boxes = get_node("boxes").get_children()
	
	server.set_boxes(boxes)
	client.set_boxes(boxes)
	
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
		server.update(delta)
		
	#Client update
	if (ready and not host):
		client.update(delta)
			
# Start/stop functions for client/server
func start_client():
	if (client.connect(ip.get_text(), port.get_val())):
		connect.set_text("Disconnect")
		start.set_disabled(true)
		set_host_boxes(false)
		host = false
		ready = true
	
func stop_client():
	ready = false
	host = true
	client.disconnect()
	set_host_boxes(true)
	connect.set_text("Connect")
	start.set_disabled(false)
	
func start_server():
	if (server.start(port.get_val(), network_fps.get_val())):
		start.set_text("Stop Server")
		connect.set_disabled(true)
		set_host_boxes(true)
		host = true
		ready = true
	
func stop_server():
	ready = false
	server.stop()
	start.set_text("Start Server")
	connect.set_disabled(false)

# Sets all boxes to host mode
func set_host_boxes(host):
	for box in boxes:
		box.host = host
