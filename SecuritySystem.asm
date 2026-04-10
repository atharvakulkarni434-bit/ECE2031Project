; SecuritySystem.asm

ORG 0
Reset:
	LOAD Channel0
    OUT  Hex0
    JUMP Reset

; Variables
Pattern:   DW 0

; Peripheral Channels
ORG &HC0
Channel0:  DW 0
Channel1:  DW 0
Channel2:  DW 0
Channel3:  DW 0
Channel4:  DW 0
Channel5:  DW 0
Channel6:  DW 0
Channel7:  DW 0

; Sensor Inputs
ORG &HD0
Motion:    DW 0
Other:     DW 0

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005