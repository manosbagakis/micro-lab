/*
 * AVRAssembler4.asm
 *
 *  Created: 26/11/2017 12:43:50 ??
 *   Author: arv_c
 */


.include "m16def.inc"


.DSEG
_tmp_: .byte 2

.CSEG

 .def temp = r26
 .def first_digit = r19
 .def second_digit = r18
 .def loop_cnt = r27

	ser temp
	ldi temp ,(1 << PC7) | (1 << PC6) | (1 << PC5) | (1 << PC4) ; ����� �� ������� �� 4 MSB
	out DDRC ,temp ;
	ser temp
	out DDRB ,temp	;Port B as output

	ldi temp ,low(RAMEND)   ;initialize stack pointer
	out SPL ,temp
	ldi temp ,high(RAMEND)
	out SPH ,temp


mainp:
	clr temp
	out PORTB,temp  ; initially output leds are OFF

loop_1st:
	ldi r24,0x05 ; 5ms delay between checking keyboard state
	rcall scan_keypad_rising_edge
	mov temp,r24
	add temp,r25
	cpi temp,0x00 ; if not button was pressed , read again
	breq loop_1st

	rcall keypad_to_ascii ; since a button was pressed , put ascii value in register
	mov first_digit,r24

loop_2nd:
	ldi r24,0x05 ;5m delay between checking keyboard state
	rcall scan_keypad_rising_edge
	mov temp,r24
	add temp,r25
	cpi temp,0x00 ; if not button was pressed , read again
	breq loop_2nd
	
	rcall keypad_to_ascii ; since a buttton was pressed , put ascii value in register
	mov second_digit,r24

	cpi first_digit,'1' ; if first digit was '1'
	brne wrong_pass

	cpi second_digit,'2' ; and the second was '2'
	brne wrong_pass

correct_pass: ; open leds for 4 seconds
	ser temp
	out PORTB, temp
	ldi r24,low(4000)
	ldi r25,high(4000)
	rcall wait_msec  ;4 sec delay
	rjmp mainp  ;continuous runtime program

wrong_pass: ; if 2 digits werent '1' , '2'
	ldi loop_cnt,0x08 ; turn leds on for 0,25 sec , turn leds off for 0,25 sec, do this 8 times ( 4seconds total)
loop_wrong:
	ser temp
	out PORTB,temp
	ldi r24,low(250)
	ldi r25,high(250)
	rcall wait_msec  ;0.25 sec delay
	clr temp
	out PORTB,temp
	ldi r24,low(250)
	ldi r25,high(250)
	rcall wait_msec  ;0.25 sec delay
	dec loop_cnt
	cpi loop_cnt,0x00
	brne loop_wrong
	rjmp mainp

scan_row:
	ldi r25 , 0x08 ;
back_: lsl r25 ;
	dec r24
	brne back_
	out PORTC , r25
	nop
	nop
	in r24 , PINC
	andi r24 ,0x0f
	ret

scan_keypad:
	ldi r24 , 0x01
	rcall scan_row
	swap r24
	mov r27 , r24
	ldi r24 ,0x02
	rcall scan_row
	add r27 , r24
	ldi r24 , 0x03
	rcall scan_row
	swap r24
	mov r26 , r24
	ldi r24 ,0x04
	rcall scan_row
	add r26 , r24
	movw r24 , r26
	ret


scan_keypad_rising_edge:
	mov r22 ,r24
	rcall scan_keypad
	push r24
	push r25
	mov r24 ,r22
	ldi r25 ,0
	rcall wait_msec
	rcall scan_keypad
	pop r23
	pop r22
	and r24 ,r22
	and r25 ,r23
	ldi r26 ,low(_tmp_)
	ldi r27 ,high(_tmp_)
	ld r23 ,X+
	ld r22 ,X
	st X ,r24
	st -X ,r25
	com r23
	com r22
	and r24 ,r22
	and r25 ,r23
	ret

keypad_to_ascii:
	movw r26 ,r24
	ldi r24 ,'*'
	sbrc r26 ,0
	ret
	ldi r24 ,'0'
	sbrc r26 ,1
	ret
	ldi r24 ,'#'
	sbrc r26 ,2
	ret
	ldi r24 ,'D'
	sbrc r26 ,3
	ret
	ldi r24 ,'7'
	sbrc r26 ,4
	ret
	ldi r24 ,'8'
	sbrc r26 ,5
	ret
	ldi r24 ,'9'
	sbrc r26 ,6
	ret
	ldi r24 ,'C'
	sbrc r26 ,7
	ret
	ldi r24 ,'4'
	sbrc r27 ,0
	ret
	ldi r24 ,'5'
	sbrc r27 ,1
	ret
	ldi r24 ,'6'
	sbrc r27 ,2
	ret
	ldi r24 ,'B'
	sbrc r27 ,3
	ret
	ldi r24 ,'1'
	sbrc r27 ,4
	ret
	ldi r24 ,'2'
	sbrc r27 ,5
	ret
	ldi r24 ,'3'
	sbrc r27 ,6
	ret
	ldi r24 ,'A'
	sbrc r27 ,7
	ret
	clr r24
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
