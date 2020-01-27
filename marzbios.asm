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
PORT_B		.EQ $01		8255 PORT B address - Arduino Nano PS/2 kybd controller
PORT_C		.EQ $02		8255 PORT C address - control port for PORT A & PORT B
PORT_CTL	.EQ	$03		8255 Control register address

WARM_START

	LD SP, STACK_TOP	Initialize the stack pointer

;---------------------------------------------------------------------------
;		$86 Sets the 8255 GROUP A to MODE 0: PORT A & PORT C Upper to OUTPUTS
;		GROUP B to MODE 1: PORT B INPUT, C Lower to STROBE
;---------------------------------------------------------------------------

	LD A, $86
	OUT (PORT_CTL), A	Send the control word to the 8255 Control Register

;---------------------------------------------------------------------------
;		$38 Sets the 16x2 Display to 8 bit Mode, 2 lines, & 5x8 font size
;		The display is connected to PORT A of the 8255
;---------------------------------------------------------------------------

	LD A, $38					Setup the display as described above
	CALL LCD_COMMAND
	LD A, $0F					Init display instruction
	CALL LCD_COMMAND
	LD A, $01					Clear display instruction
	CALL LCD_COMMAND

	LD HL, BIOS_MSG		Set HL to the bios message start address
	LD A, (HL)
NEXT_CHAR
	CALL LCD_DISPLAY
	INC HL
	LD A, (HL)
	CP $0A						Check for end of string
	JP NZ,NEXT_CHAR

	LD A, $A8					Move cursor to the beginning of the 2nd line
	CALL LCD_COMMAND
	LD A, $3E					Load cursor '>'
	CALL LCD_DISPLAY

	HALT

ECHO
	IN A, (PORT_C)		Read PORT C to Accumulator
	LD C, $02					Load bit mask into C
	AND C							Apply bit mask
	CP $02						Check IBF (bit 2 of PORT C)
	JP NZ,ECHO 			Nothing in buffer, keep checking
	IN A, (PORT_B)		Read PORT B to Accumulator
	CALL LCD_DISPLAY
	RET

LCD_COMMAND
	OUT (PORT_A), A
	LD A, $20
	OUT (PORT_C), A		Set E and reset RS to send data to command register
	XOR A							Zero out accumulator
	OUT (PORT_C), A
	RET

LCD_DISPLAY
	OUT (PORT_A), A
	LD A, $30
	OUT (PORT_C), A		Set E and RS to send data to data register
	XOR A							Zero out accumulator
	OUT (PORT_C), A
	RET

BIOS_MSG
	.DB "MARZ80 BIOS V1.0", $0A
