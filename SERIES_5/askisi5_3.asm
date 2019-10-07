.include "m16def.inc"
.def temp=r16
.def flag=r22
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

    ldi temp ,(1<<ISC11)|(1<<ISC10) ;INT1 is defined positive edge trigger
    out MCUCR,temp
    ldi temp,(1<<INT1) ;enable INT1
    out GICR,temp
    sei
    clr flag
loop1:
    sbic PINA,7   ;check if PA7 is high
    rcall ISR1
    rjmp loop1

ISR1:
    in temp,SREG
    push temp
refresh:
    ldi temp,(1<<TOIE1)
    out TIMSK,temp
    ldi temp,(1<<CS12)|(0<<CS11)|(1<<CS10) ;clk/256 de ginetai gt den mporw na metrhsw 4 sec afou > 2^16 -1 ara clk/1024
    out TCCR1B,temp

    ser temp
    out PORTB, temp

    ldi temp, 0xf0
    out TCNT1H, temp
    ldi temp, 0xbe
    out TCNT1L, temp
loop2:
    sbic PINA,7   ;check if PA7 is high
    rjmp refresh
    sbrs flag,0
    rjmp loop2

    ldi temp, 0x95
    out TCNT1H, temp
    ldi temp, 0x30
    out TCNT1L, temp
loop3:
    sbic PINA,7   ;check if PA7 is high
    rjmp refresh
    sbrc flag,0
    rjmp loop3
    
    pop temp
    out SREG,temp
    reti

ISR_TIMER1_OVF:
    in temp,SREG
    push temp
    sbrs flag,0
    rjmp leave_pa0_open
    clr temp
    out PORTB, temp
    clr flag
    rjmp end_timer
leave_pa0_open:
    ldi temp,0x01   ;enable PB0
    out PORTB, temp
    ser flag
end_timer_int:
    pop temp
    out SREG,temp
    reti
