;---------------------------------------------------------------------------
;
;		MARZ80 BIOS
;
;---------------------------------------------------------------------------

	.CR	Z80						It's a Z80 assembler now
	.TF marzbios.bin, bin
	.OR	$0000

STACK_TOP	.EQ $FFFF	Stack pointer starting address
PORT_A		.EQ $00		8255 PORT A address - 16 x 2 LCD display
PORT_B		.EQ $01		8255 PORT B address - Arduino Nano PS/2 kybd controller
PORT_C		.EQ $02		8255 PORT C address - control port for PORT A & PORT B
PORT_CTL	.EQ	$03		8255 Control register address

COLD
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

SETUP
	LD A, $38
	OUT (PORT_A), A
	LD A, $20					Set E and reset RS
	OUT (PORT_C), A		Send E & RS to PORT C
	LD A, $00					Reset E & RS
	OUT (PORT_C), A		Send E & RS to PORT C

INIT
	LD A, $0F					Init display instruction
	OUT (PORT_A), A		Send instruction to PORT A
	LD A, $20					Set E and reset RS
	OUT (PORT_C), A		Send E & RS to PORT C
	LD A, $00					Reset E & RS
	OUT (PORT_C), A		Send E & RS to PORT C

CLEAR
	LD A, $01					Clear display instruction
	OUT (PORT_A), A		Send instruction to PORT A
	LD A, $20					Set E and reset RS
	OUT (PORT_C), A		Send E & RS to PORT C
	LD A, $00					Reset E & RS
	OUT (PORT_C), A		Send E & RS to PORT C

	LD HL, MSG				Set HL to the string start address
	LD A, (HL)

NXTCHR
	OUT (PORT_A), A		Send the current char to PORT A
	LD A, $30					Set both E and RS
	OUT (PORT_C), A		Display the character
	LD A, $00					Reset E & RS
	OUT (PORT_C), A		Send E & RS to PORT C
	INC HL
	LD A, (HL)
	CP $0A						Check for end of string
	JP NZ,NXTCHR

NEWLN
	LD A, $A8					Move cursor to the beginning of the 2nd line
	OUT (PORT_A), A		Send instruction to PORT A
	LD A, $20					Set E and reset RS
	OUT (PORT_C), A		Send E & RS to PORT C
	LD A, $00					Reset E & RS
	OUT (PORT_C), A		Send E & RS to PORT C

CURSOR
	LD A, $3E					Load cursor '>'
	OUT (PORT_A), A		Display cursor
	LD A, $30					Set both E and RS
	OUT (PORT_C), A		Display the character
	LD A, $00					Reset E & RS
	OUT (PORT_C), A		Send E & RS to PORT C

ECHO
	IN A, (PORT_C)		Read PORT C to Accumulator
	LD C, $02					Load bit mask into C
	AND C							Apply bit mask
	CP $02						Check IBF (bit 2 of PORT C)
	JP NZ,ECHO 			Nothing in buffer, keep checking
	IN A, (PORT_B)		Read PORT B to Accumulator
	OUT (PORT_A), A		Output keyboard input to PORT A
	LD A, $30					Set both E and RS
	OUT (PORT_C), A		Display the character
	LD A, $00					Reset E & RS
	OUT (PORT_C), A		Send E & RS to PORT C
	JP ECHO

END
	HALT

MSG
	.DB "MARZ80 BIOS V1.0", $0A
