.include "m16def.inc"
.def temp=r16
.def outled = r21



.org 0x00
rjmp reset
.org 0x04
rjmp ISR1
.org 0x10
rjmp ISR_TIMER1_OVF


reset:
    ldi temp ,low(RAMEND)   ;initialize stack pointer
    out SPL ,temp
    ldi temp ,high(RAMEND)
    out SPH ,temp

    ser temp
    out DDRB, temp ;PORTB for output
    clr temp
    out DDRA,temp ;PORTA for input
		
	ldi temp,(1<<TOIE1)
    out TIMSK,temp
    ldi temp,(1<<CS12)|(0<<CS11)|(1<<CS10) ;clk/256 de ginetai gt den mporw na metrhsw 4 sec afou > 2^16 -1 ara clk/1024
    out TCCR1B,temp

    ldi temp ,(1<<ISC11)|(1<<ISC10) ;INT1 is defined positive edge trigger
    out MCUCR,temp
    ldi temp,(1<<INT1) ;enable INT1
    out GICR,temp
    sei
    clr outled

loop1:
    sbic PINA,7   ;check if PA7 is high
    rjmp ISRA1
    rjmp loop1

ISR1:
	sei
	ldi r24,(1<<INTF1)
    out GIFR,r24 ; 7th bit is now zero
    ldi r24,low(5)
    ldi r25,high(5)
    rcall wait_msec ;5msec delay
    ldi r24,GIFR
    sbrc r24,7
	rjmp ISR1

	cpi outled,0x00
	breq first_time
	rjmp enable_all

ISRA1:
	
	sei
	loop_for_a_0:
	in temp,PINA
	andi temp,0x80
	push temp
	ldi r24,low(5)
    ldi r25,high(5)
    rcall wait_msec ;5msec delay
	pop temp
	sbrc temp,7
	rjmp loop_for_a_0
	cpi outled,0x00
	breq first_time
    
    
enable_all:
	ser outled
	out PORTB, outled

	ldi temp, 0xf0
    out TCNT1H, temp
    ldi temp, 0xbe
    out TCNT1L, temp
	
wait_for_time1:
	cpi outled,0x01
	breq one_open
	sbic PINA,7   ;check if PA7 is high
    rjmp ISRA1 
	rjmp wait_for_time1
	

one_open:
    ;ldi outled,0x01
    ;out PORTB, outled

    ldi temp, 0x95
    out TCNT1H, temp
    ldi temp, 0x30
    out TCNT1L, temp


wait_for_time2:
    ;sbrc outled,0			;escape if flag==0
	cpi outled,0x00
	breq loop1
	sbic PINA,7   ;check if PA7 is high
    rjmp ISRA1
    rjmp wait_for_time2

rjmp loop1

first_time:
    ldi outled,0x01
    out PORTB, outled

    ldi temp, 0x85
    out TCNT1H, temp
    ldi temp, 0xee
    out TCNT1L, temp


wait_for_time3:
    ;sbrc outled,0			;escape if flag==0
	cpi outled,0x00
	breq loop1
	sbic PINA,7   ;check if PA7 is high
    rjmp ISRA1
    rjmp wait_for_time3

rjmp loop1

ISR_TIMER1_OVF:
	
    in temp,SREG
    push temp
    sbrs outled,4
    rjmp turn_off_all
    ldi outled,0x01
    out PORTB, outled
    rjmp end_timer_int
turn_off_all:
    clr outled   ;enable PB0
    out PORTB, outled
end_timer_int:
    pop temp
    out SREG,temp
	sei
    reti

wait_usec:
sbiw r24,1
nop
nop
nop
nop
brne wait_usec
ret

wait_msec: ;
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
