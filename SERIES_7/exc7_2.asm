.include "m16def.inc"
.def temp = r15
.def count = r16
.def binary = r17
.def ten = r18
reset:
  ldi temp ,low(RAMEND)   ;initialize stack pointer
  out SPL ,temp
  ldi temp ,high(RAMEND)
  out SPH ,temp

  clr temp
  out DDRA, temp ;PORTA as input
  rcall lcd_init  ;initialize lcd
start:

  in temp, PINA
  clr ten
  ldi count, 0x08 ;loop : send each bit to output lcd
loop1:
  cpi count, 0x00
  breq to_dec
  ldi binary, 0x1e ; binary = 30
  rol temp ;
  sbrc temp,0 ; if msb is 1 send '31' to lcd
  inc binary ; else send '30'
  mov r24, binary
  rcall lcd_data
  rjmp loop1

  ldi r24, '='
  rcall lcd_data
to_dec:  ; if input is either 00000000 or 11111111 print 0 to lcd
  cpi temp,0xff
  brne not_zero
  cpi temp, 0x00
  brne not_zero
zero:
  ldi r24,'0'
  rcall lcd_data
  rjmp end
not_zero:
  sbrs temp,7 ;check sign$
  rjmp positive
  neg temp
  ldi r24,'-'
  rcall lcd_data
  rjmp print_dec
positive:
  ldi r24, '+'
  rcall lcd_data
print_dec: ; count number of hundreds , tens and units . Print them in lcd
  cpi temp,0x64
  brlo tens
  subi temp,0x64
  ldi r24,'1'
  rcall lcd_data
tens:
  cpi temp,0x0A
  brlo units
  inc ten
  subi temp,0x0A
  rjmp tens
units:
  cpi ten, 0x00
  breq one_digit
  subi ten,-30
  mov r24,ten
  rcall lcd_data
one_digit:
  subi temp,-30 ;hacker intensifies
  mov r24,temp
  rcall lcd_data

end:
    ldi r24, 0x01
    rcall lcd_command ;clear screen
    ldi r24, 0x02
    rcall lcd_command ;cursor return home
    rjmp start

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

  ldi r24 ,0x0c
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
