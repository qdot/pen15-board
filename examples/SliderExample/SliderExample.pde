import processing.serial.*;

Serial pen15;

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
	size(510, 50);
}

void draw()
{
	rect(0, 0, 510, 50);
	rect(mouseX-1, 0, 3, 50);
	pen15.write(mouseX/2);
}


