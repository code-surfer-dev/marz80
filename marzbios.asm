;---------------------------------------------------------------------------
;
;		MARZ80 BIOS
;
;---------------------------------------------------------------------------

	.CR	Z80				It's a Z80 assembler now
	.TF marzbios.rom, bin
	.OR	$0000

STACK	.EQ $FFFF			Stack pointer starting address
COLD
	LD SP, STACK	Initialize the stack pointer

;---------------------------------------------------------------------------
;		$86 Sets the 8255 GROUP A to MODE 0: PORT A & PORT C Upper to OUTPUTS
;		GROUP B to MODE 1: PORT B INPUT, C Lower to STROBE
;---------------------------------------------------------------------------

	LD A, $86
	OUT ($03), A	Send the control word to the 8255 Control Register

;---------------------------------------------------------------------------
;		$38 Sets the 16x2 Display to 8 bit Mode, 2 lines, & 5x8 font size
;		The display is connected to PORT A of the 8255
;---------------------------------------------------------------------------

SETUP
	LD A, $38
	OUT ($00), A
	LD A, $20			Set E and reset RS
	OUT ($02), A	Send E & RS to PORT C
	LD A, $00			Reset E & RS
	OUT ($02), A	Send E & RS to PORT C

INIT
	LD A, $0F			Init display instruction
	OUT ($00), A	Send instruction to PORT A
	LD A, $20			Set E and reset RS
	OUT ($02), A	Send E & RS to PORT C
	LD A, $00			Reset E & RS
	OUT ($02), A	Send E & RS to PORT C

CLEAR
	LD A, $01			Clear display instruction
	OUT ($00), A	Send instruction to PORT A
	LD A, $20			Set E and reset RS
	OUT ($02), A	Send E & RS to PORT C
	LD A, $00			Reset E & RS
	OUT ($02), A	Send E & RS to PORT C

	LD HL, MSG		Set hl to the string start address
	LD A, (HL)

NXTCHR
	OUT ($00), A	Send the current char to PORT A
	LD A, $30			Set both E and RS
	OUT ($02), A	Display the character
	LD A, $00			Reset E & RS
	OUT ($02), A	Send E & RS to PORT C
	INC HL
	LD A, (HL)
	CP $0A				Check for end of string
	JP NZ,NXTCHR

NEWLN
	LD A, $A8			Move cursor to the beginning of the 2nd line
	OUT ($00), A	Send instruction to PORT A
	LD A, $20			Set E and reset RS
	OUT ($02), A	Send E & RS to PORT C
	LD A, $00			Reset E & RS
	OUT ($02), A	Send E & RS to PORT C

CURSOR
	LD A, $3E			Load cursor '>'
	OUT ($00), A	Display cursor
	LD A, $30			Set both E and RS
	OUT ($02), A	Display the character
	LD A, $00			Reset E & RS
	OUT ($02), A	Send E & RS to PORT C

ECHO
	IN A, ($02)		Read PORT C to Accumulator
	LD C, $02			Load bit mask into C
	AND C					Apply bit mask
	CP $02				Check IBF (bit 2 of PORT C)
	JP NZ,ECHO 		Nothing in buffer, keep checking
	IN A, ($01)		Read PORT B to Accumulator
	OUT ($00), A	Output keyboard input to PORT A
	LD A, $30			Set both E and RS
	OUT ($02), A	Display the character
	LD A, $00			Reset E & RS
	OUT ($02), A	Send E & RS to PORT C
	JP ECHO

END
	HALT

MSG
	.DB "MARZA80 O/S V1.0", $0A
