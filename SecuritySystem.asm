; --- Constants ---
Channel0:  EQU &HC0
Channel1:  EQU &HC1
Channel2:  EQU &HC2
Channel3:  EQU &HC3
Channel4:  EQU &HC4
Channel5:  EQU &HC5
Channel6:  EQU &HC6
Channel7:  EQU &HC7
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005

; --- Program ---
            ORG 0
Reset:      IN   Channel0
            OUT  Hex0
            JUMP Reset
