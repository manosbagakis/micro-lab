.DSEG
_tmp_: .byte 2
.CSEG


.include "m16def.inc"
.def min = r18
.def secs = r16
.def cnt = r17
.def temp = r19

reset:
  ldi temp ,low(RAMEND)   ;initialize stack pointer
  out SPL ,temp
  ldi temp ,high(RAMEND)
  out SPH ,temp

  clr temp
  out DDRB, temp ;PORTB as input
  ser temp
  out DDRD, temp
  rcall lcd_init  ;initialize lcd

reset_timer:
  clr min
  clr secs
  rcall print_time


 checkb:
  rcall sec_delay
  in temp, PINB
  cpi temp, 0x80
  brsh reset_timer

  ror temp
  brcc checkb
  //rcall sec_delay
  cpi secs,60 ; de tha eprepe na einai an einai 59?
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
  rcall lcd_init
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
  ldi r24, '0'
  add r24 , cnt
  rcall lcd_data

print_min2:
  ldi r24, '0'
  add r24 , min
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
  ldi r24, '0'
  add r24 , cnt
  rcall lcd_data

print_sec2:
  ldi r24, '0'
  add r24 , secs
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

  ldi r24 ,0x0c ; cursor blinking,0x0e for not blinking
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

