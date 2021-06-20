	.LF /Users/ingoschmied/Documents/develop.nosync/assembly/marz80/marzbios.lst
;---------------------------------------------------------------------------
;
;	MARZBIOS
;
;---------------------------------------------------------------------------

	.CR	Z80				;It's a Z80 assembler now
	.TF /Users/ingoschmied/Documents/develop.nosync/assembly/marz80/marzbios.bin, bin
	.OR $0000

A_DAT		.EQ	$00		; PIO PORT A data
B_DAT 		.EQ	$01		; PIO PORT B data
A_CTL 		.EQ	$02		; PIO PORT A control
B_CTL 		.EQ	$03		; PIO PORT B control
LCD_INST	.EQ $00		; LCD RS = 0, register select data register
LCD_DATA	.EQ $01		; LCD RS = 1, register select instruction register
LCD_WR		.EQ $00		; LCD R/~W = 0, write to LCD
LCD_RD		.EQ $02		; LCD R/~W = 1, read from LCD
LCD_DISABLE	.EQ $00		; LCD E = 0, LCD disable I/O
LCD_ENABLE	.EQ $04		; LCD E = 1, LCD enable I/O
BSTB_ON		.EQ $00		; ~BSTB = 0, Strobe data into PORT A input register
BSTB_OFF	.EQ $08		; ~BSTB = 1, Ignore data at PORT A
ASTB_ON		.EQ $00		; ~ASTB = 0, Strobe data out of PORT A output register
ASTB_OFF	.EQ $10		; ~ASTB = 1, Disable PORT A output register?
STACK_TOP	.EQ	$FFFF

COLD_START:
	JP WARM_START

;	.OR $0008,$FF

BIOS_MSG:	
	.DB "MARZA BIOS V1.0", $0A

WARM_START:
	LD SP, STACK_TOP	; Initialize the stack pointer

;---------------------------------------------------------------------------
;	$0F Sets MODE 0: Output
;	$4F Sets MODE 1: Input
;	$8F Sets MODE 2: Bidirectional *
;	$CF Sets MODE 3: Control
;
;	* Only PORT A may be set to MODE 2, and the PORT B must be
;	  set to MODE 3
;---------------------------------------------------------------------------

	LD A, $8F			; Set PORT A to MODE 2: Bidirectional
	OUT (A_CTL), A
	LD A, $CF			; Set PORT B to MODE 3: Control
	OUT (B_CTL), A
	LD A, $00			; Since MODE 3 was selected, configure all pins 
	OUT (B_CTL), A		; as outputs

	LD A, $38			; Set LCD to 8 bit Mode, 2 lines, & 5x8 font
	CALL LCD_COMMAND
	LD A, $0F			; Init display instruction
	CALL LCD_COMMAND
	LD A, $01			; Clear display instruction
	CALL LCD_COMMAND

	LD HL, BIOS_MSG		; Set HL to the bios message start address
	LD A, (HL)
    
NEXT_CHAR:
	CALL LCD_DISPLAY
	INC HL
	LD A, (HL)
	CP $0A				; Check for end of string
	JP NZ,NEXT_CHAR

	LD A, $A8			; Move cursor to the beginning of the 2nd line
	CALL LCD_COMMAND
	LD A, $3E			; Load cursor '>'
	CALL LCD_DISPLAY
;	EI
	HALT

LCD_COMMAND:
	CALL LCD_READY
	OUT (A_DAT), A
	LD A, ASTB_ON|BSTB_OFF|LCD_ENABLE|LCD_WR|LCD_INST
	OUT (B_DAT), A
	LD A, ASTB_OFF|BSTB_OFF|LCD_DISABLE|LCD_WR|LCD_INST
	OUT (B_DAT), A
	RET

LCD_DISPLAY:
	CALL LCD_READY
	OUT (A_DAT), A		; Output the display data on PORT A
	LD A, ASTB_ON|BSTB_OFF|LCD_ENABLE|LCD_WR|LCD_DATA
	OUT (B_DAT), A		; Set E & RS to send data to the data register
	LD A, ASTB_OFF|BSTB_OFF|LCD_DISABLE|LCD_WR|LCD_INST
	OUT (B_DAT), A
	RET

LCD_READY:
	LD C, B_DAT
	LD B, ASTB_OFF|BSTB_ON|LCD_ENABLE|LCD_RD|LCD_INST
	OUT (C), B
	LD C, A_DAT
	IN D,(C)			; Read the PORT A input register
	LD C, B_DAT
	LD B, ASTB_OFF|BSTB_OFF|LCD_DISABLE|LCD_RD|LCD_INST
	OUT (C), B
	RL D				; Rotate bit 7 (LCD busy flag) into the carry flag
	JR C,LCD_READY		; If the LCD busy flag is set repeat the check
	RET