/*
 * AVRAssembler4.asm
 *
 *  Created: 04/11/2017 21:37:26
 *   Author: Konstantina
 */ 


.include "m16def.inc"
.def temp=r16
.def onl=r17
.def offl=r18

reset:   ldi temp ,low(RAMEND)   ; initialize stack pointer
out SPL ,temp
ldi temp ,high(RAMEND)
out SPH ,temp

ser temp
out DDRB, temp	; PORTB as output
out PINA, temp	;
clr temp
out DDRA, temp	;PORTA as input

flash:
in temp,PINA
ldi onl,0x0f	;LSB's as on led delay
;andi onl,temp
and onl,temp
ldi offl,0xf0	;MSB's as off led delay
;andi offl,temp
and offl,temp
lsr offl
lsr offl
lsr offl
lsr offl		
inc onl
inc offl
rcall on
ldi temp, 200
mul temp, onl
mov r24,r0
mov r25,r1 
rcall wait_msec
rcall off
ldi temp, 200
mul temp, offl
mov r24,r0
mov r25,r1 
rcall wait_msec
rjmp flash






 on:
ser r26
out PORTB,r26
ret

off:
clr r26
out PORTB,r26
ret

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
