# State Synchronization Demo (Work in Progress)

In light of what I've learned since I made the [snapshot interpolation demo](https://github.com/jrimclean/network-demo-tcp.git), I have decided to write a new demo for [Godot](http://www.godotengine.org) illustrating a technique called state synchronization.

Both the client and the server run the physical simulation. State snapshots are sent from the server to the client at an adjustable rate. With each update, the physical state on the client is snapped to the new state.

To start a dedicated server with the headless version of Godot type, "godotserver -server" in the project directory.

## Todo:
* Everything

## License
Copyright (c) 2015 James McLean  
Licensed under the MIT license.
