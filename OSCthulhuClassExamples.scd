// To make OSCthulhu more intuitive we've begun working on an abstracted OSCthulhu interface in SC

OSCthulhu.chat("Hello world!");

// make the client send to a different port
OSCthulhu.changePorts(57120);
OSCthulhu.changePorts(32244);

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

// log out of a piece. if no one is logged into a piece, all objects for that piece are removed
OSCthulhu.cleanup("test");

// flush the server
OSCthulhu.flush;