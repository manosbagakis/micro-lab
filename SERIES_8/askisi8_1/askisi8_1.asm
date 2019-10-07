.DSEG
_tmp_: .byte 2
.CSEG

.include "m16def.inc"
.def temp = r17

start:
	ldi temp ,low(RAMEND)   ;initialize stack pointer
	out SPL ,temp
  ldi temp ,high(RAMEND)
  out SPH ,temp

  ser temp

  out DDRA,temp	;PortA output
	out DDRB,temp ;PortB output
	out PORTA,temp	;pull-up resistors


endless_loop: ; program will be continuous
	rcall get_temp
	rjmp endless_loop


get_temp: 		; routine to get temperature and calculate the result to be printed
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
	mov temp,r24 								; temp has 8 LSB

	rcall one_wire_receive_byte ; receive 8 MSB

	mov r25, r24 ; r25 has 8 MSB
	mov r24, temp ; r24 has 8 LSB

calculate_result:
	sbrc r25,0 	;input complement of 1 instead of 2
	dec temp    ; in case of negative numbers , we substitute one
	rjmp print

not_connected: ; if no device is connected load 0x8000 in r25:r24
		ldi r25,0x80
		ldi r24,0x00
    clr temp	; when disconnected temp=0 and zero on output
print: ; temperature is being printed on PORTB
	out PORTB,temp
	ret

/*
*	GIVEN ROUTINES
*/
one_wire_reset:
sbi DDRA ,PA4      ; PA4 configured for output
cbi PORTA ,PA4     ; 480 sec reset pulse
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
