.model small
.stack 100h

.data 
    message         DB 'Enter symbols: ', 10, 13, '$'
    message_result  DB 'Decimal values: ', 10, 13, '$'
    buffer          DB 10, ?, 10 dup(0)
    new_line        DB 10, 13, "$"

.code

start:
    MOV AX, @data
    MOV DS, AX

    MOV DX, offset message
    MOV AH, 09h
    INT 21h

    MOV DX, offset buffer
    MOV AH, 0Ah
    INT 21h

    MOV DX, offset new_line
    MOV AH, 09h
    INT 21h

    MOV DX, offset message_result
    MOV AH, 09h
    INT 21h

    MOV SI, offset buffer
    ADD SI, 2
    MOV CL, [SI - 1] ; gauti inputo ilgi

next_char:
    CMP CL, 0       ; patikrinam ar dar liko simbolių
    JE done

    XOR AX, AX
    MOV AL, [SI]    ; perkeliame dabartinį simbolį į AL

    CALL print_decimal

    MOV DL, ' '
    MOV AH, 02h
    INT 21h

    INC SI          ; pereinam prie kito simbolio
    DEC CL          ; sumažiname simbolių skaičių
    JMP next_char

done:
    MOV AH, 4Ch
    INT 21h


print_decimal PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10
    XOR CX, CX

convert:
    XOR DX, DX      ; išvalome DX prieš dalybą
    DIV BX          ; padalinti AB is BX (10), kad gauti dešimtainę, liekana į DX
    ADD DL, '0'     ; konvertuojame į skaičių
    PUSH DX
    INC CX

    CMP AX, 0       ; tikrina ar dar yra simbolių
    JNE convert     ; jei ne lygu 0 convertuoja toliau

print_loop:
    POP DX
    MOV AH, 02h
    INT 21h
    LOOP print_loop

    POP DX
    POP CX
    POP BX 
    POP AX
    RET
print_decimal ENDP

END Start