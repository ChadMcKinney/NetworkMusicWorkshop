int SyncCircleCounter = 0; // Used for name generation
float SyncCircleSize = 30;

/*
  SyncCircle is our custom SyncObject extension
  Subclass SyncObject in 3 (or more) easy steps:
  1. Create the constructor and call super(objectNme, objectSubGroup, values)
  2. Override update to add custom functionality
  3. Create a clean interface that abstracts some of the obtuse components of the OSCthulhu API.
  
  SyncCircle only has 2 arguments: x and y which are both floats. SyncObjects can have any number 
  of arguments of any number of sizes, but for our purposes we want our interface to be a simple
  as possible so we provide easy x/y methods. It's important to keep track of argument indexes.
  These are fixed in OSCthulhu and for our SyncCircle 0 is always X and 1 is always Y. This
  isn't actually determined anywhere in the SyncCircle class, instead it's determined by our
  SyncMap subclass, SyncCircles as defined below, inside of the add method. The argument vector
  is what ultimately determines the order of values so when making custom OSCthulhu code you will
  have to do some book keeping with argument numbers. Again, the idea is to abstract that away in
  out subclasses.
  
  Note: This will be created by our SyncCircles class below. Don't instantiate these directly
*/
class SyncCircle extends SyncObject
{ 
  SyncCircle(String objectName, String objectSubGroup, Vector<OSCthulhuObject> values)
  {
    super(objectName, objectSubGroup, values); // pass arguments to parent class  
  }
  
  // OVerride update to add custom functionality
  void update()
  {
     draw();
  } 
  
  void draw()
  {
    fill(200, 0, 100);
    ellipse(x(), y(), SyncCircleSize, SyncCircleSize);
  }
  
  // Abstracting away the obtuse OSCthulhu variabt type interface.
  float x()
  {
    return values.get(0).floatValue();
  }
  
  float y()
  {
    return values.get(1).floatValue();
  }
  
  void setX(float x)
  {
    set(0, x);  
  }
  
  void setY(float y)
  {
    set(1, y);
  }
  
  void set(float x, float y)
  {
    set(0, x);
    set(1, y);
  }
}

/*
  Extend SyncMap to add functionality in 4 easy steps.
  1. Create a new constructor and call super(mapper, name); Add other relvant code as needed.
  2. Create an overridden add method. This method will provide a clean interface for other objects to use. 
  This custom add method will call the more generic inherited add method which is add(String objectName, Vector<OSCthulhuObject> values);
  3. Create an overridden set method. This method will provide a clean interface for other objects to use. 
  This custom set method will call the more generic inherited set method which is set(int argumentIndex, OSCthulhuObject value);
  4. Create an overridden networkAdd method. Mainly we're just concerned with making sure the networking is adding the type we want: SyncCircle
  
*/
class SyncCircles extends SyncMap
{
  
  SyncCircles(SubGroupMapper mapper, String name)
  {
    super(mapper, name);
  }
  
  String generateName()
  {
    // Name generation is very important. You have to be careful about not only replacing other people's objects,
    // but also that if you have to restart your program you don't write over your own. 
    // As a general rulle of thumb it's a good idea to check if a name already exists before using it.
    // It's also a good idea to append your userName to an object, not for ownership, but just
    // So that you aren't overwriting something that somebody else created
    String circleName = oscthulhu.getUserName() + "SyncCircle" + SyncCircleCounter++; 
     
    while(map.containsKey(circleName))
    {
      circleName = oscthulhu.getUserName() + "SyncCircle" + SyncCircleCounter++; 
    }
  
    return circleName;  
  }
  
  // Make a helper method for creating circles. This method simply sends an OSC message to the OSCthulhu client. On the reply we'll actually add the object
  String add(float x, float y)
  {
    Vector<OSCthulhuObject> values = new Vector<OSCthulhuObject>();
    values.add(new OSCthulhuObject(x)); // We need to instantiate these as OSCthulhuObjects so that our system can mix types easily
    values.add(new OSCthulhuObject(y)); // We need to instantiate these as OSCthulhuObjects so that our system can mix types easily
    // Name generation is very important. You have to be careful about not only replacing other people's objects,
    // but also that if you have to restart your program you don't write over your own. 
    // As a general rulle of thumb it's a good idea to check if a name already exists before using it.
    String circleName = generateName();
    add(circleName, values); // Create a new SyncObject on the OSCthulhuServer
    return circleName;
  }
  
  void set(String objectName, float x, float y)
  {
    // This is a bit obtuse with having to use new OSCthulhuObject. Other languages can do this cleaner. Work with what you got.
    set(objectName, 0, new OSCthulhuObject(x)); // We need to instantiate these as OSCthulhuObjects so that our system can mix types easily
    set(objectName, 1, new OSCthulhuObject(y)); // We need to instantiate these as OSCthulhuObjects so that our system can mix types easily
  }
  
  // Be sure to override network add so that the right Class is being instantiated on /addSyncObject
  // Do not call his directly!
  void networkAdd(String objectName, Vector<OSCthulhuObject> values)
  {
    map.put(objectName, new SyncCircle(objectName, groupName, values));  
  }
}
