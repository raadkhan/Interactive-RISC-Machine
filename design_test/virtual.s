	MOV R5, seed
	LDR R5, [R5]
	MOV R4, stem
	LDR R4, [R4]
	MOV R3, result
	LDR R3, [R3]

	MOV R0, #10
	MOV R1, #7
	STR R0, [R5]
	STR R1, [R5, #-1]

	MOV R2, tree
	BLX R2

	STR R0, [R3]

	MOV R0, #4
	MOV R1, #8
	STR R0, [R4]
	STR R1, [R4, #-1]

	MOV R2, leaf
	BLX R2

	STR R0, [R3, #1]

	HALT

tree:
	LDR R0, [R5]
	LDR R1, [R5, #-1]
	ADD R0, R0, R1
	BX R7

leaf:
	LDR R0, [R4]
	LDR R1, [R4, #-1]
	ADD R0, R0, R1
	BX R7

seed:
.word 0xFF

stem:
.word 0xEE

result:
.word 0xDD