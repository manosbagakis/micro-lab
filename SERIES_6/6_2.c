/*
 * _6_2.c
 *
 * Created: 25/11/2017 10:08:45
 *  Author: Konstantina
 */ 

#include <avr/io.h>

int main(void)
{
	unsigned char A,B,C,D,E,F0,F1,F2;
	DDRA = 0x00;
	DDRC = 0xFF;
    while(1)
    {
       A = (PINA & 0x01);
	   B =  (PINA & 0x02)>>1;
	   C = (PINA & 0x04)>>2;
	   D = (PINA & 0x08)>>3;
	   E = (PINA & 0x10)>>4;
	   
	   A = A & B & C;
	   C = C & D;
	   B = D & E;
	   D = (!D) & (!E);
	   F0 = !(A | C | B);
	   F1 = A | D;
	   F2 = F0 | F1;
	   F0 = (F0 << 5);
	   F1 = (F1 << 6);
	   F2 = (F2 << 7);
	   PORTC = (F0 | F1 | F2);
    }
}