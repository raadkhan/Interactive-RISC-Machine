	MOV R6, stack_begin
	LDR R6, [R6]
	MOV R5, SW_BASE
	LDR R5, [R5]
	LDR R0, [R5]
	MOV R4, LEDR_BASE
	LDR R4, [R4]
	MOV R1, #5
	MOV R2, #9
	MOV R3, #16
	BL leaf
	STR R0, [R4]
	HALT

leaf:
	STR R4, [R6]
	STR R5, [R6, #-1]
	ADD R4, R0, R1
	MOV R0, R4, LSL#1
	CMP R4, R3
	BLE petal
	ADD R5, R2, R3
	MVN R5, R5
	ADD R4, R4, R5
	MOV R5, #1
	ADD R4, R4, R5
	MOV R0, R4

petal:
	LDR R5, [R6, #-1]
	LDR R4, [R6]
	BX R7

stack_begin:
	.word 0xFF
SW_BASE:
	.word 0x0140
LEDR_BASE:
	.word 0x0100
