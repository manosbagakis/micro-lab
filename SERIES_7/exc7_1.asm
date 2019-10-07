.include "m16def.inc"
.def temp = r15
.def first_digit = r16
.def second_digit = r17
.def third_digit = r18
.org 0x0
  rjmp reset
.org 0x10
    rjmp ISR_TIMER1_OVF




reset:
  ldi temp ,low(RAMEND)   ;initialize stack pointer
  out SPL ,temp
  ldi temp ,high(RAMEND)
  out SPH ,temp

  clr temp
  out DDRB, temp ;PORTB as input
  ser temp
  out DDRA, temp  ;PORTA as alarm output
  out DDRD, temp  ;PORTD as alarm output
  rcall lcd_init  ;initialize lcd

  ldi temp,(1<<TOIE1) ;Setup timer
  out TIMSK,temp
  ldi temp,(1<<CS12)|(0<<CS11)|(1<<CS10) ;clk/256
  out TCCR1B,temp

wait_for_trigger: ; wait untill any B push button is pressed
  in temp, PINB
  cpi temp, 0x00
  breq wait_for_trigger

  ldi r24,0x67
  out TCNT1H, r24
  ldi r24,0x69
  out TCNT1L, r24

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

  ldi r24,0x01 ; clear lcd display
  rcall lcd_command
  ldi r24, 0x02
  rcall lcd_command;return home
  ldi r24, 0x0c
  rcall lcd_command; cursor disabled

rcall print_correct
;PRINT ALARM OFF
  clr temp
  out TIMSK, temp  ; disable timer


alarm_on:
  rcall ISR_TIMER1_OVF

ISR_TIMER1_OVF:
ldi r24,0x01
rcall lcd_command
ldi r24,0x02
rcall lcd_command
rcall print_wrong
loop_1:
  ser temp
  out PORTA, temp
  ldi r24,low(400)
  ldi r25,high(400)
  clr temp
  out PORTA, temp
  ldi r24,low(100)
  ldi r25,high(100)
  rjmp loop_1
reti

;Given routines for lcd, keyboard and wait
write_2_nibbles:
  push r24 ; στέλνει τα 4 MSB
  in r25 ,PIND ;διαβάζονται τα 4LSB και τα ξαναστέλνουμε
  andi r25 ,0x0f ; για να μην χαλάσουμε την όποια προηγούμενη κατάσταση
  andi r24 ,0xf0 ; απομονώνονται τα 4 MSB και
  add r24 ,r25 ;  συνδυάζονται με τα προϋπάρχοντα 4 LSB
  out PORTD ,r24 ; και δίνονται στην έξοδο
  sbi PORTD ,PD3  ; δημιουργείται παλμός Enable στον ακροδέκτη PD3
  cbi PORTD ,PD3 ; PD3=1 και μετά PD3=0
  pop r24 ; στέλνει τα 4 LSB. Ανακτάται το byte.
  swap r24 ; εναλλάσσονται τα 4 MSB με τα 4 LSB
  andi r24 ,0xf0 ; που με την σειρά τους αποστέλλονται
  add r24 ,r25
  out PORTD ,r24
  sbi PORTD ,PD3 ; Νέος παλμός Enable
  cbi PORTD ,PD3
  ret

lcd_command:
  cbi PORTD,PD2 ;επιλογή του καταχωρητή εντολών (PD2=1)
  rcall write_2_nibbles ;  αποστολή της εντολής και αναμονή 39μsec

  ldi r24,39 ; για την ολοκλήρωση  της εκτέλεσης της από τον ελεγκτή της lcd
  ldi r25,0 ; ΣΗΜ.: υπάρχουν δύο εντολές, οι clear display και return home
  rcall wait_usec ; που απαιτούν σημαντικά μεγαλύτερο χρονικό διάστημα.
  ret

lcd_data:
  sbi PORTD ,PD2; επιλογή του καταχωρήτη δεδομένων (PD2=1)
  rcall write_2_nibbles ; αποστολή του byte
  ldi r24 ,43 ; αναμονή 43μsec μέχρι να ολοκληρωθεί η λήψη
  ldi r25 ,0  ; των δεδομένων από τον ελεγκτή της lcd
  rcall wait_usec
  ret

lcd_init:
  ldi r24 ,40 ; Όταν ο ελεγκτής της lcd τροφοδοτείται με
  ldi r25 ,0  ; ρεύμα εκτελεί την δική του αρχικοποίηση.
  rcall wait_msec ; Αναμονή 40 msec μέχρι αυτή να ολοκληρωθεί.
  ldi r24 ,0x30 ; εντολή μετάβασης σε 8 bit mode
  out PORTD ,r24 ; επειδή δεν μπορούμε να είμαστε βέβαιοι
  sbi PORTD ,PD3  ; για τη διαμόρφωση εισόδου του ελεγκτή
  cbi PORTD ,PD3  ; της οθόνης, η εντολή αποστέλλεται δύο φορές
  ldi r24 ,39
  ldi r25 ,0  ; εάν ο ελεγκτής της οθόνης βρίσκεται σε 8-bit mode
  rcall wait_usec ; δεν θα συμβεί τίποτα, αλλά αν ο ελεγκτής έχει διαμόρφωση
                  ; εισόδου 4 bit θα μεταβεί σε διαμόρφωση 8 bit
  ldi r24 ,0x30
  out PORTD ,r24
  sbi PORTD ,PD3
  cbi PORTD ,PD3
  ldi r24 ,39
  ldi r25 ,0
  rcall wait_usec
  ldi r24 ,0x20   ; αλλαγή σε 4-bit mode
  out PORTD ,r24
  sbi PORTD ,PD3
  cbi PORTD ,PD3
  ldi r24 ,39
  ldi r25 ,0
  rcall wait_usec

  ldi r24 ,0x28   ; επιλογή χαρακτήρων μεγέθους 5x8 κουκίδων
  rcall lcd_command   ; και εμφάνιση δύο γραμμών στην οθόνη

  ldi r24 ,0x0f ; cursor blinking,0x0e for not blinking
  rcall lcd_command ; ενεργοποίηση της οθόνης, απόκρυψη του κέρσορα
  ldi r24 ,0x01
  rcall lcd_command ; καθαρισμός της οθόνης
  ldi r24 ,low(1530)
  ldi r25 ,high(1530)
  rcall wait_usec
  ldi r24 ,0x06
  rcall lcd_command
  ret

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
