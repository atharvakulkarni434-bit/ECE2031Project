; ----------------------
; Flash all LEDs for new high score
; ----------------------
FlashAllLEDs:
    LOADI 4
    STORE FlashCount

FlashLoop:
    ; LEDs all ON
    LOAD  AllLEDs
    OUT   LEDs
    CALL  Delay

    ; LEDs all OFF
    LOADI 0
    OUT   LEDs
    CALL  Delay

    LOAD  FlashCount
    ADD   MinusOne
    STORE FlashCount
    JZERO FlashDone
    JUMP  FlashLoop

FlashDone:
    RETURN

Delay:
    OUT Timer
WaitingLoop:
    IN  Timer
    ADDI -3
    JNEG WaitingLoop
    RETURN

ORG 400

FlashCount:       DW 0
AllLEDs:       DW &H03FF
