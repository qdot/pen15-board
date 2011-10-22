import processing.serial.*;
import oscP5.*;
import netP5.*;
Serial pen15;
OscP5 oscP5;
NetAddress myRemoteLocation;
int t = 0;

void initializePen15()
{
    if(Serial.list().length == 0) {
	println("No serial ports found!");
	exit();
	return;
    }
    pen15 = new Serial(this, Serial.list()[0], 9600);
}

void setup()
{
    initializePen15();
    oscP5 = new OscP5(this,12000);  
    myRemoteLocation = new NetAddress("127.0.0.1",12000);		  
    size(510, 50);
}

void draw()
{
    fill(255);
    stroke(255);
    rect(0, 0, 510, 50);
    fill(255,0,0);
    stroke(255,0,0);
    rect(t-1, 0, 3, 50);
    fill(255);
    stroke(0);
    rect(mouseX-1, 0, 3, 50);
    OscMessage myMessage = new OscMessage("/motor");
    myMessage.add(mouseX);
    oscP5.send(myMessage, myRemoteLocation); 
    pen15.write(t/2);
}

void oscEvent(OscMessage theOscMessage) {
    t = theOscMessage.get(0).intValue();
}
