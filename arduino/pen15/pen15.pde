void setup()
{
   pinMode(3,OUTPUT); 
    Serial.begin(9600);
}


void loop()
{

if(Serial.available() > 0)
{
   analogWrite(3,Serial.read()); 
}
  
  
  
}
