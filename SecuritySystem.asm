; ADC Test - reads channel 0, displays on 7-seg
ORG 0
Reset:
    IN   CH0
    OUT  Hex0
    JUMP Reset

; ADC Peripheral Addresses
ORG &HC0
CH0:  DW 0

; I/O Constants
Hex0:  EQU 004
