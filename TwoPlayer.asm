; PotDisplay.asm
; Both potentiometers control hex displays simultaneously
; Player 1 (CH0) -> Hex1 (middle-left displays)
; Player 2 (CH1) -> Hex0 (rightmost displays)
; Values shown as decimal 00-99

ORG 0

Loop:
    ; --- Player 1 ---
    IN CH0
    CALL ScaleTo99
    CALL PackDecimal
    OUT Hex1

    ; --- Player 2 ---
    IN CH1
    CALL ScaleTo99
    CALL PackDecimal
    OUT Hex0

    JUMP Loop

; ---------------------------------------------------------------
; ScaleTo99: divides AC (0-4095) down to 0-99
; ---------------------------------------------------------------
ScaleTo99:
    STORE ScaleTemp
    LOADI 0
    STORE ScaleQuot
ScaleLoop:
    LOAD ScaleTemp
    SUB Const41
    JNEG ScaleDone
    STORE ScaleTemp
    LOAD ScaleQuot
    ADDI 1
    STORE ScaleQuot
    JUMP ScaleLoop
ScaleDone:
    LOAD ScaleQuot
    RETURN

; ---------------------------------------------------------------
; PackDecimal: converts 0-99 in AC to tens*16 + ones
; Example: 73 -> 0x73 -> displays as "73" on hex
; ---------------------------------------------------------------
PackDecimal:
    STORE PackTemp
    LOADI 0
    STORE PackTens
PackLoop:
    LOAD PackTemp
    SUB Const10
    JNEG PackDone
    STORE PackTemp
    LOAD PackTens
    ADDI 1
    STORE PackTens
    JUMP PackLoop
PackDone:
    LOAD PackTens
    STORE ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD ShiftTemp
    ADD PackTemp
    RETURN

; Variables
ScaleTemp: DW 0
ScaleQuot: DW 0
PackTemp:  DW 0
PackTens:  DW 0
ShiftTemp: DW 0

; Constants
Const41:   DW 41
Const10:   DW 10

; IO
CH0:  EQU &HC0
CH1:  EQU &HC1
Hex0: EQU 004
Hex1: EQU 005
