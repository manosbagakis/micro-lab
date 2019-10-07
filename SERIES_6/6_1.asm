/*
 * _6_1.asm
 *
 *  Created: 26/11/2017 15:51:02
 *   Author: Konstantina
 */ 
 .include "m16def.inc"
 .def temp = r22
 .def leds = r16
 .def oldc = r17
 .def olda = r18
 .def newa = r19
 .def newc = r20
 .def temp2 = r21

 reset:
	clr temp
	out DDRA, temp ;PORTA as input
	out DDRC, temp; PORTC as input
	ser temp
	out DDRB, temp ;PORTB as output

	clr leds
	out PORTB,leds

	clr olda
	clr oldc


loop1:
	in newa, PINA
	in newc, PINC
	cp newa,olda
	brne process ;if PINA has changed
	cp newc, oldc ;check if PINC has changed
	breq loop1 ;wait until input changes

process:
	mov olda, newa
	mov oldc, newc

	clr temp
	lsr olda
	eor olda, newa ; 
	andi olda, 0x01;pa1 xor pa0
	or temp, olda

	mov olda, newa
	lsr olda
	or olda, newa
	andi olda, 0x04
	lsr olda ;pa2 or pa3
	or temp, olda

	mov olda, temp
	lsr olda
	and olda, temp ;(pa2 or pa3) and (pa1 xor pa0)
	andi temp,0x02;keep only pb1
	or temp, olda

	mov olda, newa
	lsr olda
	or olda, newa
	com olda
	andi olda, 0x10
	lsr olda
	lsr olda
	or temp,olda; pa5 nor pa4

	mov olda, newa
	lsr olda
	eor olda, newa
	com olda
	andi olda, 0x40
	lsr olda
	lsr olda
	lsr olda
	or temp, olda;pa6 nxor pa7

	mov olda, newa


	mov leds, temp
	cpi newc, 0
	breq show
	eor leds, newc ;if newc != 0 reverse leds indicated by PINC
show:
	out PORTB, leds
	rjmp loop1


