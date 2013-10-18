/////////////////////////////////
// Networking with OSCthulhu
/////////////////////////////////

(
n = NetAddr("127.0.0.1", 32243); // Address of the OSCthulhu Client

OSCresponder(nil, '/addSyncObject', {
	arg time, resp, msg; [time, msg].postln;

	if(msg[1] == \SynthObject, { // If the set message is adding SynthObject
		"MAKE SYNTH!".postln;
		if(~syncSynth == nil, { ~syncSynth = Synth(\SynchronizedSynth, [\freq, msg[4], \phaseDist, msg[5]]); }); // Create the Synth
	});

}).add;

OSCresponder(nil, '/setSyncArg', { arg time, resp, msg;
	[time, msg].postln;

	if(msg[1] == \SynthObject, { // If the set message is setting SynthObject
		case
		{ msg[2] == 0 } { ~syncSynth.set(\freq, msg[3]) } // Argument 0, Freq
		{ msg[2] == 1 } { ~syncSynth.set(\phaseDist, msg[3]) } // Argument 1, Phase Dist
	});

}).add;

OSCresponder(nil, '/removeSyncObject', { arg time, resp, msg;
	[time, msg].postln;

	if(msg[1] == \SynthObject, { // If the set message is adding SynthObject
		if(~syncSynth != nil, { ~syncSynth.set(\gate, 0); ~syncSynth = nil; }); // Create the Synth
	});

}).add;

OSCresponder(nil, '/addPeer', { arg time, resp, msg;
	[time, msg].postln;

}).add;

OSCresponder(nil, '/removePeer', { arg time, resp, msg;
	[time, msg].postln;

}).add;

OSCresponder(nil, '/chat', { arg time, resp, msg;
	[time, msg].postln;

}).add;

OSCresponder(nil, '/ports', { arg time, resp, msg;
	[time, msg].postln;

}).add;

OSCresponder(nil, '/userName', { arg time, resp, msg;
	[time, msg].postln;

}).add;

// CHANGES THE PORTS
// Syntax: /changePorts,portNum1,portNumN,etc (any number of port numbers)
n.sendMsg("/changePorts", 57120, 32244);

// THIS UPDATES YOU WHEN LOGIN WITH EVERYTHING FROM SERVER. ALSO SENDS YOUR USER NAME OVER
n.sendMsg("/login");
)

// ADDING AN OBJECT
// Syntax: /addSyncObject,"objectName","objectType","objectSubtype",arg1,argN,etc (any number of arguments from 0-whatevz)
n.sendMsg("/addSyncObject", "TestObject3", "SCObject", "SubSC", 0.0, "something", 5);
// If you look in the post window you'll notice the server updates posting.


// SETTING AN ARGUMENT'S VALUE
// Syntax: /setSyncArg, "objectName",argNum,argValue,(optional: int, if set to 1 this prevents bounce back[ask for more info from me if you want to know why this would be useful])
n.sendMsg("/setSyncArg", "TestObject3", 0, 1.0.rand);
n.sendMsg("/setSyncArg", "TestObject3", 1, "hell yeah");

// This prevents bounce back from the server
n.sendMsg("/setSyncArg", "TestObject3", 2, 233, true);

// REMOVING AN OBJECT
// Syntax: /removeSyncObject,"objectName"
n.sendMsg("/removeSyncObject", "TestObject3");

// REMOVE ALL OBJECTS FROM THE SERVER
n.sendMsg("/flush");

// SEND CHAT MESSAGE
// Syntax: /chat,"chatText"
n.sendMsg("/chat", "OSCthulhu is so cool!");


///////////////////////
// Little Synth Example
///////////////////////

s.boot; // Don't forget to boot the server!!!

// Compile a synthdef
(
SynthDef.new(\SynchronizedSynth, {
	|freq=440, phaseDist = 1, gate = 1|
	var signal = SinOsc.ar(0, SinOsc.ar(freq, 0, 0.5, 0.5) * phaseDist, 0.1);
	var env = EnvGen.ar(Env.asr(0.1, 1, 1, -4), gate:gate, doneAction: 2);
	Out.ar(0, signal.dup * env);
}).store;
)

// Add an object, we already defined our response above using the tag \SynthObject
n.sendMsg("/addSyncObject", "SynthObject", "SCObject", "Synth", 880, 0.5);
n.sendMsg("/setSyncArg", "SynthObject", 0, 440);
n.sendMsg("/setSyncArg", "SynthObject", 0, 666);
n.sendMsg("/setSyncArg", "SynthObject", 1, 2);
n.sendMsg("/setSyncArg", "SynthObject", 1, 8pi);
n.sendMsg("/removeSyncObject", "SynthObject");

// You can logout when you're done.
n.sendMsg("/logout");

/*
What if you want to start your own server?
Commands: OSCthulhu Server port password
from terminal

OSX:
cd /path/to/OSCthulhu.app/Contents/MacOS
./OSCthulhu Server 32242 yourpass

Linux:
cd /path/to/OSCthulhu
./OSCthulhu Server 32242 yourpass

Windows:
I don't know windows command line stuff very well :(

NOTE:
At this point you'll want to change your OSCthulhu client preference to your server's IP Address as well as the port you chose (here 32242)
You may have to restart OSCthulhu to get it to connect to the new server, but it should just automatically connect.
*/