#include <avr/io.h>

int main(void)
{

	UBRR0L = 103; 
	UCSR0C = 0b00000110;
	UCSR0B = 0b00011000; 


TCCR2A = 0b00100011; // TOP = OCRA
TCCR2B = 0b00000001; // Div 1, WGM2 mode

DDRD = 0xFF;

	while(1)
	{
		OCR2B = UDR0; // Read the byte!
	}


return 0;

}
