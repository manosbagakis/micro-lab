
.DSEG
_tmp_: .byte 2
.CSEG

.include "m16def.inc"

.def temp = r19
.def first_digit = r16
.def second_digit = r17
.def third_digit = r18
.org 0x0
  rjmp reset
.org 0x10
    rjmp ISR_TIMER1_OVF


reset:
  clr temp
  out TIMSK, temp
  ldi temp ,low(RAMEND)   ;initialize stack pointer
  out SPL ,temp
  ldi temp ,high(RAMEND)
  out SPH ,temp

  ldi r24 ,(1 << PC7) | (1 <<PC6) | (1 <<PC5) | (1 <<PC4)
  out DDRC ,r24 ;initialize keyboard


  clr temp
  out DDRB, temp ;PORTB as input
  ser temp
  out DDRA, temp  ;PORTA as alarm output
  out DDRD, temp  ;PORTD as alarm output
  rcall lcd_init  ;initialize lcd



wait_for_trigger: ; wait until any B push button is pressed
  in temp, PINB
  cpi temp, 0x00
  breq wait_for_trigger
  ldi temp,(1<<TOIE1) ;Setup timer
  out TIMSK,temp
  ldi temp,(1<<CS12)|(0<<CS11)|(1<<CS10) ;clk/1024
  out TCCR1B,temp
sei

  ldi temp,0x67; overflow after 5 sec
  out TCNT1H, temp
  ldi temp,0x69
  out TCNT1L, temp



loop_1st:
  ldi r24,0x05 ; 5ms delay between checking keyboard state
  rcall scan_keypad_rising_edge
  mov temp,r24
  or temp,r25
  cpi temp,0x00 ; if not button was pressed , read again
  breq loop_1st

  rcall keypad_to_ascii
  mov first_digit, r24

  rcall lcd_data


loop_2nd:
  ldi r24,0x05 ; 5ms delay between checking keyboard state
  rcall scan_keypad_rising_edge
  mov temp,r24
  or temp,r25
  cpi temp,0x00 ; if not button was pressed , read again
  breq loop_2nd

  rcall keypad_to_ascii
  mov second_digit, r24
  rcall lcd_data
loop_3rd:
  ldi r24,0x05 ; 5ms delay between checking keyboard state
  rcall scan_keypad_rising_edge
  mov temp,r24
  or temp,r25
  cpi temp,0x00 ; if not button was pressed , read again
  breq loop_3rd

  rcall keypad_to_ascii
  mov third_digit, r24
  rcall lcd_data



;Password checking
  cpi first_digit,'3' ; if input isn't '312' alarm is on
  brne alarm_on
  cpi second_digit,'1'
  brne alarm_on
  cpi third_digit,'2'
  brne alarm_on
  clr temp
  out TIMSK,temp
  rcall lcd_init
  ldi r24, 0x0c
  rcall lcd_command; cursor disabled


rcall print_correct;print ALARM OFF

loo:
rjmp loo





alarm_on:
  rcall ISR_TIMER1_OVF



ISR_TIMER1_OVF:
rcall lcd_init
ldi r24,0x0c ;cursor disabled
rcall lcd_command
rcall print_wrong ;print ALARM ON
loop_1:
  ser temp
  out PORTA, temp ;turn on the LEDs for 0.4 sec
  ldi r24,low(400)
  ldi r25,high(400)
  rcall wait_msec
  clr temp
  out PORTA, temp ;turn off the LEDs for 0.1 sec
  ldi r24,low(100)
  ldi r25,high(100)
  rcall wait_msec
  rjmp loop_1
reti

keypad_to_ascii:
movw r26 ,r24 ;
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


wait_msec:
	push r24
	push r25
	ldi r24 , low(998)
	ldi r25 , high(998)
	rcall wait_usec
	pop r25
	pop r24
	sbiw r24 , 1
	brne wait_msec
	ret


wait_usec:
	sbiw r24 ,1
	nop
	nop
	nop
	nop
	brne wait_usec
	ret

write_2_nibbles:
push r24
in r25 ,PIND
andi r25 ,0x0F
andi r24 ,0xF0
add r24 ,r25
out PORTD, r24
sbi PORTD,PD3
cbi PORTD,PD3
pop r24
swap r24
andi r24 ,0xF0
add r24 ,r25
out PORTD ,r24
sbi PORTD ,PD3
cbi PORTD ,PD3
ret


lcd_data:
sbi PORTD,PD2
rcall write_2_nibbles
ldi r24 ,43
ldi r25 ,0
rcall wait_usec ret

lcd_command:
cbi PORTD,PD2
rcall write_2_nibbles
ldi r24 ,39
ldi r25 ,0
rcall wait_usec ret




lcd_init:
ldi r24 ,40
ldi r25 ,0
rcall wait_msec
ldi r24 ,0x30
out PORTD ,r24
sbi PORTD,PD3
cbi PORTD,PD3
ldi r24 ,39
ldi r25 ,0
rcall wait_usec
ldi r24 ,0x30
out PORTD ,r24
sbi PORTD ,PD3
cbi PORTD ,PD3
ldi r24 ,39
ldi r25 ,0
rcall wait_usec
ldi r24 ,0x20
out PORTD ,r24
sbi PORTD ,PD3
cbi PORTD ,PD3
ldi r24 ,39
ldi r25 ,0
rcall wait_usec
ldi r24 ,0x28
rcall lcd_command
ldi r24 ,0x0e
rcall lcd_command
ldi r24 ,0x01
rcall lcd_command
ldi r24 ,low(1530)
ldi r25 ,high(1530)
rcall wait_usec
ldi r24 ,0x06
rcall lcd_command
ret



print_wrong:
  ldi r24,'A'
  rcall lcd_data
  ldi r24,'L'
  rcall lcd_data
  ldi r24,'A'
  rcall lcd_data
  ldi r24,'R'
  rcall lcd_data
  ldi r24,'M'
  rcall lcd_data
  ldi r24,' '
  rcall lcd_data
  ldi r24,'O'
  rcall lcd_data
  ldi r24,'N'
  rcall lcd_data
  ret

print_correct:
  ldi r24,'A'
  rcall lcd_data
  ldi r24,'L'
  rcall lcd_data
  ldi r24,'A'
  rcall lcd_data
  ldi r24,'R'
  rcall lcd_data
  ldi r24,'M'
  rcall lcd_data
  ldi r24,' '
  rcall lcd_data
  ldi r24,'O'
  rcall lcd_data
  ldi r24,'F'
  rcall lcd_data
  ldi r24,'F'
  rcall lcd_data
  ret
