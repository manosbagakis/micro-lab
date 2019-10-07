.DSEG
_tmp_: .byte 2
.CSEG


.include "m16def.inc"
.def temp = r17

.def ten = r19
.def temp_LSB = r16
.def temp_MSB = r21
.def decim = r20
.def hundreds = r22
start:
	ldi temp ,low(RAMEND)   ;initialize stack pointer
  	out SPL ,temp
  	ldi temp ,high(RAMEND)
  	out SPH ,temp

  	ser temp

  	out DDRA,temp	;PortA output
	  out PORTA,temp	;Pull up resistors
  	out DDRD,temp	; Output for LCD Device
	  out DDRB,temp
	  rcall lcd_init
main_p:
		//rcall get_temp_from_keyb
		rcall get_temp

		mov temp_MSB, r25 ;temp_MSB has 8 msb input
		mov temp_LSB, r24 ;temp_LSB has 8 lsb input

print:
	rcall lcd_init ; initialize lcd screen

	cpi temp_MSB,0x80 ;if input is 8000
	breq not_connected1 ; then no device is connected
	cpi temp_MSB,0x00  ; if sign extension is zeros
	breq positive_print ; go to positive print ( print '+')
negative_print:
	neg temp_LSB ; if sign extension is ff we are dealing with a negative number , comp_2 because that is stored in temp_LSB (return val of get* routines)
	lsr temp_LSB ; shift the number by one , since lsb has an accuracy of 0.5
	cpi temp_LSB, 0x00  ; in case of  lsb input being 00 -> skip '+' printing
	breq skip_sign	;if i'm zero do not print sign

	ldi r24, '-' ;since i'm dealing with a negative number print '-'
	rcall lcd_data
	mov temp, temp_LSB ; move 8lsb input to temp and start calculating output
	rcall print_temp
	ldi r24, 0b10110010 ;print '°'
	rcall lcd_data
	ldi r24, 'C'
	rcall lcd_data

	rjmp main_p
positive_print:
	lsr temp_LSB;shift the numbe rby one , since lsb has an accuracy of 0.5
	cpi temp_LSB, 0x00 ; if input is zero dont print '+'
	breq skip_sign	;if i'm zero launch to hero (and skip sign on your way)
	ldi r24, '+'
	rcall lcd_data

skip_sign:
	mov temp, temp_LSB
	rcall print_temp

	ldi r24, 0b10110010 ;print '°C'
	rcall lcd_data
	ldi r24, 'C'
	rcall lcd_data
	rjmp main_p

not_connected1: ; if no device is connected load 0x8000 in r25:r24
	rcall print_disconnect
	rjmp main_p

; routine to print temperature in lcd
print_temp:
	clr hundreds
	clr ten
print_dec: ; count number of hundreds , tens and units . Print them in lcd
  cpi temp,0x64
  brlo ten_loop
  subi temp,0x64
  ldi hundreds, 1
ten_loop:
  cpi temp,0x0A
  brlo units
  inc ten
  subi temp,0x0A
  rjmp ten_loop

units:
  cpi hundreds, 0x01
	breq print_3digits
	cpi ten, 0x01
	brge print_2digits
	rjmp print_1digit
print_3digits:
	ldi r24,'0'
	add r24, hundreds
	rcall lcd_data
print_2digits:
	ldi r24, '0'
	add r24, ten
	rcall lcd_data
print_1digit:
	ldi r24,'0'
	add r24, temp
	rcall lcd_data
end:
	ret

get_temp:	;returns comp_2 of temperature in r25:r24
	rcall one_wire_reset ; wait until a device is connected
	cpi r24,0
	breq not_connected

	ldi r24,0xCC ; only one input device
	rcall one_wire_transmit_byte
	ldi r24,0x44 ; start measuring
	rcall one_wire_transmit_byte

wait_measure_to_end:
	rcall one_wire_receive_bit ; is the measurement over ?
	sbrs r24,0
	rjmp wait_measure_to_end

	rcall one_wire_reset ; wait until a device is connected
	cpi r24,0
	breq not_connected

	ldi r24,0xCC ; only one input device
	rcall one_wire_transmit_byte
	ldi r24,0xBE
	rcall one_wire_transmit_byte ; send me the result
	rcall one_wire_receive_byte ; receive 8 LSB
	mov temp,r24 ; temp has 8 LSB

	rcall one_wire_receive_byte ; receive 8 MSB

	mov r25, r24 ; r25 has 8 MSB
	mov r24, temp ; r24 has 8 LSB

calculate_result:
	sbrc r25,0
	dec temp
	rjmp print1

not_connected: ; if no device is connected load 0x8000 in r25:r24
	ldi r25,0x80
	ldi r24,0x00
	clr temp ; when disconnected temp=0 and zero on output
print1:
;We are printing real_temp*2
;Erwthsh gia to swsto typwma
	out PORTB,temp
	ret

get_temp_from_keyb:
	ldi r24 ,(1 << PC7) | (1 <<PC6) | (1 <<PC5) | (1 <<PC4)
  out DDRC ,r24 ;initialize keyboard

	loop_1st:
	ldi r24,0x05 ; 5ms delay between checking keyboard state
	rcall scan_keypad_rising_edge
	mov temp,r24
	or temp,r25
	cpi temp,0x00 ; if not button was pressed , read again
	breq loop_1st
	rcall keypad_to_hex
	mov r18, r24
	lsl r18
	lsl r18
	lsl r18
	lsl r18
	loop_2nd:
	ldi r24,0x05 ; 5ms delay between checking keyboard state
	rcall scan_keypad_rising_edge
	mov temp,r24
	or temp,r25
	cpi temp,0x00 ; if not button was pressed , read again
	breq loop_2nd
	rcall keypad_to_hex
	add r18, r24


	loop_3rd:
	ldi r24,0x05 ; 5ms delay between checking keyboard state
	rcall scan_keypad_rising_edge
	mov temp,r24
	or temp,r25
	cpi temp,0x00 ; if not button was pressed , read again
	breq loop_3rd
	rcall keypad_to_hex
	mov r16, r24
	lsl r16
	lsl r16
	lsl r16
	lsl r16

	loop_4th:
	ldi r24,0x05 ; 5ms delay between checking keyboard state
	rcall scan_keypad_rising_edge
	mov temp,r24
	or temp,r25
	cpi temp,0x00 ; if not button was pressed , read again
	breq loop_4th
	rcall keypad_to_hex

	mov r25, r18
	add r24, r16
	ret

print_disconnect:
	ldi r24, 'N'
	rcall lcd_data
	ldi r24, 'O'
	rcall lcd_data
	ldi r24, ' '
	rcall lcd_data
	ldi r24, 'D'
	rcall lcd_data
	ldi r24, 'E'
	rcall lcd_data
	ldi r24, 'V'
	rcall lcd_data
	ldi r24, 'I'
	rcall lcd_data
	ldi r24, 'C'
	rcall lcd_data
	ldi r24, 'E'
	rcall lcd_data
ret

one_wire_reset:
sbi DDRA ,PA4      ; PA4 configured for output
cbi PORTA ,PA4     ; 480 �sec reset pulse
ldi r24 ,low(480)
ldi r25 ,high(480)
rcall wait_usec
cbi DDRA ,PA4      ; PA4 configured for input
cbi PORTA ,PA4
ldi r24 ,100
; wait 100 �sec for devices
ldi r25 ,0
; to transmit the presence pulse
rcall wait_usec
in r24 ,PINA       ; sample the line
push r24
ldi r24 ,low(380) ; wait for 380 �sec
ldi r25 ,high(380)
rcall wait_usec
pop r25
; return 0 if no device was
clr r24
; detected or 1 else
sbrs r25 ,PA4
ldi r24 ,0x01
ret


one_wire_receive_byte:
ldi r27 ,8
clr r26
loop_:
rcall one_wire_receive_bit
lsr r26
sbrc r24 ,0
ldi r24 ,0x80
or r26 ,r24
dec r27
brne loop_
mov r24 ,r26
ret

one_wire_transmit_byte:
mov r26 ,r24
ldi r27 ,8
_one_more_:
clr r24
sbrc r26 ,0
ldi r24 ,0x01
rcall one_wire_transmit_bit
lsr r26
dec r27
brne _one_more_
ret


one_wire_receive_bit:
sbi DDRA ,PA4
cbi PORTA ,PA4    ; generate time slot
ldi r24 ,0x02
ldi r25 ,0x00
rcall wait_usec
cbi DDRA ,PA4     ;  release the line
cbi PORTA ,PA4
ldi r24 ,10       ; wait 10 �s
ldi r25 ,0
rcall wait_usec
clr r24           ; sample the line
sbic PINA ,PA4
ldi r24 ,1
push r24
ldi r24 ,49       ; delay 49 �s to meet the standards
ldi r25 ,0        ; for a minimum of 60 �sec time slot
rcall wait_usec; and a minimum of 1 �sec recovery time
pop r24
ret


one_wire_transmit_bit:
push r24          ; save r24
sbi DDRA ,PA4
cbi PORTA ,PA4   ; generate time slot
ldi r24 ,0x02
ldi r25 ,0x00
rcall wait_usec

pop r24     ; output bit
sbrc r24 ,0
sbi PORTA ,PA4
sbrs r24 ,0
cbi PORTA ,PA4
ldi r24 ,58       ; wait 58 �secfor the
ldi r25 ,0        ; device to sample the line
rcall wait_usec
cbi DDRA ,PA4 ; recovery time
cbi PORTA ,PA4
ldi r24 ,0x01
ldi r25 ,0x00
rcall wait_usec
ret

/*
*	LCD Driver routines
*/

write_2_nibbles:
  push r24 ; st???e? ta 4 MSB
  in r25 ,PIND ;d?a�????ta? ta 4LSB ?a? ta ?a?ast?????�e
  andi r25 ,0x0f ; ??a ?a �?? ?a??s??�e t?? ?p??a p??????�e?? ?at?stas?
  andi r24 ,0xf0 ; ap?�??????ta? ta 4 MSB ?a?
  add r24 ,r25 ;  s??d?????ta? �e ta p???p?????ta 4 LSB
  out PORTD ,r24 ; ?a? d????ta? st?? ???d?
  sbi PORTD ,PD3  ; d?�?????e?ta? pa?�?? Enable st?? a???d??t? PD3
  cbi PORTD ,PD3 ; PD3=1 ?a? �et? PD3=0
  pop r24 ; st???e? ta 4 LSB. ??a?t?ta? t? byte.
  swap r24 ; e?a???ss??ta? ta 4 MSB �e ta 4 LSB
  andi r24 ,0xf0 ; p?? �e t?? se??? t??? ap?st?????ta?
  add r24 ,r25
  out PORTD ,r24
  sbi PORTD ,PD3 ; ???? pa?�?? Enable
  cbi PORTD ,PD3
  ret

lcd_command:
  cbi PORTD,PD2 ;ep????? t?? ?ata????t? e?t???? (PD2=1)
  rcall write_2_nibbles ;  ap?st??? t?? e?t???? ?a? a?a�??? 39�sec

  ldi r24,39 ; ??a t?? ????????s?  t?? e?t??es?? t?? ap? t?? e?e??t? t?? lcd
  ldi r25,0 ; S??.: ?p?????? d?? e?t????, ?? clear display ?a? return home
  rcall wait_usec ; p?? apa?t??? s?�a?t??? �e?a??te?? ??????? d??st?�a.
  ret

lcd_data:
  sbi PORTD ,PD2; ep????? t?? ?ata????t? ded?�???? (PD2=1)
  rcall write_2_nibbles ; ap?st??? t?? byte
  ldi r24 ,43 ; a?a�??? 43�sec �???? ?a ?????????e? ? ????
  ldi r25 ,0  ; t?? ded?�???? ap? t?? e?e??t? t?? lcd
  rcall wait_usec
  ret

lcd_init:
  ldi r24 ,40 ; ?ta? ? e?e??t?? t?? lcd t??f?d?te?ta? �e
  ldi r25 ,0  ; ?e?�a e?te?e? t?? d??? t?? a?????p???s?.
  rcall wait_msec ; ??a�??? 40 msec �???? a?t? ?a ?????????e?.
  ldi r24 ,0x30 ; e?t??? �et?�as?? se 8 bit mode
  out PORTD ,r24 ; epe?d? de? �p????�e ?a e?�aste �?�a???
  sbi PORTD ,PD3  ; ??a t? d?a�??f?s? e?s?d?? t?? e?e??t?
  cbi PORTD ,PD3  ; t?? ??????, ? e?t??? ap?st???eta? d?? f????
  ldi r24 ,39
  ldi r25 ,0  ; e?? ? e?e??t?? t?? ?????? �??s?eta? se 8-bit mode
  rcall wait_usec ; de? ?a s?��e? t?p?ta, a??? a? ? e?e??t?? ??e? d?a�??f?s?
                  ; e?s?d?? 4 bit ?a �eta�e? se d?a�??f?s? 8 bit
  ldi r24 ,0x30
  out PORTD ,r24
  sbi PORTD ,PD3
  cbi PORTD ,PD3
  ldi r24 ,39
  ldi r25 ,0
  rcall wait_usec
  ldi r24 ,0x20   ; a??a?? se 4-bit mode
  out PORTD ,r24
  sbi PORTD ,PD3
  cbi PORTD ,PD3
  ldi r24 ,39
  ldi r25 ,0
  rcall wait_usec

  ldi r24 ,0x28   ; ep????? ?a?a?t???? �e?????? 5x8 ?????d??
  rcall lcd_command   ; ?a? e�f???s? d?? ??a��?? st?? ?????

  ldi r24 ,0x0c
  rcall lcd_command ; e?e???p???s? t?? ??????, ap?????? t?? ???s??a
  ldi r24 ,0x01
  rcall lcd_command ; ?a?a??s�?? t?? ??????
  ldi r24 ,low(1530)
  ldi r25 ,high(1530)
  rcall wait_usec
  ldi r24 ,0x06
  rcall lcd_command
  ret

/* waiting routines*/

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

/*keypad routines*/

	keypad_to_hex:
	movw r26 ,r24 ;
	ldi r24 ,0x0e
	sbrc r26 ,0
	ret
	ldi r24 ,0x00
	sbrc r26 ,1
	ret
	ldi r24 ,0x0f
	sbrc r26 ,2
	ret
	ldi r24 ,0x0d
	sbrc r26 ,3
	ret
	ldi r24 ,0x07
	sbrc r26 ,4
	ret
	ldi r24 ,0x08
	sbrc r26 ,5
	ret
	ldi r24 ,0x09
	sbrc r26 ,6
	ret
	ldi r24 ,0x0c
	sbrc r26 ,7
	ret
	ldi r24 ,0x04
	sbrc r27 ,0
	ret
	ldi r24 ,0x05
	sbrc r27 ,1
	ret
	ldi r24 ,0x06
	sbrc r27 ,2
	ret
	ldi r24 ,0x0B
	sbrc r27 ,3
	ret
	ldi r24 ,0x01
	sbrc r27 ,4
	ret
	ldi r24 ,0x02
	sbrc r27 ,5
	ret
	ldi r24 ,0x03
	sbrc r27 ,6
	ret
	ldi r24 ,0x0A
	sbrc r27 ,7
	ret
	clr r24
	ret

	keypad_to_ascii:
	movw r26 ,r24 ;
	ldi r24 ,'E'
	sbrc r26 ,0
	ret
	ldi r24 ,'0'
	sbrc r26 ,1
	ret
	ldi r24 ,'F'
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

	scan_keypad:
		ldi r24 ,0x01
		rcall scan_row
		swap r24
		mov r27 ,r24
		ldi r24 ,0x02
		rcall scan_row
		add r27 ,r24
		ldi r24 ,0x03
		rcall scan_row
		swap r24
		mov r26 ,r24
		ldi r24 ,0x04
		rcall scan_row
		add r26 ,r24
		movw r24 ,r26
		ret

	scan_row:
		ldi r25 ,0x08
	back_: lsl r25
		dec r24
		brne back_
		out PORTC ,r25
		nop
		nop
		in r24 ,PINC
		andi r24 ,0x0f
		ret
