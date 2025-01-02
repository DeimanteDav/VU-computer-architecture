.model small
.stack 100h

.data
    old_ip DW ?
    old_cs DW ?

    regAX_name DW "xa"
    regCX_name DW "xc"
    regDX_name DW "xd"
    regBX_name DW "xb"
    regSP_name DW "ps"
    regBP_name DW "pb"
    regSI_name DW "is"
    regDI_name DW "id"
    regAX DW ?
    regCX DW ?
    regDX DW ?
    regBX DW ?
    regSP DW ?
    regBP DW ?
    regSI DW ?
    regDI DW ?

    regAL_name DW "la"
    regCL_name DW "lc"
    regDL_name DW "ld"
    regBL_name DW "lb"
    regAH_name DW "ha"
    regCH_name DW "hc"
    regDH_name DW "hd"
    regBH_name DW "hb"

    message             DB "Zingsninio rezimo pertraukimas! $"
    mnem                DB "neg $"
    reg_value           DB ?
    reg_name            DW ?
    dollar_symbol       DB "$"
    newLine             DB 13, 10, "$"
    pos                 DW 5 dup("$")
    segm                DW 5 dup("$")
    op_code1            DB ?
    op_code2            DB ?

.code
main:
    mov ax, @data
    mov ds, ax          

; ISSISAUGOME SENUS PERTRAUKIMO CS, IP
    MOV AX, 0
    MOV ES, AX  	; Extra segmentas prasides ten pat kur vektoriu lentele
    MOV AX, ES:[4]
    MOV BX, ES:[6]
    MOV old_cs, BX
    MOV old_ip, AX

; PERIMAME PERTRAUKIMĄ
    MOV AX, CS
    MOV BX, offset interrupt_handler

    MOV ES:[4], BX
    MOV ES:[6], AX

; AKTYVUOJAME ŽINGSINĮ REŽIMĄ (flag TF=1)
    PUSHF 		; push SF
    POP AX
    or AX, 100h
    PUSH AX
    POPF 		; pop SF
    NEG AX      ; Bet kokia komanda, kuri nebus atpažinta

; BET KOKIOS KOMANDOS
    MOV AX, 12H
    NEG AX
    MOV DX, 0F8h
    NEG DX
    MOV CX, 0F8h
    NEG CX
    MOV BX, 0F8h
    NEG BX
    MOV BX, 0FD5H
    NEG BX

    MOV AL, 33H
    NEG AL
    MOV BL, 13h
    NEG BL
    MOV CL, 33h
    NEG CL
    MOV AH, 22h
    NEG AH
    MOV DH, 09h
    NEG DH

; IŠJUNGIAME ŽINGSNINĮ REŽIMĄ
    PUSHF
    POP  AX
    and  AX, 0FEFFh ;1111 1110 1111 1111 (nuliukas priekyj F, nes skaiciai privalo prasideti skaitmeniu, ne raide) - TF=0, visi kiti liks nepakeisti
    PUSH AX
    POPF 

; ATSTATOME SENĄ PERTRAUKIMO ADRESĄ (CS, IP)
    MOV AX, old_ip
    MOV BX, old_cs
    MOV ES:[4], AX
    MOV ES:[6], BX

  exit:
    MOV AH, 4Ch
    INT 21h

;******************************************************
; PERTRAUKIMO APDOROJIMO PROCEDŪRA
;******************************************************
interrupt_handler PROC
    MOV regAX, AX
    MOV regCX, CX
    MOV regDX, DX
    MOV regBX, BX
    MOV regSP, SP
    MOV regBP, BP
    MOV regSI, SI
    MOV regDI, DI

    PUSH AX
    PUSH BX
    PUSH DX
    PUSH BP
    PUSH ES
    PUSH DS

    MOV BP, SP        ; SP - stack pointer
    add BP, 12
    MOV BX, [BP]
    MOV pos, BX
    MOV ES, [BP + 2]
    MOV segm, ES
    MOV dx, [ES:BX]
    MOV op_code1, DL
    MOV op_code2, DH

; TIKRINAME AR KOMANDA yra NEG
    MOV AL, DL 
    CMP AL, 0F6h 
    JE checkNEG_8
    CMP AL, 0F7h
    JE checkNEG_16
    JMP notNEG
  checkNEG_8:
    MOV AL, DH
    AND AL, 38h     ; 38h = 00111000b
    SHR AL, 3       ; 3 = 011 - shift to right by 3
    CMP AL, 3
    JE checkReg_8
  checkNEG_16:
    MOV AL, DH
    AND AL, 38h     ; 38h = 00111000b
    SHR AL, 3       ; 3 = 011 - shift to right by 3
    CMP AL, 3
    JE checkReg_16_1

  notNeg:
    JMP goBack

  checkReg_8:
    MOV DL, op_code2
    CMP DL, 0D8h
    JE AL_isReg
    CMP DL, 0D9h
    JE CL_isReg
    CMP DL, 0DAh
    JE DL_isReg
    CMP DL, 0DBh
    JE BL_isReg
    CMP DL, 0DCh
    JE AH_isReg
    CMP DL, 0DDh
    JE CH_isReg
    CMP DL, 0DEh
    JE DH_isReg
    CMP DL, 0DFh
    JE BH_isReg
    JMP goBack
  
  checkReg_16_1:
    JMP checkReg_16

  AL_isReg:
    MOV DX, regAL_name
    MOV AX, regAX
    JMP storeRegister
  CL_isReg:
    MOV DX, regCL_name
    MOV AX, regCX
    JMP storeRegister
  DL_isReg:
    MOV DX, regDL_name
    MOV AX, regDX
    JMP storeRegister
  BL_isReg:
    MOV DX, regBL_name
    MOV AX, regBX
    JMP storeRegister
  AH_isReg:
    MOV DX, regAH_name
    MOV AX, regAX
    MOV AL, AH
    JMP storeRegister
  CH_isReg:
    MOV DX, regCH_name
    MOV AX, regCX
    MOV AL, AH
    JMP storeRegister
  DH_isReg:
    MOV DX, regDH_name
    MOV AX, regDX
    MOV AL, AH
    JMP storeRegister
  BH_isReg:
    MOV DX, regBH_name
    MOV AX, regBX
    MOV AL, AH
    JMP storeRegister

; TIKRINAME KOKS REGISTRAS
  checkReg_16:
    MOV DL, op_code2
    CMP DL, 0D8h
    JE AX_isReg
    CMP DL, 0D9h
    JE CX_isReg
    CMP DL, 0DAh
    JE DX_isReg
    CMP DL, 0DBh
    JE BX_isReg
    CMP DL, 0DCh
    JE SP_isReg
    CMP DL, 0DDh
    JE BP_isReg
    CMP DL, 0DEh
    JE SI_isReg
    CMP DL, 0DFh
    JE DI_isReg1
    JMP goBack

  AX_isReg:
    MOV DX, regAX_name
    MOV AX, regAX
    JMP storeRegister
  CX_isReg:
    MOV DX, regCX_name
    MOV AX, regCX
    JMP storeRegister
  DX_isReg:
    MOV DX, regDX_name
    MOV AX, regDX
    JMP storeRegister
  DI_isReg1:
    JMP DI_isReg
  BX_isReg:
    MOV DX, regBX_name
    MOV AX, regBX
    JMP storeRegister
  SP_isReg:
    MOV DX, regSP_name
    MOV AX, regSP
    JMP storeRegister
  BP_isReg:
    MOV DX, regBP_name
    MOV AX, regBP
    JMP storeRegister
  SI_isReg:
    MOV DX, regSI_name
    MOV AX, regSI
    JMP storeRegister
  DI_isReg:
    MOV DX, regDI_name
    MOV AX, regDI
    JMP storeRegister

  storeRegister:
    MOV reg_name, DX
    MOV reg_value, AL
    JMP print

  print:
    MOV AH, 9
    MOV DX, offset message
    INT 21h

    MOV AX, segm  
    CALL printAX
    MOV AH, 2
    MOV DL, ":" 
    INT 21h
    MOV AX, pos
    CALL printAX
	  CALL printSpace

    MOV AL, op_code1
    CALL printAL
    MOV AL, op_code2
    CALL printAL
    CALL printSpace

    MOV AH, 9
    MOV DX, offset mnem      ; neg
    INT 21h

    MOV DX, offset reg_name
    INT 21h

    CALL printSpace
    MOV AH, 2
    MOV DL, ";"  	          ; spausdinam kabliataškį
    INT 21h

    CALL printSpace
    MOV AH, 9
    MOV DX, offset reg_name
    INT 21h

    MOV AH, 2
    MOV DL, "="  	           ; spausdinam lygybę
    INT 21h
    CALL printSpace

    XOR AX, AX
    MOV AL, reg_value
    CALL printAL

    MOV AH, 9
    MOV DX, offset newLine
    INT 21h

  goBack:
    MOV AX, regAX
    MOV BX, regBX
    MOV CX, regCX
    MOV DX, regDX
    MOV SP, regSP
    MOV BP, regBP
    MOV SI, regSI
    MOV DI, regDI

    IRET ; - grįžimas is pertraukimo apdorojimo procedūros
interrupt_handler ENDP

;******************************************************
; PAGALBINĖS PERTRAUKIMO NAUDOJAMOS PROCEDŪROS
;******************************************************
printAX PROC
    PUSH AX
    MOV AL, AH
    CALL printAL
    POP AX
    CALL printAL
    RET
printAX ENDP

printSpace PROC
    PUSH AX
    PUSH DX
    MOV AH, 2
    MOV DL, " "
    INT 21h
    POP DX
    POP AX
    RET
printSpace ENDP

printAL PROC
    PUSH AX
    PUSH CX
    PUSH AX
    MOV CL, 4
    SHR AL, CL 
    CALL printHex
    POP AX
    CALL printHex
    POP CX
    POP AX
    RET
printAL ENDP

; Spausdina hex skaitmeni pagal AL jaunesniji pusbaiti (4 jaunesnieji bitai - > AL=72, tai 0010)
printHex PROC
    PUSH AX
    PUSH DX
    AND AL, 0Fh
    CMP AL, 9
    JBE printHex_0_9
    JMP printHex_A_F

  printHex_A_F:
    SUB AL, 10
    ADD AL, 41h
    MOV DL, AL
    MOV AH, 2           ; Print A-F
    INT 21h
    JMP printHex_grizti

  printHex_0_9:
    MOV DL, al
    ADD DL, 30h
    MOV AH, 2           ; Print 0-9
    INT 21h
    JMP printHex_grizti

  printHex_grizti:
    POP DX
    POP AX
    RET
printHex ENDP

END main