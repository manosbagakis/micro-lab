/*
 * AVRAssembler1.asm
 *
 *  Created: 04/11/2017 20:00:49
 *   Author: Konstantina
 */ 
 .include "m16def.inc"

 .def temp=r16
 .def temp1=r17
 

reset:   ldi temp ,low(RAMEND)   ; initialize stack pointer
out SPL ,temp
ldi temp ,high(RAMEND)
out SPH ,temp
 
 start: 
 ser temp
 out DDRB, temp ;???a ? ?? ???d??
 ;out PORTA, temp ;pull-up ???a? ?
 clr temp
 out DDRA, temp ;???a ? ?? e?s?d??
 ldi temp, 0x01 ;de??a led
 ldi r24,low(500)
 ldi r25,high(500)
 out PORTB,temp
ldi temp, 0x01 ;de??a led
 right:
 ;in temp1,PINA
 ;cpi temp1,0x01
 ;brne right
 sbis PINA,0
 rjmp right
 cpi temp, 0x80
 breq left
 sbrc temp,7
 rjmp left
 lsl temp
 out PORTB, temp
 ldi r24,low(500)
 ldi r25,high(500)
rcall wait_msec
 rjmp right
 left:
 ;in temp1, PINA
 ;cpi temp1, 0x01
 ;brne left
 sbis PINA,0
 rjmp left
 ;cpi temp, 0x01
 ;breq right
 sbrc temp,0
 rjmp right
 lsr temp
 out PORTB, temp
  ldi r24,low(500)
 ldi r25,high(500)
 rcall wait_msec
 rjmp left
 end:

wait_usec:
sbiw r24,1
nop
nop
nop
nop
brne wait_usec
ret

wait_msec:

push r24
push r25
ldi r24, low(998)
ldi r25, high(998)
rcall wait_usec
pop r25
pop r24
sbiw r24,1
brne wait_msec
ret



