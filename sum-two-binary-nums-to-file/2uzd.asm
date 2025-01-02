LOCALS @@
.MODEL small
.STACK 256
.DATA
    pos     DW 0
    length1 DW 0
    length2 DW 0
    length3 DW 0
    handle  DW 0                        ; Failo deskriptoriaus numeris
    error   DB "Error reading from file!"
    errorLen = $-error                  ; Eilutes ilgis gaunamas is einamojo adreso ($) atemus jos pradzios adresa
    Helpmsg DB "Program sums two binary numbers from files and prints to result file.",0dh,0ah,"Program gets parameters in this order:",0dh,0ah,"2uzd data_file1 data_file2 result_file"
    HelpLen = $-Helpmsg                 ; Eilutes ilgis gaunamas is einamojo adreso ($) atemus jos pradzios adresa
    fname1  DB 20h DUP(?)               ; input1
    fname2  DB 20h DUP(?)               ; input2
    fname3  DB 20h DUP(?)               ; output
    fbuf1   DB 1000h DUP(?)             ; Skaitymo buferis
    fbuf2   DB 1000h DUP(?)             ; Skaitymo buferis 2
    fbuf3   DB 1000h DUP(?)             ; Rasymo buferis

.CODE
Start:
    MOV BL, [ds: 80h]               ; parametrų eilutės ilgis
    XOR BH, BH
    MOV byte ptr [BX + 81h], ' '    ; įdedam po parametrų eilutės tarpą; susiaurinam [bx + 81h] iki baito

    MOV CX, DS                      ; Issisaugom psp segmenta i CX

    MOV AX, @data
    MOV DS, AX    

    CLD                            ; clear isvalyt direction flag; default = 0
    MOV SI, 82h                    ; nustatom SI į parametrų pradžią
    MOV [pos], OFFSET fname1
    CALL ReadingArguments

    CALL Help

    MOV [pos], OFFSET fname2
    CALL ReadingArguments
    MOV [pos], OFFSET fname3
    CALL ReadingArguments

    MOV DX, OFFSET fname1
    MOV [pos], OFFSET fbuf1
    CALL ReadFile
    MOV [length1], CX               ; nuskaitytą ilgį įrašom į [length1]

    MOV DX, OFFSET fname2
    MOV [pos], OFFSET fbuf2
    CALL ReadFile
    MOV [length2], CX

    CALL Sum
    CALL WriteFile

Exit:
    MOV AX, 04C00h
    INT 21h ; int 21,4C - programos pabaiga

;-------------------------------------------------------------------
; ReadingArguments - writes one of the parameters into memory
;-------------------------------------------------------------------
ReadingArguments PROC
    PUSH BX
    PUSH AX
    MOV BX, [pos]

    @@read:
    PUSH DS
    MOV DS, CX
    LODSB                    ; al <-- [ds:si] su SI poslinkiu
    POP DS
    CMP AL, ' '
    JE @@delete
    MOV [BX], AL
    INC BX
    JMP @@read

    @@delete:
    PUSH DS
    MOV DS, CX
    LODSB
    POP DS
    CMP AL, ' '
    JNZ @@end
    JMP @@delete
    
    @@end:
    DEC SI                    ; ant SI yra prasmingas simbolis (ne tarpas)
    MOV byte ptr [BX], 0      ; kai nuskaito parametrą, gale prideda 0
    POP AX
    POP BX
    RET
ReadingArguments ENDP

;-------------------------------------------------------------------
; Help
;-------------------------------------------------------------------
Help PROC
    CMP [fname1], '/'
    JNZ @@end
    CMP [fname1+1], '?'
    JNZ @@end
    MOV DX, OFFSET Helpmsg
    MOV CX, (HelpLen)                 ; CX = ilgis
    CALL PrintBuf
    JMP Exit

    @@end:
    RET
Help ENDP

;-------------------------------------------------------------------
; Sum
;-------------------------------------------------------------------
Sum PROC
    PUSH 0
    XOR BX, BX
    MOV CX, [length1]
    CMP CX, [length2]
    JA @@continue               ; jump if above - jei length1 ilgesnis už length2 tesiame, o jei ne apkeičiam vietomis
    MOV CX, [length2]

    @@continue:
    INC CX                      ; +1 prie ilgio, nes dvejetainių sumos ilgis turi būti ilgesnis
    MOV [length3], CX
    DEC CX                      ; atsatom ilgį į pradinę reikšmę

    @@repeat:
    INC BX
    PUSH BX
    XOR AL, AL
    SUB BX, [length1]           ; surandamas skirtumas tarp BX ir lenght1
    NEG BX                      ; randam BX teigiamą reikšmę
    CMP BX, 0
    JL @@less                  ; jump if less - pasiekiama pirmojo buferio pabaiga, jei BX < 0
    MOV AL, [fbuf1 + BX]        ; imam reikšmę iš 1 buferio į AL
    SUB AL, '0'                 ; paverčia ASCII į skaičių -30h

    @@less:
    POP BX
    PUSH BX
    SUB BX, [length2]
    NEG BX
    CMP BX, 0
    JL @@less2
    MOV DL, [fbuf2 + BX]         ; imam reikšmę iš 2 buferio į - DL
    SUB DL, '0'
    add AL, DL

    @@less2:
    POP BX
    POP DX                      ; POP DX--> 0
    ADD AL, DL                  ; prideda sena liekana, kaip sudeties stulpeliu
    XOR DX, DX
    CMP AL, 2                   ; tikrinam ar suma daugiau nei 2
    JB @@zero                   ; jump if below - 
    SUB AL, 2                   ; jei suma > 2, sumažinam AL
    INC DX                      ; +1 minty
    
    @@zero:
    PUSH DX
    ADD AL, '0'                 ; rez paverčiamas į ASCII simbolį +30h
    PUSH BX                     ; bx - kiek sudejau zenklu
    SUB BX, [length3]           ; surandamas skirtumas tarp BX ir lenght3
    NEG BX
    MOV [fbuf3 + BX], AL        ; išsaugome rez į 3 buferį
    POP BX
    LOOP @@repeat               ; kol CX = 0

    MOV [fbuf3], ' '
    POP DX
    CMP DX, 0                   ; tikrinam ar neliko nieko minty
    JE @@end                    
    ADD DL, '0'                 ; jei liko, paverčiam į ASCII
    MOV [fbuf3], DL             ; 

    @@end: 
    RET
Sum ENDP

;-------------------------------------------------------------------
; ReadFile - reads data from file
; IN
; DX - offset of filename
; [pos] - offset of output buffer
; OUT
; CX - number of symbols read
; output buffer - data
;-------------------------------------------------------------------
ReadFile PROC
    MOV [Handle], 0             ; assign(f1,'failas1');
    MOV AX, 3d00h               ; funkcija nuskaito faila i AX
    INT 21h
    JC @@Exit                   ; if carryflag. jei neatsidaro failas.
    MOV [handle], AX            ; Issaugoti deskriptoriu
    MOV BX, AX
    PUSH 0

    @@loopReading:
    MOV AH, 3fh                 ; read file funkcija
    MOV DX, [pos]
    POP CX                      ; CX uzrasys ilgi nuskaityto skaiciaus
    add DX, CX
    PUSH CX
    MOV CX, 100h                ; ! 256 baitu
    INT 21h                     ; vykdo funkcija is AX - read faila
    JC @@Exit
    XOR AX, AX
    JZ @@Exit                   ; EOF - failo Exit
    POP CX
    ADD CX, AX
    PUSH CX                      
    JMP @@loopReading           ; nuskaito 256 baitu, kartoja LOOP.

    @@Exit:
    POP CX
    MOV BX, [Handle]
    or BX, BX
    JZ @@dontClose
    MOV AH,3Eh
    INT 21h                     ; Uzdaryti faila

    @@dontClose:
    or BX, BX
    JNZ @@end
    MOV CX, (errorLen)
    MOV DX, OFFSET error
    CALL PrintBuf               ; Atspausdiname klaidos pranesima  
    JMP Exit
    @@end:
    RET
ReadFile ENDP

;-------------------------------------------------------------------
; writes results from fbuf3 to file fname3
;-------------------------------------------------------------------
WriteFile PROC
    MOV DX, OFFSET fname3
    MOV AH, 3Ch                 ; create file funkcija
    MOV CX, 100000b             ; 32 dvejetainiai skaitmenys.
    INT 21h                     ; sukurti faila
    JC @@end
    MOV BX, AX
    MOV AH, 40h
    MOV CX, [length3]
    MOV DX, OFFSET fbuf3
    INT 21h                     ; irasyti rezultata i faila
    MOV AH, 3Eh
    INT 21h                     ; Uzdaryti faila
    @@end:    
    RET
WriteFile ENDP

;-------------------------------------------------------------------
; PrintBuf - prints char buffer to STDOUT
; IN
; CX - char count
; DX - buf
;-------------------------------------------------------------------
PrintBuf PROC
    PUSH AX 
    PUSH BX 
    MOV AH, 40h
    MOV BX, 1
    INT 21h 
    POP BX 
    POP AX
    RET
PrintBuf ENDP
END Start