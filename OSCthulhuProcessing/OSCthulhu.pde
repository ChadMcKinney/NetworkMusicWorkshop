import oscP5.*;
import netP5.*;
import java.util.concurrent.*; // necessary for ConcurrentHashMap
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Vector; 
import java.lang.reflect.Field; // Major haxorz, why can't we just have nice things?

// Global singleton pointer. Not ideal, but it works.
OSCthulhu OSCthulhuSingleton = null;

// Our public interface for creating actions based on messages. 
// Java doesn't have first class functions, so this is the best we can get. Not ideal.
public interface OscAction
{
  public void call(OscMessage msg);
}

// Variant type object. This is very unsafe, but necessary because OSC values of various are often mixed together
// Use with caution!
class OSCthulhuObject extends OscArgument
{
  OSCthulhuObject(Object value)
  {
    this.value = value;  
  }
  
  OSCthulhuObject(OscArgument argument)
  {
    // We want to open up our OSCthulhuObject to the OscArgument.value field. Subclassing isn't enough when assigning values from other OscArguments
    // This is a pretty big hack, but necessary so we can 
    try
    {
      Field fs = argument.getClass().getSuperclass().getDeclaredField("value");
      fs.setAccessible(true); // Hack Hack Hack Hack Hack Hack Hack Hack Hack
      this.value = fs.get(argument);  
    }
    
    catch(Exception e)
    {
      print(e);
    }  
  }
  
  void set(Object value)
  {
    this.value = value; // Be very careful! We only want boolean, int, float, double, or string! 
  }
 
  String getClassName()
  {
    return value.getClass().getSimpleName(); 
  } 
}

// Interface for create update functions for SyncObjects
public interface SyncObjectUpdate {
  public void update(Vector<OSCthulhuObject> values);  
}

// Generic class for synchronized objects
class SyncObject
{
  // object name, and the subgroup it's associated with
  String objectName, objectSubGroup;
  Vector<OSCthulhuObject> values; // vector of values for the object
  SyncObjectUpdate updateFunction; // update function
  
  protected void init(String objectName, String objectSubGroup)
  {
    this.objectName = objectName;
    this.objectSubGroup = objectSubGroup;
    
    // Here's an example of how to add an update function for the SyncObject
    updateFunction = new SyncObjectUpdate()
    {
      public void update(Vector<OSCthulhuObject> values)
      {
        // Do stuff here... 
      }
    };
  }
  
  SyncObject(String objectName, String objectSubGroup, OSCthulhuObject value)
  {
    this.values = new Vector<OSCthulhuObject>();
    values.add(value);
    this.init(objectName, objectSubGroup);
  }
  
  SyncObject(String objectName, String objectSubGroup, Vector<OSCthulhuObject> values)
  {
    this.values = values;
    this.init(objectName, objectSubGroup);
  }
  
  // Set the updateFuntion to use when the update method is called on this object
  void setUpdateFunction(SyncObjectUpdate updateFunction)
  {
    this.updateFunction = updateFunction;  
  }
  
  // Conversely you can simply extend the SyncObject class and override the update function if you want
  void update()
  {
    updateFunction.update(values);
  }
  
  void set(int index, OSCthulhuObject value)
  {
    OSCthulhuSingleton.setSyncArg(objectName, index, value);
  }
  
  OSCthulhuObject get(int index)
  {
    return values.get(index);  
  }
  
  void networkSet(int index, OSCthulhuObject value)
  {
    values.set(index, value);  
  }
}

/*
  Ideally we would use a singleton pattern or namespace interface. Java gives us the ability to do singletons, but 
  processing treats the entire program as a subclass of PApplet so we can't use the static keyword. This is because
  Java prevents the use of the static keyword with inner classes. Quagmire. Instead, you just have to be sure not
  to create two instances, and we have to rely on global variables and an OOP interface. If developing in another
  language or even just pure java, consider a different approach.
*/
class OSCthulhu
{ 
  OscP5 oscP5; // The OSC client, used to communicate with out local OSCthulhu Client
  NetAddress oscthulhuAddr; // The oscthulhu net address, which is just the default local address: 127.0.0.1
  
  String pieceName; // Used so that OSCthulhu can clean up leftover objects if everyone leaves a piece
  String userName; // This will get bounced back to use by the OSCthulhu client
  int oscthulhuPort; // Port on which to send to OSCthulhu, by default 32243
  int localPort; // Port to receive information on, let's just pick something high, 12000
  String clientAddr; // The local OSCthulhu client address: 127.0.0.1
  boolean printMessages;
  // Map for storing all our actions based on messages from the OSCthulhu server via the OSCthulhu client
  ConcurrentHashMap<String, OscAction> actionMap;
  
  // We only ever want one instance running, so we'll use a Singleton pattern
  OSCthulhu(PApplet applet, String pieceName)
  {
    OSCthulhuSingleton = this;
    localPort = 12000; // Our programs port for reveiving messages
    oscthulhuPort = 32243; // This is the port that OSCthulhu defaults to
    clientAddr = "127.0.0.1"; // address of the OSCthulhu client instance
    this.pieceName = pieceName; // The "piece name". This is a very music centric term.
    
    // Start the oscP5 client, which immediately starts listening to traffic on port 12000
    oscP5 = new OscP5(applet, localPort);
    
    /* The first arg is a remote address for sending packets to. We choose our client address, 
       which is just the local 127.0.0.1. 
       The second argument is the port on which we're listening */
    oscthulhuAddr = new NetAddress(clientAddr, oscthulhuPort); 
    
    changePort(localPort); // inform OSCthulhu of where to send it's traffic
    
    actionMap = new ConcurrentHashMap<String, OscAction>(); // Create our actionMap
    setPrintMessages(false); // Default to off, but we can turn it on if we want
  }

  void changePort(int port)
  {
    localPort = port;
    // send the OSCthulhu client an OSC message informing it to start sending it's traffic to this port
    OscMessage msg = new OscMessage("/changePorts"); // Create the message with the address pattern to change ports
    msg.add(localPort);  // Add the value that we're sending, which is our local port
    send(msg);  // send the message to OSCthulhu so that it starts sending it's traffic to our local port
  }
  
  void send(OscMessage msg) // Convenience method to make sending shorter
  {
    oscP5.send(msg, oscthulhuAddr);  // This is where we send the actual message
  }
  
  void send(String pattern) // Convenience method for simple message with no arguments sending
  {
    OscMessage msg = new OscMessage(pattern);
    send(msg);  
  }
  
  void send(String pattern, String value) // Convenience method for simple message with one argument sending
  {
    OscMessage msg = new OscMessage(pattern);
    msg.add(value);
    send(msg);  
  }
  
  void send(String pattern, float value) // Convenience method for simple message with one argument sending
  {
    OscMessage msg = new OscMessage(pattern);
    msg.add(value);
    send(msg);  
  }
  
  void send(String pattern, int value) // Convenience method for simple message with one argument sending
  {
    OscMessage msg = new OscMessage(pattern);
    msg.add(value);
    send(msg);  
  }
  
  void send(String pattern, double value) // Convenience method for simple message with one argument sending
  {
    OscMessage msg = new OscMessage(pattern);
    msg.add(value);
    send(msg);  
  }
  
  void send(String pattern, boolean value) // Convenience method for simple message with one argument sending
  {
    OscMessage msg = new OscMessage(pattern);
    msg.add(value);
    send(msg);  
  }

  void oscEvent(OscMessage msg) // All OSC events will come here first. We must parse them via their address pattern
  {
    if(actionMap.containsKey(msg.addrPattern()))
      actionMap.get(msg.addrPattern()).call(msg);
    
    if(printMessages)
    {
      print("OSCthulhu: " + msg.addrPattern() + " ");
      Object[] arguments = msg.arguments();
      
      for(int i = 0; i < arguments.length; ++i)
      {
        print(arguments[i]);
        print(" ");  
      }
      
      println(" ");
    }
  }
  
  // Add an osc action to our map
  void addAction(String pattern, OscAction action)
  {
    actionMap.put(pattern, action);  
  }
  
  // Remove an osc action from our map
  void removeAction(String pattern)
  {
    actionMap.remove(pattern);
  }
  
  void setPrintMessages(boolean printMessages)
  {
    this.printMessages = printMessages;
  }
  
  boolean getPrintMessages()
  {
    return printMessages;  
  }
  
  void login()
  {
    // Add an action to get our user name from the OSCthulhuClient. 
    // We don't set our name from here, we receive it from the client program.
    onUserName(new OscAction()
    {
      public void call(OscMessage msg)
      {
        OSCthulhuSingleton.setUserName(msg.get(0).stringValue()); 
        println("User Name is: " + OSCthulhuSingleton.getUserName());  
      }
    });
    
    send("/login", pieceName);
  }
  
  void logout()
  {
    send("/logout");  
  }
  
  void setUserName(String userName)
  {
    this.userName = userName;  
  }
  
  String getUserName()
  {
    return userName;  
  }
  
  // Convenciance class for adding arrays of arguments of mixed types to an OscMessage
  private OscMessage addArgArray(OscMessage msg, Vector<OSCthulhuObject> argArray)
  {
    for(int i = 0; i < argArray.size(); ++i)
    {
      String className = argArray.get(i).getClassName();
     
      if(className.equals("Boolean"))
      {
        msg.add(argArray.get(i).booleanValue());
      }
     
      else if(className.equals("Integer"))
      {
        msg.add(argArray.get(i).intValue());
      }  
      
      else if(className.equals("Float"))
      {
        msg.add(argArray.get(i).floatValue());
      } 
      
      else if(className.equals("Double"))
      {
        msg.add(argArray.get(i).doubleValue());
      } 
      
      else if(className.equals("Character"))
      {
        msg.add(argArray.get(i).charValue());
      } 
      
      else if(className.equals("String"))
      {
        msg.add(argArray.get(i).stringValue());
      } 
      
      else
      {
        println("Cannot addSyncArg for argument of type: " + className);  
        return msg;
      }
    }
    
    return msg;
  }
  
  //////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Client messaging interface
  //////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  // Use these methods to create changes in the network
  
  /**
  *  addSyncObject add a new sync object on the OSCthulhu server
  *  @param String the name of the object
  *  @param String the sub group name for the object
  *  @Vector<Object> The array of arguments to add. Only use booleans, ints, floats, doubles, and strings!!!!!
  *  Java is statically typed, so we have to do goofy little tricks like this.
  */
  void addSyncObject(String objectName, String objectSubGroup, Vector<OSCthulhuObject> argArray)
  {
    OscMessage msg = new OscMessage("/addSyncObject");
    msg.add(objectName);
    msg.add(pieceName);
    msg.add(objectSubGroup);
    msg = addArgArray(msg, argArray);
    send(msg);
  }
  
  void addSyncObject(String objectName, String objectSubGroup, boolean argumentValue)
  {
    OscMessage msg = new OscMessage("/addSyncObject");
    msg.add(objectName);
    msg.add(pieceName);
    msg.add(objectSubGroup);
    msg.add(argumentValue);
    send(msg);
  }
  
  void addSyncObject(String objectName, String objectSubGroup, int argumentValue)
  {
    OscMessage msg = new OscMessage("/addSyncObject");
    msg.add(objectName);
    msg.add(pieceName);
    msg.add(objectSubGroup);
    msg.add(argumentValue);
    send(msg);
  }
  
  void addSyncObject(String objectName, String objectSubGroup, float argumentValue)
  {
    OscMessage msg = new OscMessage("/addSyncObject");
    msg.add(objectName);
    msg.add(pieceName);
    msg.add(objectSubGroup);
    msg.add(argumentValue);
    send(msg);
  }
  
  void addSyncObject(String objectName, String objectSubGroup, double argumentValue)
  {
    OscMessage msg = new OscMessage("/addSyncObject");
    msg.add(objectName);
    msg.add(pieceName);
    msg.add(objectSubGroup);
    msg.add(argumentValue);
    send(msg);
  }
  
  void addSyncObject(String objectName, String objectSubGroup, char argumentValue)
  {
    OscMessage msg = new OscMessage("/addSyncObject");
    msg.add(objectName);
    msg.add(objectSubGroup);
    msg.add(argumentValue);
    send(msg);
  }
  
  void addSyncObject(String objectName, String objectSubGroup, String argumentValue)
  {
    OscMessage msg = new OscMessage("/addSyncObject");
    msg.add(objectName);
    msg.add(pieceName);
    msg.add(objectSubGroup);
    msg.add(argumentValue);
    send(msg);
  }
  
  void addSyncObject(String objectName, String objectSubGroup, OSCthulhuObject argumentValue)
  {
    OscMessage msg = new OscMessage("/addSyncObject");
    msg.add(objectName);
    msg.add(pieceName);
    msg.add(objectSubGroup);
    
    String className = argumentValue.getClassName();
     
    if(className.equals("Boolean"))
    {
      msg.add(argumentValue.booleanValue());
    }
   
    else if(className.equals("Integer"))
    {
      msg.add(argumentValue.intValue());
    }  
    
    else if(className.equals("Float"))
    {
      msg.add(argumentValue.floatValue());
    } 
    
    else if(className.equals("Double"))
    {
      msg.add(argumentValue.doubleValue());
    } 
    
    else if(className.equals("Character"))
    {
      msg.add(argumentValue.charValue());
    } 
    
    else if(className.equals("String"))
    {
      msg.add(argumentValue.stringValue());
    } 
    
    else
    {
      println("Cannot addSyncArg for argument of type: " + className);  
      return;
    }
    
    send(msg);
  }
  
  void removeSyncObject(String objectName)
  {
    send("/removeSyncObject", objectName);  
  }
  
  /**
  *  setSyncArg sets the value of a syncObject on the OSCthulhu server
  *  @param String the name of the object to alter
  *  @param int the number of the argument in the argArray supplied
  *  @param boolean The value of the argument
  *  @param boolean If true the OSCthulhuClient will immediately send back the value, allowing for a single inteface
  *  for setting values. You can set this to false if you want to have a seperate interface for directly setting
  *  values in the local instance.
  */
  void setSyncArg(String objectName, int argumentNumber, boolean argumentValue, boolean localBounce)
  {
    OscMessage msg = new OscMessage("/setSyncArg");
    msg.add(objectName);
    msg.add(argumentNumber);
    msg.add(argumentValue);
    
    if(localBounce)
      msg.add(1);
    
    send(msg);
  }
  
  // Default to localBounce = true
  void setSyncArg(String objectName, int argumentNumber, boolean argumentValue)
  {
    setSyncArg(objectName, argumentNumber, argumentValue, true);  
  }
  
  void setSyncArg(String objectName, int argumentNumber, int argumentValue, boolean localBounce)
  {
    OscMessage msg = new OscMessage("/setSyncArg");
    msg.add(objectName);
    msg.add(argumentNumber);
    msg.add(argumentValue);
    
    if(localBounce)
      msg.add(1);
    
    send(msg);
  }
  
  // Default to localBounce = true
  void setSyncArg(String objectName, int argumentNumber, int argumentValue)
  {
    setSyncArg(objectName, argumentNumber, argumentValue, true);  
  }
  
  void setSyncArg(String objectName, int argumentNumber, float argumentValue, boolean localBounce)
  {
    OscMessage msg = new OscMessage("/setSyncArg");
    msg.add(objectName);
    msg.add(argumentNumber);
    msg.add(argumentValue);
    
    if(localBounce)
      msg.add(1);
    
    send(msg);
  }
  
  // Default to localBounce = true
  void setSyncArg(String objectName, int argumentNumber, float argumentValue)
  {
    setSyncArg(objectName, argumentNumber, argumentValue, true);  
  }
  
  void setSyncArg(String objectName, int argumentNumber, double argumentValue, boolean localBounce)
  {
    OscMessage msg = new OscMessage("/setSyncArg");
    msg.add(objectName);
    msg.add(argumentNumber);
    msg.add(argumentValue);
    
    if(localBounce)
      msg.add(1);
    
    send(msg);
  }
  
  // Default to localBounce = true
  void setSyncArg(String objectName, int argumentNumber, double argumentValue)
  {
    setSyncArg(objectName, argumentNumber, argumentValue, true);  
  }
  
  void setSyncArg(String objectName, int argumentNumber, char argumentValue, boolean localBounce)
  {
    OscMessage msg = new OscMessage("/setSyncArg");
    msg.add(objectName);
    msg.add(argumentNumber);
    msg.add(argumentValue);
    
    if(localBounce)
      msg.add(1);
    
    send(msg);
  }
  
  // Default to localBounce = true
  void setSyncArg(String objectName, int argumentNumber, char argumentValue)
  {
    setSyncArg(objectName, argumentNumber, argumentValue, true);  
  }
  
  void setSyncArg(String objectName, int argumentNumber, String argumentValue, boolean localBounce)
  {
    OscMessage msg = new OscMessage("/setSyncArg");
    msg.add(objectName);
    msg.add(argumentNumber);
    msg.add(argumentValue);
    
    if(localBounce)
      msg.add(1);
    
    send(msg);
  }
  
  // Default to localBounce = true
  void setSyncArg(String objectName, int argumentNumber, String argumentValue)
  {
    setSyncArg(objectName, argumentNumber, argumentValue, true);  
  }
  
  void setSyncArg(String objectName, int argumentNumber, OSCthulhuObject argumentValue, boolean localBounce)
  {
    OscMessage msg = new OscMessage("/setSyncArg");
    msg.add(objectName);
    msg.add(argumentNumber);
    
    String className = argumentValue.getClassName();
     
    if(className.equals("Boolean"))
    {
      msg.add(argumentValue.booleanValue());
    }
   
    else if(className.equals("Integer"))
    {
      msg.add(argumentValue.intValue());
    }  
    
    else if(className.equals("Float"))
    {
      msg.add(argumentValue.floatValue());
    } 
    
    else if(className.equals("Double"))
    {
      msg.add(argumentValue.doubleValue());
    } 
    
    else if(className.equals("Character"))
    {
      msg.add(argumentValue.charValue());
    } 
    
    else if(className.equals("String"))
    {
      msg.add(argumentValue.stringValue());
    } 
    
    else
    {
      println("Cannot addSyncArg for argument of type: " + className);  
      return;
    }
    
    if(localBounce)
      msg.add(1);
    
    send(msg);
  }
  
  // Default to localBounce = true
  void setSyncArg(String objectName, int argumentNumber, OSCthulhuObject argumentValue)
  {
    setSyncArg(objectName, argumentNumber, argumentValue, true);  
  }
  
  void chat(String message)
  {
    send("/chat", message);  
  }
  
  // Flush all the arguments out of the OSCthulhu server/client system. Don't use this unless something has gone wrong
  void flush()
  {
    send("/flush");  
  }
  
  // Ask the server to clean  up all the objects specific to a piece.Again, don't use this normally.
  void cleanup(String pieceName)
  {
    send("/cleanup", pieceName);  
  }
  
  void cleanup()
  {
    send("/cleanup", pieceName);  
  }
  
  void getChat()
  {
      send("/getChat");
  }
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Client response interface
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  // Use these methods to add responses to changes in the network

  void onAddSyncObject(OscAction action)
  {
    addAction("/addSyncObject", action);  
  }

  void onSetSyncArg(OscAction action)
  {
    addAction("/setSyncArg", action);  
  }
  
  void onRemoveSyncObject(OscAction action)
  {
    addAction("/removeSyncObject", action);  
  }
  
  void onAddPeer(OscAction action)
  {
    addAction("/addPeer", action);  
  }
  
  void onRemovePeer(OscAction action)
  {
    addAction("/removePeer", action);  
  }
  
  void onChat(OscAction action)
  {
    addAction("/chat", action);  
  }
  
  void onGetChat(OscAction action)
  {
    addAction("/getChat", action);  
  }
  
  void onUserName(OscAction action)
  {
    addAction("/userName", action);  
  }
  
  void onPorts(OscAction action)
  {
    addAction("/ports", action);  
  }
}

// One approach to networking with OSCthulhu is to create a SubGroupMapper to filter messages to specific maps of objects.
// This way you have a simple interface for creating, manipulating, and destroying objects.
// This method isn't the most efficient, but it's easier to work with.
// This is literally a map of maps.

SubGroupMapper SubGroupMapperSingleton = null; // Global variable. Ugly, but again, we can't use static variables :(

class SubGroupMapper
{
  ConcurrentHashMap<String, SyncMap> syncMaps;
  OSCthulhu oscthulhu; // current oscthulhu instance

  // The oscthulhu argument is for cleanliness of the interface, but also to guarantee you aren't making a SubGroupMapper without
  // having already made an oscthulhu instance
  SubGroupMapper(OSCthulhu oscthulhu)
  {
    this.oscthulhu = oscthulhu;
    SubGroupMapperSingleton = this;
    syncMaps = new ConcurrentHashMap<String, SyncMap>();
    
    // Create /addSyncObject response
    oscthulhu.onAddSyncObject(new OscAction()
    { 
      // msg format: [0] ObjectName [1] Group [2] SubGroup [3+] arguments
      public void call(OscMessage msg)
      {
        SyncMap map = SubGroupMapperSingleton.get(msg.get(2).stringValue());
        if(map != null)
        {
          Vector<OSCthulhuObject> oscthulhuArguments = new Vector<OSCthulhuObject>();
          Object[] arguments = msg.arguments();
          
          // Collect the arguments
          for(int i = 3; i < arguments.length; ++i)
          {
            oscthulhuArguments.add(new OSCthulhuObject(arguments[i]));
          }
          
          map.networkAdd(msg.get(0).stringValue(), oscthulhuArguments); 
        }
      }  
    });
    
    // create /setSyncArg response
    oscthulhu.onSetSyncArg(new OscAction()
    {
      // msg format: [0] ObjectName [1] Argument Index [2] Argument Value [3] Group [4] SubGroup
      public void call(OscMessage msg)
      {
        Object[] arguments = msg.arguments();
        SyncMap map = SubGroupMapperSingleton.get(msg.get(4).stringValue());
        map.networkSet(msg.get(0).stringValue(), msg.get(1).intValue(), new OSCthulhuObject(arguments[2]));
      }  
    });
    
    oscthulhu.onRemoveSyncObject(new OscAction()
    {
      // msg format: [0] objectName [1] Group Name [2] SubGroup name
      public void call(OscMessage msg)
      {
        SyncMap map = SubGroupMapperSingleton.get(msg.get(2).stringValue());
        map.networkRemove(msg.get(0).stringValue());
      }  
    });
  }
  
  // Create a generic subGroup. Not terribly usefule except for basic use. More ideal is to subclass SyncMap
  SyncMap addSubGroup(String subGroup)
  {
    SyncMap map = new SyncMap(this, subGroup);
    return map;
  }
  
  // Useful for adding subclasses of SyncMap. Polymorphism is your friend.
  void addSubGroup(SyncMap map)
  {
    syncMaps.put(map.getName(), map); 
  }
  
  void removeSubGroup(String subGroup)
  {
    // Call remove all then remove the syncmap itself 
    SyncMap map = syncMaps.get(subGroup);
    
    if(map != null)
    {
      map.removeAll();
      syncMaps.remove(subGroup);
    }
  }
  
  SyncMap get(String subGroup)
  {
    return syncMaps.get(subGroup);
  }
  
  void update() // Update all the subgroups, which subsequently updates all the registered sync objects
  {
    for(SyncMap syncMap : syncMaps.values())
    {
      syncMap.update();  
    }
  }
}

// A synchronized map which synchronizes the creation, manipulation, and destruction of sync objects. 
// For more utility try extending this class creating your own similar to it.
// Please note that the interface is networked and no changes are immediate. Changes only occur on the bounce back from the network. 
// To best use this class, don't depend on anything happening at a specific time, or an object existing specifically
class SyncMap
{
  SubGroupMapper mapper; // Reference to the mapper that this SyncMap is inside
  protected ConcurrentHashMap<String, SyncObject> map;
  protected String groupName;
  
  SyncMap(SubGroupMapper mapper, String groupName)
  {
    map = new ConcurrentHashMap<String, SyncObject>();
    this.mapper = mapper;
    this.groupName = groupName;
    mapper.addSubGroup(this); // Add the SyncMap instance to the mapper.
  }
  
  /////////////////////////////////////////////////////////////////////////////////
  // Use this functions directly
  /////////////////////////////////////////////////////////////////////////////////
  
  void add(String objectName, OSCthulhuObject value)
  {
    OSCthulhuSingleton.addSyncObject(objectName, groupName, value);
  }
  
  void add(String objectName, Vector<OSCthulhuObject> values)
  {
    OSCthulhuSingleton.addSyncObject(objectName, groupName, values);
  }
  
  void remove(String objectName)
  {
    OSCthulhuSingleton.removeSyncObject(objectName);
  }
  
  // Probably don't want to use this unless you have a good reason. The SyncMap interface is networked and is usually ideal when making changes.
  SyncObject get(String objectName)
  {
    return map.get(objectName);  
  }
  
  void set(String objectName, int argumentIndex, OSCthulhuObject value)
  {
    OSCthulhuSingleton.setSyncArg(objectName, argumentIndex, value);
  }
  
  // Set all members arguments of a specific index. Useful for mass changes.
  void setAll(int argumentIndex, OSCthulhuObject value)
  {
    Iterator<Entry<String, SyncObject>> it = map.entrySet().iterator();
    while(it.hasNext())
    {
      Entry<String, SyncObject> entry = it.next();
      set(entry.getKey(), argumentIndex, value);
    }
  }
  
  void removeAll()
  {
    Iterator<Entry<String, SyncObject>> it = map.entrySet().iterator();
    while(it.hasNext())
    {
      Entry<String, SyncObject> entry = it.next();
      remove(entry.getKey());
    }
  }
  
  // Update all the values of the map
  void update()
  {
    for(SyncObject object : map.values())
    {
      object.update();  
    }
  }
  
  // set a custom update function for a SyncObject. This is useful if you don't want to subclass SyncObject
  // As a general rule of thumb a subclass will be more useful.
  void setUpdateFunction(String objectName, SyncObjectUpdate updateFunction)
  {
    SyncObject object = map.get(objectName);
    if(object != null)
      object.setUpdateFunction(updateFunction);  
  }
  
  String getName()
  {
    return groupName;  
  }
  
  //////////////////////////////////////////////////////////////////////////////////
  // Do not use these directly, they get called by OSCthulhu
  //////////////////////////////////////////////////////////////////////////////////
  
  void networkAdd(String objectName, Vector<OSCthulhuObject> values)
  {
    map.put(objectName, new SyncObject(objectName, groupName, values));  
  }
  
  void networkRemove(String objectName)
  {
    map.remove(objectName);  
  }
  
  void networkSet(String objectName, int argumentIndex, OSCthulhuObject value)
  {
    SyncObject object = map.get(objectName);
    if(object != null)
      object.networkSet(argumentIndex, value);   
  }
}
