	.LF marzbios.lst
;---------------------------------------------------------------------------
;
;		MARZ80 BIOS
;
;---------------------------------------------------------------------------

	.CR	Z80						It's a Z80 assembler now
	.TF marzbios.bin, bin
	.OR $0000

STACK_TOP	.EQ $FFFF	Stack pointer starting address
PORT_A		.EQ $00		8255 PORT A address - 16 x 2 LCD display
PORT_B		.EQ $01		8255 PORT B address - Not assigned
PORT_C		.EQ $02		8255 PORT C address - control port for PORT A & PORT B
PORT_CTL	.EQ $03		8255 Control register address

COLD_START
	JP WARM_START

	.NO $0008,$FF

RST_08
	DI
	CALL SCAN_CODE
	RETI

	.NO $0040,$FF

BIOS_MSG	.DB "MARZ80 BIOS V1.0", $0A

WARM_START
	LD SP, STACK_TOP	Initialize the stack pointer

;---------------------------------------------------------------------------
;	$C2 Sets the 8255 GROUP A to MODE 2: PORT A bidirectional 
;										 PORT C Upper to CTL
;					  GROUP B to MODE 0: PORT B INPUT, C Lower to outputs
;---------------------------------------------------------------------------

	LD A, $C2
	OUT (PORT_CTL), A	Send the control word to the 8255 Control Register

	LD A, $38			Set LCD to 8 bit Mode, 2 lines, & 5x8 font
	CALL LCD_COMMAND
	LD A, $0F			Init display instruction
	CALL LCD_COMMAND
	LD A, $01			Clear display instruction
	CALL LCD_COMMAND

	LD HL, BIOS_MSG		Set HL to the bios message start address
	LD A, (HL)
NEXT_CHAR
	CALL LCD_DISPLAY
	INC HL
	LD A, (HL)
	CP $0A				Check for end of string
	JP NZ,NEXT_CHAR

	LD A, $A8			Move cursor to the beginning of the 2nd line
	CALL LCD_COMMAND
	LD A, $3E			Load cursor '>'
	CALL LCD_DISPLAY
	EI
	HALT

LCD_COMMAND
	CALL LCD_READY
	LD B, $04
	OUT (PORT_C), B		Set E and RS 
	OUT (PORT_A), A
	LD A, $05
	OUT (PORT_C), A		Set E and reset RS to send data to command register
	XOR A				Zero out accumulator
	OUT (PORT_C), A
	RET

LCD_DISPLAY
	CALL LCD_READY
	OUT (PORT_A), A
	LD A, $30
	OUT (PORT_C), A		Set E and RS to send data to data register
	XOR A				Zero out accumulator
	OUT (PORT_C), A
	RET

LCD_READY
	LD B, $06
	OUT (PORT_C), B		Set the LCD R/W and E bits to read the busy flag
	IN C, (PORT_A)		Read from the LCD
	LD B, $02
	OUT (PORT_C), B		Unset E of the LCD
	RL C				Rotate bit 7 into the carry flag
	JR C, LCD_READY		If the busy flag is set repeat the check
	RET

SCAN_CODE
;	IN A, (PORT_B)		Read the current scan code from keyboard controller
; 						Conditional handling of scan codes for control or echo
	RET
