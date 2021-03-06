.include "m16def.inc"
.def temp=r16
.def int_cnt=r22 ;interrupt counter reg
.def cnt=r26      ;main counter reg
.org 0x0 ;code is declared on 0x0
rjmp reset

.org 0x4 ;interrupt code routine is defined at 0x04
rjmp ISR1 ;interrupt service routine

reset:
    ldi temp ,low(RAMEND)   ;initialize stack pointer
    out SPL ,temp
    ldi temp ,high(RAMEND)
    out SPH ,temp

    ldi r24 ,(1<<ISC11)|(1<<ISC10) ;INT1 is defined positive edge trigger
    out MCUCR,r24
    ldi r24,(1<<INT1) ;enable INT1
    out GICR,r24
    sei     ;enable all interrupts
    clr int_cnt ;r22 will count interrupts in main
main:
    ser temp ;  PORTA and PORTB for output
    out DDRB,temp ;B main counter output
    out DDRA,temp ;A interrupt counter output
    clr temp
    out DDRD,temp ; PORTD is input
    clr cnt
loop1:
    out PORTB,cnt
    ldi r24,low(200)
    ldi r25,high(200)
    rcall wait_msec  ;200 msec delay
    inc cnt
rjmp loop1

ISR1: ;should i disable all interrupts after entering one ? ( in the end re-enable them)
    cli         ;na rwthsoume an xreiazetai mazi me to spinthirismo
    push cnt   ;push register,SREG
    in temp,SREG
    push temp
loop2:
    ldi r24,(1<<INTF1)
    out GIFR,r24 ; 7th bit is now zero
    ldi r24,low(5)
    ldi r25,high(5)
    rcall wait_msec ;5msec delay
    ldi r24,GIFR
    sbrc r24,7
rjmp loop2

    sbis PIND,7 ; If PD7 = 1 , skip
    rjmp endintr1
    inc int_cnt
    out PORTA,int_cnt
endintr1:
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
