

.include "m16def.inc"
.def temp = r19
.def count = r16
.def binary = r17
.def ten = r18
.def temp2 = r20
reset:
  ldi temp ,low(RAMEND)   ;initialize stack pointer
  out SPL ,temp
  ldi temp ,high(RAMEND)
  out SPH ,temp
  ser temp
  out DDRD,temp ;iPORTD for the lcd screen
  clr temp
  out DDRA, temp ;PORTA as input
  
  
start:
  rcall lcd_init  ;initialize lcd
  in temp, PINA
  mov temp2, temp
  clr ten
  ldi count, 0x08 ;loop : send each bit to output lcd
loop1:
  cpi count, 0x00
  breq to_dec
  ldi binary, '0' ; binary = 30
  lsl temp2 ;
  brcc a0; if msb is 1 send '31' to lcd
  inc binary ; else send '30'
 a0:
  mov r24, binary
  rcall lcd_data
  dec count
  rjmp loop1

  
to_dec:  ; if input is either 00000000 or 11111111 print 0 to lcd
  ldi r24, '='
  rcall lcd_data

  cpi temp,0xff
  breq zero
  cpi temp, 0x00
  breq zero
  rjmp not_zero
zero:
  ldi r24,'0'
  rcall lcd_data
  rjmp end
not_zero:
  sbrs temp,7 ;check sign$
  rjmp positive
  ;neg temp
  com temp
  ldi r24,'-'
  rcall lcd_data
  rjmp print_dec
positive:
  ldi r24, '+'
  rcall lcd_data
print_dec: ; count number of hundreds , tens and units . Print them in lcd
  mov temp2, temp
  cpi temp,0x64
  brlo tens
  subi temp,0x64
  ldi r24,'1'
  rcall lcd_data
tens:
  cpi temp, 0x0A
  brlo one_digit
ten_loop:
  cpi temp,0x0A
  brlo units
  inc ten
  subi temp,0x0A
  rjmp ten_loop

units:
  ldi r24,'0'
  add r24, ten
  rcall lcd_data
  rjmp lab1
one_digit:
	cpi temp2, 0x64
	brlo lab1
	ldi r24, '0'
	rcall lcd_data
lab1:
  ldi binary,'0'
  add temp,binary
  mov r24,temp
  rcall lcd_data


end:
    rjmp start

write_2_nibbles:
  push r24 ; ������� �� 4 MSB
  in r25 ,PIND ;����������� �� 4LSB ��� �� �������������
  andi r25 ,0x0f ; ��� �� ��� ��������� ��� ����� ����������� ���������
  andi r24 ,0xf0 ; ������������� �� 4 MSB ���
  add r24 ,r25 ;  ������������ �� �� ������������ 4 LSB
  out PORTD ,r24 ; ��� �������� ���� �����
  sbi PORTD ,PD3  ; ������������� ������ Enable ���� ��������� PD3
  cbi PORTD ,PD3 ; PD3=1 ��� ���� PD3=0
  pop r24 ; ������� �� 4 LSB. ��������� �� byte.
  swap r24 ; ������������� �� 4 MSB �� �� 4 LSB
  andi r24 ,0xf0 ; ��� �� ��� ����� ���� �������������
  add r24 ,r25
  out PORTD ,r24
  sbi PORTD ,PD3 ; ���� ������ Enable
  cbi PORTD ,PD3
  ret

lcd_command:
  cbi PORTD,PD2 ;������� ��� ���������� ������� (PD2=1)
  rcall write_2_nibbles ;  �������� ��� ������� ��� ������� 39�sec

  ldi r24,39 ; ��� ��� ����������  ��� ��������� ��� ��� ��� ������� ��� lcd
  ldi r25,0 ; ���.: �������� ��� �������, �� clear display ��� return home
  rcall wait_usec ; ��� �������� ��������� ���������� ������� ��������.
  ret

lcd_data:
  sbi PORTD ,PD2; ������� ��� ���������� ��������� (PD2=1)
  rcall write_2_nibbles ; �������� ��� byte
  ldi r24 ,43 ; ������� 43�sec ����� �� ����������� � ����
  ldi r25 ,0  ; ��� ��������� ��� ��� ������� ��� lcd
  rcall wait_usec
  ret

lcd_init:
  ldi r24 ,40 ; ���� � �������� ��� lcd ������������� ��
  ldi r25 ,0  ; ����� ������� ��� ���� ��� ������������.
  rcall wait_msec ; ������� 40 msec ����� ���� �� �����������.
  ldi r24 ,0x30 ; ������ ��������� �� 8 bit mode
  out PORTD ,r24 ; ������ ��� �������� �� ������� �������
  sbi PORTD ,PD3  ; ��� �� ���������� ������� ��� �������
  cbi PORTD ,PD3  ; ��� ������, � ������ ������������ ��� �����
  ldi r24 ,39
  ldi r25 ,0  ; ��� � �������� ��� ������ ��������� �� 8-bit mode
  rcall wait_usec ; ��� �� ������ ������, ���� �� � �������� ���� ����������
                  ; ������� 4 bit �� ������� �� ���������� 8 bit
  ldi r24 ,0x30
  out PORTD ,r24
  sbi PORTD ,PD3
  cbi PORTD ,PD3
  ldi r24 ,39
  ldi r25 ,0
  rcall wait_usec
  ldi r24 ,0x20   ; ������ �� 4-bit mode
  out PORTD ,r24
  sbi PORTD ,PD3
  cbi PORTD ,PD3
  ldi r24 ,39
  ldi r25 ,0
  rcall wait_usec

  ldi r24 ,0x28   ; ������� ���������� �������� 5x8 ��������
  rcall lcd_command   ; ��� �������� ��� ������� ���� �����

  ldi r24 ,0x0c
  rcall lcd_command ; ������������ ��� ������, �������� ��� �������
  ldi r24 ,0x01
  rcall lcd_command ; ���������� ��� ������
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
