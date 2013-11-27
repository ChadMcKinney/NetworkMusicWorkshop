// To make OSCthulhu more intuitive we've begun working on an abstracted OSCthulhu interface in SC

OSCthulhu.chat("Hello world!");

// make the client send to a different port. VERY IMPORTANT. ALWAYS REMEMBER TO CHANGE IT TO YOUR CLIENT PORT. SC IS 57120
OSCthulhu.changePorts(57120);
OSCthulhu.changePorts(32244);
OSCthulhu.changePorts(57120);

// make the client send to two ports
OSCthulhu.changePorts([57120,32244]);

// login to a specific piece
OSCthulhu.login("Test");

// once you are logged in, you can get your user name from here
OSCthulhu.userName;

// add a sync object
OSCthulhu.addSyncObject("awesomeObject", "test", "subgroup", [1,2.0,"three"]);

OSCthulhu.printAll(true); // For debugging, printing out your messages is very helpful
OSCthulhu.printAll(false); // Turn it off like such

// We set arguments by specifying the name of the object, then argument number (in the original array given in addSyncObject), and the new value
OSCthulhu.setSyncArg("awesomeObject", 2, "FiftyFive");
OSCthulhu.setSyncArg("awesomeObject", 0, 667);

// We can create an action when a new object is added with .onAddSyncObject
~onAdd = OSCthulhu.onAddSyncObject(\addPost, {|m| ("ADD: " ++ m).postln });

// Similarly, onSetSyncArg is can be used for actions you want to be called when an argument is set.
~onSync = OSCthulhu.onSetSyncArg(\syncPost, { |m| ("SET: " ++ m).postln; });

// We can have multiple of these functions, just make sure to name them differently or they'll overwrite eachother.
~onSync2 = OSCthulhu.onSetSyncArg(\syncPost2, { |m| ("SET2: " ++ m).postln; });

~onAdd.free; // remove actions when you are done.
~onSync.free;
~onSync2.free;

// It useful to focus our functions on one object, we can accompolish this with onObjectSet
~onAwesomeSet = OSCthulhu.onObjectSet(\onAwesomeSet, "awesomeObject", { |argNum, value| [argNum, value].postln });
~onAwesomeSet.free;

// remove our sync object
OSCthulhu.removeSyncObject("awesomeObject");

// Same example as before, but now with the class functions
(
s.boot; // Don't forget to boot the server!!!

// Compile a synthdef
(
SynthDef.new(\SynchronizedSynth, {
	|freq=440, phaseDist = 1, gate = 1|
	var signal = SinOsc.ar(0, SinOsc.ar(freq, 0, 0.5, 0.5) * phaseDist, 0.1);
	var env = EnvGen.ar(Env.asr(0.1, 1, 1, -4), gate:gate, doneAction: 2);
	Out.ar(0, signal.dup * env);
}).store;
);

// Create the listener for new synth instances
~addSyncSynth = OSCthulhu.onAddSyncObject(\addSynthObject, {
	|msg|
	msg.postln;
	if(msg[1] == \SynthObject, { // If the set message is adding SynthObject
		"MAKE SYNTH!".postln;
		if(~syncSynth == nil, { ~syncSynth = Synth(\SynchronizedSynth, [\freq, msg[4], \phaseDist, msg[5]]); }); // Create the Synth
	});
});

// Create the listener for deleting synth instances
~deleteSyncSynth = OSCthulhu.onRemoveSyncObject(\removeSynthObject, {
	|msg|

	if(msg[1] == \SynthObject, { // If the set message is adding SynthObject
		"FREE SYNTH!".postln;
		if(~syncSynth != nil, { ~syncSynth.set(\gate, 0); ~syncSynth = nil; }); // Create the Synth
	});
});

~setSyncSynth = OSCthulhu.onObjectSet(\setSynthObject, "SynthObject", {
	|argNum, value|
	argNum.postln;
	value.postln;
	case
	{ argNum == 0 } { ~syncSynth.set(\freq, value) } // Argument 0, Freq
	{ argNum == 1 } { ~syncSynth.set(\phaseDist, value) } // Argument 1, Phase Dist
});

)

// Your last argument, the argArray must be an array or you can crash the OSCthulhu server by sending bad data
OSCthulhu.addSyncObject("SynthObject", "SCObject", "Synth", [440, 1]);
OSCthulhu.setSyncArg("SynthObject", 0, 666);
OSCthulhu.setSyncArg("SynthObject", 0, 777);
OSCthulhu.setSyncArg("SynthObject", 1, 4);
OSCthulhu.setSyncArg("SynthObject", 1, 8);
OSCthulhu.removeSyncObject("SynthObject");

// log out of a piece. if no one is logged into a piece, all objects for that piece are removed
OSCthulhu.cleanup("test");

// flush the server
OSCthulhu.flush;