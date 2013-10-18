int SyncRectCounter = 0; // Used for name generation
float SyncRectSize = 30;

/*
  SyncRect is our custom SyncObject extension
  Subclass SyncObject in 3 (or more) easy steps:
  1. Create the constructor and call super(objectNme, objectSubGroup, values)
  2. Override update to add custom functionality
  3. Create a clean interface that abstracts some of the obtuse components of the OSCthulhu API.
  
  SyncRect only has 3 arguments: x and y which are both floats and fillColor, which is an int. SyncObjects can have any number 
  of arguments of any number of sizes, but for our purposes we want our interface to be a simple
  as possible so we provide easy x/y/color methods. It's important to keep track of argument indexes.
  These are fixed in OSCthulhu and for our SyncRect 0 is always x and 1 is always y and 2 is always fillColor. This
  isn't actually determined anywhere in the SyncRect class, instead it's determined by our
  SyncMap subclass, SyncRects as defined below, inside of the add method. The argument vector
  is what ultimately determines the order of values so when making custom OSCthulhu code you will
  have to do some book keeping with argument numbers. Again, the idea is to abstract that away in
  out subclasses.
  
  Note: This will be created by our SyncRects class below. Don't instantiate these directly
*/
class SyncRect extends SyncObject
{ 
  SyncRect(String objectName, String objectSubGroup, Vector<OSCthulhuObject> values)
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
    fill(this.fillColor());
    rect(x(), y(), SyncRectSize, SyncRectSize);
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
  
  color fillColor()
  {
    return values.get(2).intValue();
  }
}

/*
  Extend SyncMap to add functionality in 4 easy steps.
  1. Create a new constructor and call super(mapper, name); Add other relvant code as needed.
  2. Create an overridden add method. This method will provide a clean interface for other objects to use. 
  This custom add method will call the more generic inherited add method which is add(String objectName, Vector<OSCthulhuObject> values);
  3. Create an overridden set method. This method will provide a clean interface for other objects to use. 
  This custom set method will call the more generic inherited set method which is set(int argumentIndex, OSCthulhuObject value);
  4. Create an overridden networkAdd method. Mainly we're just concerned with making sure the networking is adding the type we want: SyncRect
  
*/
class SyncRects extends SyncMap
{
  
  SyncRects(SubGroupMapper mapper, String name)
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
    String rectName = oscthulhu.getUserName() + "SyncRect" + SyncRectCounter++; 
     
    while(map.containsKey(rectName)) // Skip already reserved names
    {
      rectName = oscthulhu.getUserName() + "SyncRect" + SyncRectCounter++; 
    }
  
    return rectName;  
  }
  
  // Make a helper method for creating circles. This method simply sends an OSC message to the OSCthulhu client. On the reply we'll actually add the object
  String add(float x, float y)
  {
    color randomColor = color(random(255), random(255), random(255));
    
    Vector<OSCthulhuObject> values = new Vector<OSCthulhuObject>();
    values.add(new OSCthulhuObject(x)); // We need to instantiate these as OSCthulhuObjects so that our system can mix types easily
    values.add(new OSCthulhuObject(y)); // We need to instantiate these as OSCthulhuObjects so that our system can mix types easily
    values.add(new OSCthulhuObject(randomColor)); // color is really just an int, so this is ok. Normally other types are NOT ok.
    // Name generation is very important. You have to be careful about not only replacing other people's objects,
    // but also that if you have to restart your program you don't write over your own. 
    // As a general rulle of thumb it's a good idea to check if a name already exists before using it.
    String rectName = generateName();
    add(rectName, values); // Create a new SyncObject on the OSCthulhuServer
    return rectName;
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
    map.put(objectName, new SyncRect(objectName, groupName, values));  
  }
}
