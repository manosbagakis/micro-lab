DATA SEGMENT
    MSG1 DB "GIVE 2 DECIMAL DIGITS: $"
    MSG2 DB "OCTAL= $"
    NEWLINE DB 0AH,0DH,'$'
ENDS

STACK SEGMENT
    DW   128  DUP(0)
ENDS   

READ MACRO
 MOV AH,0X08
 INT 0X21
ENDM

      
PRINT_STR MACRO STRING
  PUSH AX
  PUSH DX
  LEA DX,STRING  
  MOV AH,0X09
  INT 0X21
  POP DX
  POP AX        
ENDM      

PRINT MACRO CHAR
 PUSH AX
  PUSH DX
  MOV DL,CHAR
  MOV AH,0X02
  INT 0X21
  POP DX
  POP AX
 ENDM

 
CODE SEGMENT 
    ASSUME CS:CODE,SS:STACK,DS:DATA
START:
; SET SEGMENT REGISTERS:
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX

;GET INPUT
INIT:   
    PRINT_STR MSG1  ;PROMPT 1
    CALL IN_DEC     ;GET FIRST DECIMAL OR 'Q'
    CMP AL,'Q'      ;QUIT IF 'Q'
    JE QUIT
    MOV BH,AL       ;FIRST DIGIT IN BH
    CALL IN_DEC     ;GET SECOND DECIMAL OR 'Q'
READ_UNIT:   
    CMP AL,'Q'
    JE QUIT
    MOV BL,AL
    CALL IN_DEC_OR_NEWL     ;GET NEWLINE OR Q OR DECIMAL
    CMP AL,0DH      
    JE END_INPUT    ;IF NEWLINE THEN CALCULATE OCTAL
    MOV BH,BL       ;ELSE SAVE LAST NUM AS DECADE DIGIT AND WAIT FOR UNITS
    JMP READ_UNIT 
     
END_INPUT:;BX HAS THE TWO INPUT DECIMAL DIGITS 
PRINT BH
PRINT BL
SUB BH,'0'
SUB BL,'0'  
PRINT_STR NEWLINE   ;PROMPT 2
PRINT_STR MSG2

MOV AL,0AH  ;INPUT = DECADES*10+UNITS = BH*10+BL
MUL BH
ADD BL,AL   ;BL HAS THE FINAL NUMBER IN BINARY FORM

CALL DEC_TO_OCT ;CONVERT AND PRINT TO OCT SYSTEM 

PRINT_STR NEWLINE
JMP INIT          ;ENDLESS LOOP


QUIT:  
    MOV AX, 4C00H ; EXIT TO OPERATING SYSTEM.
    INT 21H    
ENDS
                  
;returns decimal number or Q char to AL register ignoring any other char
IN_DEC PROC 
DIGNORE0:
            READ
            CMP AL ,'Q'
            JE DQUIT
            CMP AL,'0'
            JL DIGNORE0
            CMP AL,'9'
            JG DIGNORE0
            ;PRINT AL     
            ;SUB AL,'0'
            DQUIT:
            RET
IN_DEC ENDP       

;returns decimal number or Q or newline char to AL register
IN_DEC_OR_NEWL PROC 
DIGNORE1:
            READ
            CMP AL ,'Q'
            JE DQUIT1    
            CMP AL,0DH
            JE DQUIT1
            CMP AL,'0'
            JL DIGNORE1
            CMP AL,'9'
            JG DIGNORE1
            ;PRINT AL     
            ;SUB AL,'0'
            DQUIT1:
            RET
IN_DEC_OR_NEWL ENDP    
          
;Converts decimal to octal and prints the result           
DEC_TO_OCT PROC 
    PUSH AX
    PUSH BX
    MOV AL,BL
    AND AL,0C0H ;MSB of octal number (2 msb's of input)
    MOV CL,2  
    ROL AL,CL
    ADD AL,30H
    PRINT AL      

    MOV AL,BL
    AND AL,038H  ;next three bits of input form second digit of octal notation
    MOV CL,3
    ROR AL,CL
    ADD AL,30H
    PRINT AL

    MOV AL,BL
    AND AL,07H
    ADD AL,30H
    PRINT AL         
    POP BX
    POP AX 
RET
DEC_TO_OCT ENDP
    

END START ; SET ENTRY POINT AND STOP THE ASSEMBLER.
