// It can be useful to abstract away even more behavior and think about our objects as fully enclosed in the synchronization framework
// We can use a subgroup mapper and sync objects to create objects with automatic networked updates

OSCthulhu.changePorts(57120); // Always make sure the OSCthulhu client is pointed at the right port
OSCthulhu.printAll(true); // For debugging, printing out your messages is very helpful
OSCthulhu.printAll(false); // Turn it off like such

// Next we need a synth def. When making synthdefs using this approach, make sure to use a gate argument and an envelope with a doneAction:2
(
SynthDef.new("SyncPulse", {
	|freq = 440, width = 0.5, res=0.5, gate=1|
	var env = EnvGen.ar(Env.asr(1, 1, 1), gate:gate, doneAction: 2);
	Out.ar(0, RLPF.ar(Pulse.ar(freq, width, 0.1).dup, freq * 4, res) * env);
}).store;
)


// Now we need to create an OSCthulhuSyncMap. This is used to organize OSCthulhuSyncObjects in a group for easy creation and network control.
// The first argument is the name of the synth definition we created. The second argument is the OSCthulhuSyncObject subclass we want to use.
~syncSynthMap = OSCthulhuSyncMap.new("SyncPulse", OSCthulhuSyncSynth);


s.boot; // Don't forget to boot the server!

// Now we can create a synth in our syncmap. The creation, setting, and removal will be synchronized across the OSCthulhu network.
~syncSynthMap.add("SyncPulse1", [666, 0.5, 0.1]);
~syncSynthMap.set("SyncPulse1", 0, 440); // We set arguments by index. This is setting argument 0 to the value 440.
~syncSynthMap.set("SyncPulse1", 1, 0.1);
~syncSynthMap.set("SyncPulse1", 2, 0.7);
~syncSynthMap.set("SyncPulse1", 2, 0.05);
~syncSynthMap.remove("SyncPulse1"); // frees the synth on the bounce back using the gate parameter

// We can have multiple running if we want.
~syncSynthMap.add("SyncPulse1", [666, 0.5, 0.1]);
~syncSynthMap.set("SyncPulse1", 0, 440); // We set arguments by index
~syncSynthMap.set("SyncPulse1", 1, 0.1);
~syncSynthMap.set("SyncPulse1", 2, 0.7);
~syncSynthMap.set("SyncPulse1", 2, 0.075);

~syncSynthMap.add("SyncPulse2", [999, 0.5, 0.1]);
~syncSynthMap.set("SyncPulse2", 0, 1337); // We set arguments by index
~syncSynthMap.set("SyncPulse2", 1, 0.1);
~syncSynthMap.set("SyncPulse2", 2, 0.7);
~syncSynthMap.set("SyncPulse2", 2, 0.075);


~syncSynthMap.remove("SyncPulse1"); // frees the synth on the bounce back using the gate parameter
~syncSynthMap.remove("SyncPulse2"); // frees the synth on the bounce back using the gate parameter

/* We can still have synths with short envelopes even if the lifetime of the synth is long by using a second envelope and a t_trig argument or something internally for the gate argument. The second envelope must have a doneAction of 0 or you will free the synth too early.*/

( // This is the same as the last synth, except that we have a second envelope and a new argument, trigFreq.
SynthDef.new("TrigPulse", {
	|freq = 440, width = 0.5, res=0.5, trigFreq=1, gate=1| // ALWAYS MAKE SURE THE GATE ARGUMENT IS LAST!
	var env = EnvGen.ar(Env.asr(1, 1, 1), gate:gate, doneAction: 2);
	var trigEnv = EnvGen.ar(Env.perc(0.01, 0.25), gate:Impulse.ar(trigFreq)); // We're using an impulse to trigger our trigEnv
	Out.ar(0, RLPF.ar(Pulse.ar(freq, width, 0.1).dup, freq * 4, res) * env * trigEnv);
}).store;
)

// We need to create a new SyncMap for each synth def.
~syncSynthMap = OSCthulhuSyncMap.new("TrigPulse", OSCthulhuSyncSynth);

~syncSynthMap.add("TrigPulse1", [666, 0.5, 0.1, 1]); // Adding the extra argument is very important, or this won't work right.
~syncSynthMap.set("TrigPulse1", 0, 440); // We set arguments by index
~syncSynthMap.set("TrigPulse1", 1, 0.1);
~syncSynthMap.set("TrigPulse1", 3, 4);
~syncSynthMap.set("TrigPulse1", 3, 30);
~syncSynthMap.set("TrigPulse1", 3, 13);
~syncSynthMap.remove("TrigPulse1"); // frees the synth on the bounce back using the gate parameter