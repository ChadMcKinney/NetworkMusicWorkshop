/*
NIME 2013: Networked Interfaces Workshop
Instructor: Chad McKinney
email: seppukuzombie@gmail.com
web: www.chadmckinneyaudio.com

The workshop code is all public domain.
OSCthulhu is licensed under the GPL version 3 license.
*/

import java.awt.event.KeyEvent;

boolean ctrlDown = false;
OSCthulhu oscthulhu; // object used for communicating with OSCthulhu
SubGroupMapper mapper; // object used to organize network data between various groups
SyncCircles circles; // A SyncMap used to control circles
SyncRects rects;
boolean toggle;
String lastCircleName; // Name of the last circle created. We don't hold on to actual objects, that's what SyncCircles is for.
String lastRectName; // Name of the last rect created. We don't hold on to actual objects, that's what SyncRects is for.

void setup()
{
  // Normal Processing setup stuff
  size(800, 600);
  background(0, 80, 150);
  smooth();
  frameRate(60);
  rectMode(CENTER);
  
  // Set up OSCthulhu, passing this, which is our application, effectively a PApplet subclass
  oscthulhu = new OSCthulhu(this, "Workshop"); // All participants in the same "piece" should use the same name
  mapper = new SubGroupMapper(oscthulhu); // This allows for easy parsing of messages. The hard work has been done for you!
  circles = new SyncCircles(mapper, "Circles"); // Our subclass of SyncMap, allows for easy creation/manipulation/deletion over the network
  rects = new SyncRects(mapper, "Rects"); // Our subclass of SyncMap, allows for easy creation/manipulation/deletion over the network
  oscthulhu.login(); // Login as the last thing you do! VERY IMPORTANT! This will tell OSCthulhu to send the entire state of the network.
  toggle = false;
}

void draw()
{
  background(0, 80, 150);
  mapper.update(); // Call update on the mapper. This updates everything in the map, and in our example draws the circles.
}

void mouseMoved()
{
  if(lastCircleName != null)
    circles.set(lastCircleName, mouseX, mouseY);
    
  if(lastRectName != null)
    rects.set(lastRectName, mouseX, mouseY);
}

void mousePressed()
{
  if(!toggle)
  {
    if(mouseButton == LEFT)
      lastCircleName = circles.add(mouseX, mouseY);
    else
      lastRectName = rects.add(mouseX, mouseY);
  }
  
  else if(lastCircleName != null)
  {
    circles.remove(lastCircleName); 
    lastCircleName = null;
  }
  
  else if(lastRectName != null)
  {
    rects.remove(lastRectName); 
    lastRectName = null;
  }
  
  toggle = !toggle; // toggle our toggle flag
}

void mouseReleased()
{
   
}

// For those curious about multiple key detection in processing, see this wiki entry:
// http://wiki.processing.org/w/Multiple_key_presses
void keyPressed()
{
  switch(keyCode)
  {
  case UP:
    break;
  
  case DOWN:
    break;
  
  case LEFT:
    break;
  
  case RIGHT:
    break;  
    
  case CONTROL:
    ctrlDown = true;
    break;
    
  case KeyEvent.VK_F1: // Toggle message printing
    oscthulhu.setPrintMessages(!oscthulhu.getPrintMessages());
    break;
    
  case KeyEvent.VK_Q: // Using explicit Java calls, this quits correctly.
    print("quit");
    if(ctrlDown)
      exit();
    break;
    
  }
  
  switch(key)
  {  
  case 'q': // This should work with ctrl-q, but processing isn't being awesome. At all.
    print("quit");
    if(ctrlDown)
      exit();
    break;
  }
}

void keyReleased()
{
  switch(keyCode)
  {
  case UP:
    break;
  
  case DOWN:
    break;
  
  case LEFT:
    break;
  
  case RIGHT:
    break;  
    
  case CONTROL:
    ctrlDown = false;
    break;
  }
  
  switch(key)
  {  
  case 'q':
    break;
  }
}

void oscEvent(OscMessage msg)
{
  oscthulhu.oscEvent(msg); // send the msg to our OSCthulhu instance for parsing
}

void exit()
{
  oscthulhu.logout();
  super.exit(); 
}
