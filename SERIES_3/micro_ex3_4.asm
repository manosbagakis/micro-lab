DATA SEGMENT
    
DATA ENDS

STACK SEGMENT
    DW 128 DUP(0)
ENDS       
   
READ MACRO
    MOV AH,8
    INT 21H
ENDM

PRINT MACRO CHAR
    MOV DL,CHAR
    MOV AH,2
    INT 21H
ENDM   

EXIT MACRO
    MOV AX,4C00H
    INT 21H
ENDM    
   
CODE SEGMENT
   ASSUME CS:CODE, DS:DATA
MAIN PROC FAR
    MOV AX, DATA
    MOV DX,AX
    MOV ES,AX  
    
START:    
    CALL READ_1DEC   ;read the first decimal number,print it in decimal, store it in BX in HEX and read the operators '-' or '+' 
                     ; AL has either Q or the symbols '+' or '-'
    CMP AL,'Q'       ;if the input is 'Q' end the program
    JE QUIT_MAIN
    PRINT AL         ;print the operator
    MOV DL,AL        ;store the operator in DL
    CALL READ_2DEC   ;read the second decimal number, print it in decimal, store it in CX in HEX and read the operator '='
                     ;AL has either Q or the symbol '='
    CMP AL,'Q'       ;if the input is 'Q' end the program
    JE QUIT_MAIN 
    PUSH DX
    PRINT '='        
    POP DX
    CMP DL,'-'      ;if the operator in DL is '+' add the numbers, if it is '-' subtract the second number from the first
    JE SU
AD:
    ADD BX,CX       ;add BX and CX
    MOV AX,BX
    CALL PRINT_16BIT_NUM   ;print the result stored in AX in HEX
    PRINT '=' 
    MOV AX,BX
    CALL HEX_TO_DEC  ;convert the result store in AX from heximal to decimal
    CALL PRINT_16BIT_NUM   ; print the result stored in AX in decimal
    JMP NEXT                ; get next input
SU: 
    CMP BX,CX      
    JE ZERO        ;if BX = CX the result is 0
    CMP BX,CX
    JG POSITIVE    ;if BX-CX>0 the result is positive
NEGATIVE:          ;if (BX-CX)<0 the result is -(CX-BX)
    PRINT '-'
    SUB CX,BX
    MOV AX,CX
    CALL PRINT_16BIT_NUM  ;print the result store in AX in HEX
    PRINT '='  
    PRINT '-'
    MOV AX,CX  
    CALL HEX_TO_DEC   ;convert the hexadecimal result in decimal
    CALL PRINT_16BIT_NUM  ;print the decimal result
    JMP NEXT              ;get next input
ZERO:
    PRINT '0' ;if CX=BX print 0=0
    PRINT '='
    PRINT '0'
    JMP NEXT  ;get next input
POSITIVE:
    SUB BX,CX
    MOV AX,BX   ;AX = BX-CX
    CALL PRINT_16BIT_NUM  ;print heximal result
    PRINT '=' 
    MOV AX,BX
    CALL HEX_TO_DEC
    CALL PRINT_16BIT_NUM  ;print decimal result        
NEXT:
    PRINT 0AH
    PRINT 0DH   ;newline
JMP START      
    
    
QUIT_MAIN:    
    EXIT
MAIN ENDP  


HEX_TO_DEC PROC NEAR     ;gets a hexadecimal number in AX and returns the same number in decimal in AX
    PUSH BX 
    PUSH CX
    MOV DX,0
    MOV BX,3E8H 
    DIV BX
    MOV CH,AL   ;CH = input/1000
    ROL CH,1
    ROL CH,1
    ROL CH,1
    ROL CH,1    ;4 MSB of CH have the 1st decimal digit
    MOV AX,DX
    MOV BL,64H
    DIV BL      ;AL = (input%1000)/100 
    ADD CH,AL   ;4LSB of CH have the 2nd decimal digit
    MOV AL,AH
    MOV AH,00H
    MOV BL,0AH
    DIV BL     ;AL = (input%100)/10
    MOV CL,AL
    ROL CL,1
    ROL CL,1
    ROL CL,1
    ROL CL,1 ;4MSB of CL have the 3rd digit
    ADD CL,AH ;4LSB of CL have the 4th digit
    MOV AX,CX
    POP CX
    POP BX
    RET    
HEX_TO_DEC ENDP    

PRINT_16BIT_NUM PROC NEAR   ;gets a 4-digit number from ав and prints it
    PUSH DX
    PUSH CX
    MOV DX,AX
    AND AX,0F000H
    CMP AX,0
    JE PRINT_2ND  ;if the number begins with 0 start printing from the 2nd digit
    MOV CL,4
    ROL AX,CL
    CALL PRINT_HEX ;print the 1st digit
PRINT_2ND:
   MOV AX,DX
   AND AX,0FF00H
   CMP AX,0
   JE PRINT_3RD   ;if the number starts with 00 start printing form the 3rd digit  
   AND AX, 0F00H
   MOV CL,8
   ROR AX,CL
   CALL PRINT_HEX   ;print the 2nd digit
PRINT_3RD:
    MOV AX,DX
    AND AX,0FFF0H
    CMP AX,0
    JE PRINT_4TH   ;if the number starts with 000 print only the 4th digit
    AND AX,000F0H
    MOV CL,4
    ROR AX,CL
    CALL PRINT_HEX   ;print the 3rd digit
PRINT_4TH:
    MOV AX,DX
    AND AX,000FH
    CALL PRINT_HEX   ;print the 4th digit
    POP CX
    POP DX
    RET
PRINT_16BIT_NUM ENDP            
    
    
PRINT_HEX PROC    ; gets a heximal number in AL and prints it
    PUSH DX
        CMP AL,9
        JG ADDR1
        ADD AL,30H   ;if it's a numerical digit add 30h to get the ascii code
        JMP ADDR2
ADDR1:    ADD AL,37H   ;if it's a letter add 37h
ADDR2:    PRINT AL
    POP DX
    RET
PRINT_HEX ENDP
       
    
READ_1DEC PROC NEAR  ;it reads a decimal number of 3 digits at most,it prints it,it converts it to heximal,it stores it in BX and reads the operator
    PUSH DX   
    MOV BX,0000H
GET_1DIG:    
    READ     ;read the first digit
    CMP AL,'Q'
    JE QUIT1
    CMP AL, 30H
    JL GET_1DIG
    CMP AL,39H
    JG GET_1DIG  ;if the input is not a valid decimal digit read again
    PUSH AX  
    PRINT AL
    POP AX     
    SUB AL,30H 
    MOV BL,AL ;BL has the first digit in HEX    
GET_2DIG:
    READ      ;read the second digit
    CMP AL,'Q'
    JE QUIT1
    CMP AL,'+'
    JE QUIT1
    CMP AL,'-'
    JE QUIT1     ; if it is an operator or Q go to the end
    CMP AL,30H
    JL GET_2DIG
    CMP AL,39H
    JG GET_2DIG   ;if it is not a valid input read again
    PUSH AX
    PRINT AL
    POP AX    
    SUB AL,30H
    MOV BH,AL ;temporarily store the 2nd digit in BH  
    MOV AL,BL
    MOV DL,0AH
    MUL DL  ;AX has the 1st digit*10D
    MOV BL,BH
    MOV BH,0 ;BX has the 2nd digit
    ADD BX,AX ;BX has the 2 digit decimal number in heximal
GET_3DIG:
    READ    ;read the 3rd digit
    CMP AL,'Q'
    JE QUIT1
    CMP AL,'+'
    JE QUIT1
    CMP AL,'-'
    JE QUIT1      ;if it is an operator or Q go to the end
    CMP AL,30H
    JL GET_3DIG
    CMP AL,39H
    JG GET_3DIG    ;if it is not a valid input read again
    PUSH AX 
    PRINT AL
    POP AX 
    SUB AL,30H
    MOV BH,AL   ;temporarily store the 3rd digit in BH
    MOV AL,BL
    MOV DL,0AH
    MUL DL
    MOV BL,BH
    MOV BH,0
    ADD BX,AX  ;BX HAS THE 3 DIGIT DEC NUMBER IN HEX
GET_ACTION:
    READ        ; read an operator or Q
    CMP AL,'Q'
    JE  QUIT1
    CMP AL,'+'
    JE QUIT1
    CMP AL,'-'
    JE QUIT1
    JMP GET_ACTION
       
QUIT1:    
    POP DX
    RET   
READ_1DEC ENDP   

READ_2DEC PROC NEAR
    PUSH DX 
    MOV CX,0000H
GET_1DIG2:    
    READ          ;read the 1st digit
    CMP AL,'Q'
    JE QUIT2
    CMP AL, 30H
    JL GET_1DIG2
    CMP AL,39H
    JG GET_1DIG2  ;if it is not a valid input read again
    PUSH AX  
    PRINT AL
    POP AX     
    SUB AL,30H 
    MOV CL,AL ;CL HAS THE FIRST DIGIT IN HEX    
GET_2DIG2:
    READ          ;read either the second digit, the operator = or Q 
    CMP AL,'Q'
    JE QUIT2
    CMP AL,'='
    JE QUIT2
    CMP AL,30H
    JL GET_2DIG2
    CMP AL,39H
    JG GET_2DIG2
    PUSH AX
    PRINT AL
    POP AX    
    SUB AL,30H
    MOV CH,AL ;TEMPORARILY STORE 2ND DIGIT IN CH  
    MOV AL,CL
    MOV DL,0AH
    MUL DL 
    MOV CL,CH
    MOV CH,0 ;CX HAS THE 2ND DIGIT
    ADD CX,AX ;CX HAS THE 2 DIGIT DEC NUMBER IN HEX
GET_3DIG2:
    READ         ;read either the 3rd digit, operator = or Q
    CMP AL,'Q'
    JE QUIT2
    CMP AL,'='
    JE QUIT2
    CMP AL,30H
    JL GET_3DIG2
    CMP AL,39H
    JG GET_3DIG2
    PUSH AX 
    PRINT AL
    POP AX 
    SUB AL,30H
    MOV CH,AL ;TEMPORARILY STORE 3RD DIGIT IN CH
    MOV AL,CL
    MOV DL,0AH
    MUL DL
    MOV CL,CH
    MOV CH,0
    ADD CX,AX  ;CX HAS THE 3 DIGIT DEC NUMBER IN HEX
GET_ACTION2:
    READ         ;read the operator = or Q
    CMP AL,'Q'
    JE  QUIT2
    CMP AL,'='
    JE QUIT2
    JMP GET_ACTION2
       
QUIT2:  
    POP DX
    RET   
READ_2DEC ENDP
ENDS 
END MAIN
    
       
