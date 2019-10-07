; multi-segment executable file template.

data segment                                     
    ; add your data here!
    newline db 0AH,0DH,'$'
    msg     db 'please enter input','$'
ends

stack segment
    dw   128  dup(0)
ends

PRINT MACRO   ; prints data sotred in AL
    MOV DL,AL
    MOV AH,2
    INT 21H
    ENDM   

PRINT_STR MACRO STRING
    MOV DX,OFFSET STRING
    MOV AH,9
    INT 21H
    ENDM

READ MACRO 
  INIT_READ:  MOV AH, 8    ; read without prinitng
    INT 21H 

    CMP AL,'='   ; IF '=' stop
    JE  EXIT_READ
    
    CMP AL,0DH
    JE  EXIT_READ  ; IF 'enter' print
    
    CMP AL,'z'    
    JG  INIT_READ
    
    CMP AL,'a'
    JGE  EXIT_READ  ; if number/uppercase/lowercase store it
    
    CMP AL,'Z'
    JG  INIT_READ
    
    CMP AL,'A'
    JGE  EXIT_READ
    
    CMP AL,'9'
    JG  INIT_READ
    
    CMP AL,'0'
    JGE  EXIT_READ
    
    CMP AL,20H    ;20H == space char
    JNE INIT_READ
    
    INC BL        ; if 'space' counter as valid character but dont store it
    
    PRINT ; prints " "
    
EXIT_READ:   
    
   ENDM 

STORE_CHAR MACRO       ; store character in memory
    PRINT ; Print char before storing it (no spaces included)
    
    
    INC BL       ;1st,2nd,3rd number in 1000,1002,1004.. memory position
    MOV AH,00H
    MOV [SI],AX    
    INC SI       ; memory increase 
    INC SI
    ENDM

code segment
start:
; set segment registers:
    mov ax, data
    mov ds, ax
    mov es, ax

    ; add your code here   ; bl is valid char counter
MAIN:
    PRINT_STR msg
    PRINT_STR newline
    MOV SI,1000H ; starting storing address
    MOV BL,00H   ; ; BL -> valid char counter    
LOOP1: 
    CMP BL,14D   ; if already 14 valid characters -> start printing
    JE TO_PRINT
    
    READ
    CMP AL,'='   ; IF '=' stop
    JE  TERMINATE
    
    CMP AL,0DH
    JE  TO_PRINT  ; IF 'enter' print
    
    CMP AL,20H    
    JE LOOP1
    
    STORE_CHAR  ; store character in memory
    
    
    JMP LOOP1
    
     
    
    
    

    
TO_PRINT:
  MOV CX,2020H ; both cl ,ch has space ( ch max number , cl 2nd  highest )
  
  PRINT_STR newline 
       
  MOV SI,0FFEH  ; for loop purposes  
  INC BL        ; for loop purposes
  MOV BH,BL ; save counter value


PRINT_NUM:  ; every time i scan memory prinitng numbers
  INC SI    ; memory step  (first time starts normaly at 1000)
  INC SI
  DEC BL    ; counter step (first time at 14)
  CMP BL,00H
  JE PRINT_UPPER ; if counter goes 0 , proceed printing uppercase letters
  CMP [SI], 30H  ; if character is number print him , else scan next memory position
  JL PRINT_NUM
  CMP [SI], 39H
  JG PRINT_NUM
  
  
  MOV AX,[SI]   ; Prints character stored in [SI] memory
  PRINT    
  
  ;STORE 2 MAX  [remember ch highest , cl second higest]  :IMPORTANT: both swap,swap_both return to scanning the next memory position
  CMP DL,CL     ; if number < cl , go to next one
  JL  PRINT_NUM
  CMP DL,CH     ; if  cl <= number <= ch  : swap number with cl
  JL  SWAP
  JMP SWAP_BOTH ; if number > ch : ch goes to cl , number goes to ch 

  
  
  
                  
PRINT_UPPER:  ; scan memory , print only uppercase letters
  MOV AL,20H  ; prints " " seperating numbers from UPPERCASE
  PRINT
  MOV SI,0FFEH
  MOV BL,BH
UPPER_LOOP:   ; like in print_number , print any upper case found in memory
  INC SI
  INC SI 
  DEC BL
  CMP BL,00H
  JE PRINT_LOWER ; once finished with upper , proceed with lowercase characters
  CMP [SI],5AH
  JG UPPER_LOOP
  CMP [SI],41H
  JL UPPER_LOOP
  
  MOV AX,[SI]
  PRINT
  
  JMP UPPER_LOOP


PRINT_LOWER:     ; scan memory , print any lowercase  characters
   MOV AL,20H    ; prints " " seperating UPPERCASE from lowercase
   PRINT
   MOV SI,0FFEH
   MOV BL,BH
LOWER_LOOP:
   INC SI
   INC SI
   DEC BL
   CMP BL,00H
   JE  FIND_MAX_ORIGIN     ; once finished with lower , proceed printing 2 biggest numbers read
   CMP [SI],61H
   JL LOWER_LOOP
   MOV AX,[SI]
   PRINT
   JMP LOWER_LOOP

     
SWAP:
    MOV CL,DL
    JMP PRINT_NUM    
SWAP_BOTH:
    MOV CL,CH
    MOV CH,[SI]
    
    JMP PRINT_NUM    
                  
                     
  
                      
  
  
  
    
    
            
 


    
FIND_MAX_ORIGIN: ; i have ch-> highest cl-> 2nd highest
    MOV SI,0FFEH ; whichever i met first at memory put it in ch , second one in cl
    MOV BL,BH
LOOP3: 
    CMP BL,00H
    JE PRINT_MAX   
    INC SI
    INC SI 
    DEC BL
    CMP [SI],CH
    JE PRINT_MAX
    CMP [SI],CL
    JNE LOOP3
    XCHG CL,CH
PRINT_MAX:
    PRINT_STR newline
    MOV AL,CH
    PRINT
    MOV AL,CL
    PRINT    
ENDING:


PRINT_STR newline     ; continuous programm
MOV SI,1000H

CLEAR_LOOP:
MOV [SI],0
INC SI 
INC SI
DEC BH
CMP BH,00H
JE MAIN
JMP CLEAR_LOOP
    
TERMINATE:
MOV AX, 4C00H ; EXIT TO OPERATING SYSTEM.
INT 21H 
ends




end start ; 
      