/*
 * AVRGCC1.c
 *
 * Created: 05/11/2017 13:35:49
 *  Author: Konstantina kai emeis
 */ 

#include <avr/io.h>


int main(void)
{	unsigned char z;
	
	DDRA = 0xFF;
	DDRC = 0x00;

	PORTA = 0x80;
    while(1)
    {
        if ((PINC&0x10)==0x10)
		{
			while((PINC&0x10)==0x10);
			PORTA = 0x80;
		}
		else if ((PINC&0x08) ==0x08)
		{
			while((PINC&0x08)==0x08);
			//PORTA = PORTA <<1;
			//PORTA = PORTA <<1;
			PORTA = (PORTA << 2) | (PORTA >> (8-2)); //ROTATE NOT SHIFTING
		}
		else if ((PINC & 0x04) == 0x04)
		{
			while((PINC&0x04)==0x04);
			//PORTA = PORTA >>1;
			//PORTA = PORTA >>1;
			PORTA = (PORTA >> 2) | (PORTA << (8-2)); //ROTATE NOT SHIFTING
		}
		else if ((PINC & 0x02) == 0x02)
		{
			while((PINC&0x02)==0x02);
			//PORTA <<1;
			PORTA = (PORTA << 1) | (PORTA >> (8-1)); //ROTATE NOT SHIFTING	
		}
		else if ((PINC & 0x01) == 0x01)
		{
			while((PINC&0x01)==0x01);
			//PORTA >> 1;
			PORTA = (PORTA >> 1) | (PORTA << (8-1)); //ROTATE NOT SHIFTING
		}
		
    }
	return 0;
}
