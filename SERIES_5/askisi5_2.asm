.include "m16def.inc"
.def temp=r16
.def cnt=r26      ;main counter reg
.def led=r17

.org 0x0 ;code is declared on 0x0
rjmp reset

.org 0x2 ;interrupt code routine is defined at 0x04
rjmp ISR0 ;interrupt service routine

reset:
    ldi temp ,low(RAMEND)   ;initialize stack pointer
    out SPL ,temp
    ldi temp ,high(RAMEND)
    out SPH ,temp

    ldi r24 ,(1<<ISC01)|(1<<ISC00) ;INT0 is defined positive edge trigger
    out MCUCR,r24
    ldi r24,(1<<INT0) ;enable INT0
    out GICR,r24
    sei     ;enable all interrupts
    clr r24
main:
    ser temp ;  PORTC for output
    out DDRC,temp ;C interrupt routine output
    out DDRB,temp ;B main counter output
    clr temp
    out DDRA,temp ;A interrupt routine input (dip switches)
    clr cnt       ;initialize main counter
loop1:
    out PORTB,cnt
    ldi r24,low(200)
    ldi r25,high(200)
    rcall wait_msec  ;200 msec delay
    inc cnt
rjmp loop1


ISR0:
    cli
    push cnt
    in temp,SREG
    push temp
loop2:
    ldi r24,(1<<INTF0)
    out GIFR,r24 ; 7th bit is now zero
    ldi r24,low(5)
    ldi r25,high(5)
    rcall wait_msec ;5msec delay
    ldi r24,GIFR
    sbrc r24,7
    rjmp loop2
    in temp, PORTA
    clr led
loop3:
    cpi temp,0
    breq exit_int
    lsr temp
    brcc loop3
    lsl led
    inc led
    rjmp loop3
exit_int:
    out PORTC,led
    pop temp ; pop register,SREG and return
    out SREG,temp
    pop cnt
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
