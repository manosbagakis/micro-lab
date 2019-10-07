.include "m16def.inc"
.def min = r15
.def secs = r16
.def cnt = r17

reset:
  ldi temp ,low(RAMEND)   ;initialize stack pointer
  out SPL ,temp
  ldi temp ,high(RAMEND)
  out SPH ,temp

  clr temp
  out DDRB, temp ;PORTB as input
  rcall lcd_init  ;initialize lcd

reset_timer:
  clr min
  clr secs
  rcall print_time

checkb:
  in temp, PORTB
  cpi temp, 0x80
  brge reset_timer

  rcall sec_delay

  lsr temp
  brcc checkb
  cpi secs,60
  breq inc_min
  inc secs
  rjmp print_1

inc_min:
  clr secs
  inc min
  cpi min,60
  brne print_1
  clr min
print_1:

  rcall print_time
  rjmp checkb



print_time: ;arguments min,secs
  push min
  push secs
  clr cnt
loop_mins:
  cpi min,0x0A
  brlo print_min1
  subi min,0x0A
  inc cnt
  rjmp loop_mins


print_min1:
  subi cnt,-30
  rcall lcd_data

print_min2:
  subi min, -30
  rcall lcd_data

ldi r24, ' '
rcall lcd_data
ldi r24, 'M'
rcall lcd_data
ldi r24, 'I'
rcall lcd_data
ldi r24, 'N'
rcall lcd_data
ldi r24, ':'
rcall lcd_data

clr cnt

loop_secs:
  cpi secs,0x0A
  brlo print_sec1
  subi secs,0x0A
  inc cnt
  rjmp loop_secs


print_sec1:
  subi cnt,-30
  rcall lcd_data

print_sec2:
  subi sec, -30
  rcall lcd_data

  ldi r24, ' '
  rcall lcd_data
  ldi r24, 'S'
  rcall lcd_data
  ldi r24, 'E'
  rcall lcd_data
  ldi r24, 'C'
  rcall lcd_data

  pop secs
  pop min

ret



sec_delay:
  ldi r24, low(1000)
  ldi r25, high(1000)
  rcall wait_msec
  ret

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

  ldi r24 ,0x0c ; cursor blinking,0x0e for not blinking
  rcall lcd_command ; ενεργοποίηση της οθόνης, απόκρυψη του κέρσορα
  ldi r24 ,0x01
  rcall lcd_command ; καθαρισμός της οθόνης
  ldi r24 ,low(1530)
  ldi r25 ,high(1530)
  rcall wait_usec
  ldi r24 ,0x06
  rcall lcd_command
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
