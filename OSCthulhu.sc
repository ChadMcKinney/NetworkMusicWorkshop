/*
 * A class for easy handling of the OSCthulhu client through SC.
 */
OSCthulhu {
	classvar <>clientPort = 32243; // 32243 is the Default OSCthulhuClient port
	classvar oscthulhuAddr, printAllDef, <>piece;
	classvar <>userName = "default";

	*initClass {
		Class.initClassTree(NetAddr);
		Class.initClassTree(OSCdef);
		oscthulhuAddr = NetAddr("127.0.0.1", clientPort);
	}

	//////////////// tell the OSCthulhu to do things ////////////////

	/*
	 * Tell the client to send to the following port(s).
	 */
	*changePorts {|portList|
		var msg;
		if(portList.isKindOf(Collection),{
			msg = Array.new(portList.size+1);
			msg.add("/changePorts");
			portList.do{|port| msg.add(port);};
		},{
			msg = Array.new(2);
			msg.add("/changePorts");
			msg.add(portList);
		});

		oscthulhuAddr.sendRaw(msg.asRawOSC);
	}

	*printAll { |doPrintAll|
		OSCFunc.trace(doPrintAll);
	}

	/*
	 * ask for login sync
	 */
	*login {|piece|

		// OSCthulhuSubGroupMapper.init; // Initialize default mapper

		// Add login responder
		OSCdef.new(\loginUserName, {
			|msg, time, addr, recvPortg| msg.postln; userName = msg[1];
			("Logged into OSCthulhu as: " ++ userName).postln;
		}, '/userName', oscthulhuAddr);

		if(piece.isNil,{
			oscthulhuAddr.sendMsg("/login");
		},{
			oscthulhuAddr.sendMsg("/login",piece);
		});

		OSCthulhu.piece = piece;
	}

	/*
	 * name, group, and subgroup are individual arguments, all object args must be in an array.
	 */
	*addSyncObject {|objName,objGroup,objSubGroup,argArray|
		var msg;

		msg = Array.new((argArray.size*2)+4);
		msg.add("/addSyncObject");
		msg.add(objName);
		msg.add(objGroup);
		msg.add(objSubGroup);
		if( argArray.size != 0,{
			msg.addAll(argArray);
		});

		oscthulhuAddr.sendRaw(msg.asRawOSC);
	}

	/*
	 * set an arg for a sync object
	 */
	*setSyncArg {|objName,objArgNumber,objArgValue|
		oscthulhuAddr.sendMsg("/setSyncArg",objName,objArgNumber,objArgValue);
	}

	/*
	 * remove a sync object from the server
	 */
	*removeSyncObject {|objName|
		oscthulhuAddr.sendMsg("/removeSyncObject",objName);
	}

	/*
	 * send a chat
	 */
	*chat {|message|
		oscthulhuAddr.sendMsg("/chat",message);
	}

	/*
	 * force remove all sync objects
	 */
	*flush {
		oscthulhuAddr.sendMsg("/flush");
	}

	/*
	 * ask the server to remove all objects for a piece if noone is still in it
	 */
	*cleanup {|piece|
		oscthulhuAddr.sendMsg("/cleanup",piece);
	}

	/*
	 * get the body of the chat window from the client (useful at login)
	 */
	*getChat
	{
		oscthulhuAddr.sendMsg("/getChat");
	}

	//////////////// make OSCdefs to listen to the OSCthulhu ////////////////

	/*
	 * return a new OSCdef for /addSyncObject with the supplied function
	 */
	*onAddSyncObject {|key, function|
		^OSCdef.new(key, function, '/addSyncObject', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for /setSyncArg with the supplied function
	 */
	*onSetSyncArg {|key, function|
		^OSCdef.new(key, function, '/setSyncArg', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for targetting specific objects that are set
	 */
	*onObjectSet { |key, objectName, function|
		var func = {
			|m|
			if(m[1] == objectName.asSymbol, { function.value(m[2], m[3]) });
		};

		^OSCdef.new(key, func, '/setSyncArg', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for /removeSyncObject with the supplied function
	 */
	*onRemoveSyncObject {|key, function|
		^OSCdef.new(key, function, '/removeSyncObject', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for /addPeer with the supplied function
	 */
	*onAddPeer {|key, function|
		^OSCdef.new(key, function, '/addPeer', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for /removePeer with the supplied function
	 */
	*onRemovePeer {|key, function|
		^OSCdef.new(key, function, '/removePeer', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for /chat with the supplied function
	 */
	*onChat {|key, function|
		^OSCdef.new(key, function, '/chat', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for /getChat with the supplied function
	 */
	*onGetChat {|key, function|
		^OSCdef.new(key, function, '/getChat', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for /userName with the supplied function
	 */
	*onUserName {|key, function|
		^OSCdef.new(key, function, '/userName', oscthulhuAddr);
	}

	/*
	 * return a new OSCdef for /ports with the supplied function
	 */
	*onPorts {|key, function|
		^OSCdef.new(key, function, '/ports', oscthulhuAddr);
	}
}

// Class wrapper for OSCthulhu Objects
OSCthulhuSyncObject {
	var <>objectName, <>objectsubGroup, <>values, <>updateFunction;

	*new { arg objectName, objectsubGroup, values;
		^super.new.init(objectName, objectsubGroup, values);
	}

	init { arg objectName, objectsubGroup, values;
		this.objectName = objectName;
		this.objectsubGroup = objectsubGroup;
		this.values = values;

		// Default nil update function
		updateFunction = { |values| ^nil };
	}

	update {
		this.updateFunction.value(values);
	}

	set { arg index, value;
		OSCthulhu.setSyncArg(objectName, index, value);
	}

	networkSet { arg index, value;
		values[index] = value;
	}

	// overrideablefor clean up on removal
	networkRemove {

	}
}

// Static Class for parsing OSCthulhu objects via subgroups
OSCthulhuSubGroupMapper {
	classvar syncMaps;

	*initClass {
		StartUp.add { OSCthulhuSubGroupMapper.init; }
	}

	// Initalized OSCthulhu with the SubGroupMapper functions
	*init {
		syncMaps = Dictionary.new;

		OSCthulhu.onAddSyncObject(\SGMapperAddObject, {
			|msg, time, addr, recvPortg|

			// /addSyncObject
			// msg format
			// [0] msg address
			// [1] Object name
			// [2] Group
			// [3] SubGroup
			// [4] arguments

			var map = syncMaps.at(msg[3].asSymbol);
			if(map.notNil, {
				map.networkAdd(msg[1], [msg[4]]);
			});
		});

		OSCthulhu.onSetSyncArg(\SGMapperSetArg, {
			|msg, time, addr, recvPortg|

			// /setSyncArg
			// msg format
			// [0] msg address
			// [1] Object name
			// [2] argument index
			// [3] value
			// [4] group
			// [5] subgroup
			var map = syncMaps.at(msg[5].asSymbol);

			if(map.notNil, {
				map.networkSet(msg[1], msg[2], msg[3]);
			});
		});

		OSCthulhu.onRemoveSyncObject(\SGMapperRemovObject, {
			|msg, time, addr, recvPortg|

			// /removeSyncObject
			// msg format
			// [0] msg address
			// [1] Object name
			// [2] group
			// [3] subgroup
			var map = syncMaps.at(msg[3].asSymbol);

			if(map.notNil, {
				map.networkRemove(msg[1]);
			});
		});
	}

	*newSubGroup { arg subGroupName;
		^SyncMap.new(subGroupName);
	}

	*addSubGroup { arg subGroup;
		syncMaps[subGroup.groupName.asSymbol] = subGroup;
	}

	*update {
		syncMaps.keysValuesDo {
			arg key, value;
			value.update;
		}
	}
}

// Subclassable Map for managing OSCthulhu SyncObjects
OSCthulhuSyncMap {
	var map;
	var <>groupName;
	var <>syncClass;

	*new { arg groupName, syncClass = syncClass ? OSCthulhuSyncObject;
		^super.new.init(groupName, syncClass);
	}

	init { arg groupName, syncClass = syncClass ? OSCthulhuSyncObject;
		this.groupName = groupName;
		this.syncClass = syncClass;
		map = Dictionary.new;
		OSCthulhuSubGroupMapper.addSubGroup(this);
	}

	add { arg objectName, values;
		OSCthulhu.addSyncObject(objectName, OSCthulhu.piece ? "SuperCollider", groupName, values);
	}

	remove { arg objectName;
		OSCthulhu.removeSyncObject(objectName);
	}

	get { arg objectName;
		^map.at(objectName);
	}

	set { arg objectName, argumentIndex, value;
		OSCthulhu.setSyncArg(objectName, argumentIndex, value);
	}

	update {
		map.keysValuesDo {
			arg key, value;
			value.update;
		}
	}

	networkAdd { arg objectName, values;
		map.put(objectName, syncClass.new(objectName, groupName, values));
	}

	networkRemove { arg objectName;
		map.at(objectName.asSymbol).networkRemove; // call cleanup function
		map.removeAt(objectName.asSymbol);
	}

	networkSet { arg objectName, index, value;
		map.at(objectName.asSymbol).networkSet(index, value);
	}
}

// A synchronized wrapper for Synth
OSCthulhuSyncSynth : OSCthulhuSyncObject {

	var synth;

	init { arg objectName, objectsubGroup, values;
		// This calls the constructor for the parent class, OSCthulhuSyncObject
		super.init(objectName, objectsubGroup, values);
		synth = Synth.new(objectsubGroup, values.collect { |item, i| [i, item] }.flat);
	}

	// Override network set value
	networkSet { arg index, value;
		synth.set(index, value);
	}

	networkRemove {
		synth.set(\gate, 0); // It expects that you're using a gate envelope
	}
}

/*

// start OSCthulhu first!

// make the client send to a different port
OSCthulhu.changePorts(32244);

// make the client send to two ports
OSCthulhu.changePorts([57120,32244]);

// login to a specific piece
OSCthulhu.login("test");

// once you are logged in, you can get your user name from here
OSCthulhu.userName;

// make a new OSCdef for the various OSCthulhu message types (created and returned)
o = OSCthulhu.onAddSyncObject(\aNewAwesomeObject,{|m| m.postln;});

o.free;	// remove it when you are done.

// add a sync object
OSCthulhu.addSyncObject("awesomeObject", "test", "subgroup", [1,2.0,"three"]);

// remove it
OSCthulhu.removeSyncObject("awesomeObject");

// log out of a piece. if no one is logged into a piece, all objects for that piece are removed
OSCthulhu.cleanup("test");

// flush the server
OSCthulhu.flush;

*/