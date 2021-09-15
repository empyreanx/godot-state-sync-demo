**Note:** This demo has been ported to Godot3. The original Godot2 version is located [here](https://github.com/empyreanx/godot-state-sync-demo/tree/godot2) for posterity.

# State Synchronization Demo

In light of what I've learned since I made the [snapshot interpolation demo](https://github.com/jrimclean/godot-snapshot-interpolation-demo), I have decided to write a new demo for [Godot](http://www.godotengine.org) illustrating a technique called state synchronization. This is now my recommended approach for networked physics using Godot.

Both the client and the server run the physical simulation. State snapshots are sent from the server to the client at a high rate. The client stores the most recent update and then interpolates toward it, which has the effect of smoothing the motion of bodies in the simulation.

To start a dedicated server with the headless version of Godot type, "godotserver -server" in the project directory.

## Features
* Sequence checking for state updates
* Linearly interpolated error correction for position and rotation
* Experimental state expiration

## Todo
* Jitter buffer
* Snap state when distance is greater than some threshold
* Compression

## Credits
[Ryan Roden-Corrent](https://github.com/rcorre) for the port to Godot3

## License
Copyright (c) 2015 James McLean  
Licensed under the MIT license.
