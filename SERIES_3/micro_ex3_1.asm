DATA SEGMENT
    MSG1 DB "GIVE 3 HEX DIGITS: $"
    MSG2 DB "Decimal: $"
    NEWLINE DB 0AH,0DH,'$'
ENDS

STACK SEGMENT
    DW   128  DUP(0)
ENDS      

;Read (no echo) macro
READ MACRO  ;AL<-INPUT FROM KEYB
    MOV AH, 8;
    INT 21H
ENDM

;Print char macro
PRINT MACRO CHAR
    MOV DL,CHAR
    MOV AH,2
    INT 21H
ENDM

;Print string macro
PRINT_STR MACRO STRING
    MOV DX,OFFSET STRING
    MOV AH,9
    INT 21H
ENDM

CODE SEGMENT 
    ASSUME CS:CODE,SS:STACK,DS:DATA
START:
; SET SEGMENT REGISTERS:
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX

INIT:
    PRINT_STR MSG1  ;Print prompt "GIVE 3 HEX DIGITS: "
    CALL HEX_KEYB   ;Input first HEX digit
    MOV BH,AL       
    ROL BH,4        ;Put first hex digit to BH msb's
    CALL HEX_KEYB   ;Input second HEX digit
    ADD BH,AL       ;Put second digit in BH lsb's
    PRINT '.'       ;Print '.' to prompt for last digit
    CALL HEX_KEYB   ;Input last HEX digit 
    MOV BL,AL       ;Last digit is put on BL lsb's
    CMP BX,0C102H   ;If BX= C102H then input was C12 and terminate
    JE QUIT
    PRINT_STR NEWLINE ;Result is printed on new line
    PRINT_STR MSG2  ;Print promp "DECIMAL: "
    
    CALL PRINT_DEC  ;Print three digit decimal number
    PRINT '.'
    MOV AX,2710H    ;multiply decimal part (bl) with 10000
    MOV BH,00H      
    MUL BX
    MOV CX,0010H    ; CX=16
    DIV CX ;DEKADIKO MEROS*10000/16
    
    CALL PRINT_DEC2 ;AX has a four digit decimal number for print
    PRINT_STR NEWLINE
    JMP INIT   ;ENDLESS LOOP
           
    QUIT:
    MOV AX, 4C00H ; EXIT TO OPERATING SYSTEM.
    INT 21H 
    
HEX_KEYB PROC       ;READS FROM KEYBOARD AND PLACES IN AX
    PUSH DX
IGNORE:
    READ
    CMP AL,30H
    JL IGNORE
    CMP AL,39H
    JG ADDR1
    PUSH AX 
    PRINT AL
    POP AX
    SUB AL,30H
    JMP ADDR2
ADDR1:
    CMP AL,'A'
    JL IGNORE
    CMP AL,'F'
    JG IGNORE
    PUSH AX   
    PRINT AL
    POP AX
    SUB AL,37H
ADDR2:
    POP DX  
    RET
    HEX_KEYB ENDP

;PRINT BH IN DECIMAL FORMAT    
PRINT_DEC PROC  
    PUSH DX  
    PUSH CX
    MOV AL,BH
    MOV AH,00H
    MOV DL,64H
    DIV DL
    MOV DL,AL
    CALL PRINT_HEX 
    MOV DL,0AH
    MOV AL,AH  
    MOV AH,00H
    DIV DL
    MOV DL,AL
    CALL PRINT_HEX
    MOV DL,AH
    CALL PRINT_HEX
    POP CX
    POP DX
    RET
PRINT_DEC ENDP     

;Print hex
PRINT_HEX PROC  
            PUSH DX
            CMP DL,9
            JG ADDR10
            ADD DL,30H
            JMP ADDR20
ADDR10:   ADD DL,37H
ADDR20:   
        PUSH AX
        PRINT DL
        POP AX
        POP DX
        RET
PRINT_HEX ENDP

;PRINTS AX (four digits) IN DECIMAL FORMAT                          
PRINT_DEC2 PROC  
    PUSH DX   
    MOV DX,00H
    MOV CX,03E8H
    DIV CX
    PUSH DX
    MOV DL,AL  
    PUSH AX
    CALL PRINT_HEX
    POP AX
    POP DX
    MOV AX,DX
    MOV DL,64H
    DIV DL
    MOV DL,AL 
    PUSH AX
    CALL PRINT_HEX
    POP AX
    MOV DL,0AH
    MOV AL,AH  
    MOV AH,00H
    DIV DL
    MOV DL,AL
    CALL PRINT_HEX
    MOV DL,AH
    CALL PRINT_HEX
    POP DX
    RET
   
PRINT_DEC2 ENDP     
                          
   
ENDS

END START ; SET ENTRY POINT AND STOP THE ASSEMBLER.
