;; Fiat Lancia Tester test program by trwgQ26xxx, 2025

PORT1_DDR		equ $0000
PORT2_DDR		equ $0001
PORT1_OUT		equ $0002
PORT2_OUT		equ $0003

KEYB_DATA_OUT	equ	$0080
IN_LATCH_STATUS equ	$0081
ROW_TO_SCAN		equ $0082
COL_TO_SCAN		equ $0083

RAM_CHECK_VAL	equ	$0084
RAM_ORI_VAL		equ	$0085

INPUT_LATCH		equ	$1000
LCD_COMMAND		equ	$2000
LCD_DATA		equ	$2001
OUT_LATCH		equ	$3000
RAM_TEST_ADDR	equ $4000

	processor HD6303

	;fill lower 32k
	org $0000
	dc.w #$FFFF

	;use upper 32k
	org $8000
main subroutine

	;Locate stack at top of internal RAM
	lds #$00FF

	ldaa #$8D
	staa PORT1_OUT

	;Set P1.0 - P1.7 as outputs
	ldaa #$FF
	staa PORT1_DDR

	ldaa #$00
	staa OUT_LATCH
	jsr delay
	
	;Init display
	ldaa #$38
	staa LCD_COMMAND
	jsr small_delay
	
	ldaa #$38
	staa LCD_COMMAND
	jsr small_delay
	
	ldaa #$38
	staa LCD_COMMAND
	jsr small_delay
	
	ldaa #$38
	staa LCD_COMMAND
	jsr small_delay
	
	ldaa #$0C
	staa LCD_COMMAND
	jsr small_delay
	
	ldaa #$01	;clear display
	staa LCD_COMMAND
	jsr delay
	
	ldaa #$06	;entry mode set
	staa LCD_COMMAND
	jsr small_delay
	
	ldaa #$80	;set addr to 1st line
	staa LCD_COMMAND
	jsr small_delay
	
	ldx #welc_message
	jsr print

; RAM test

	ldaa #$C0	;set addr to 2nd line
	staa LCD_COMMAND
	jsr small_delay
	
	;Perform RAM test
	ldaa RAM_TEST_ADDR		;Load and store original value
	staa RAM_ORI_VAL
	coma					;Calculate complement
	staa RAM_TEST_ADDR
	staa RAM_CHECK_VAL		;Store complement
			
	ldaa RAM_TEST_ADDR		;Read again and check if it is complement
	cmpa RAM_CHECK_VAL
	beq .bat_is_OK			;It is, so battery is OK
	
	ldx #ram_fail_msg		;It is not, first write was blocked, so battery is low
	bra .print_battery_test_result
	
.bat_is_OK
	ldx #ram_ok_msg

.print_battery_test_result
	ldaa RAM_ORI_VAL		;Restore original value
	staa RAM_TEST_ADDR

	jsr print				;Print result
	
; HW revision check
	
	ldaa #$90	;set addr to 3rd line
	staa LCD_COMMAND
	jsr small_delay
	
	ldab INPUT_LATCH
	
	andb #$C0	;mask other bits, keep D7 & D6
	
	lsrb
	lsrb
	lsrb
	lsrb
	lsrb
	lsrb		;shift bits 6 times
	
	clc			;clear carry
	
	;so now D1-D0 is D7-D6
	
	;Pick correct key string
	ldx #hw_cfg_msg_list
	abx
	abx			;add two times, as pointer is 16bit
	ldd 0,x	
	xgdx

	;Put key string
	jsr print

	jsr delay

; KEYBOARD test

.progstart
	
	;Start KBD scan
	ldaa #$10
	staa ROW_TO_SCAN
	
	ldab #$00
	
.row_scan_start
	
	;Set row to scan
	ldaa PORT1_OUT
	anda #$0F
	oraa ROW_TO_SCAN
	staa PORT1_OUT
	
	stab KEYB_DATA_OUT
	
	;Wait
	jsr small_delay
	
	ldab KEYB_DATA_OUT
	
	ldaa INPUT_LATCH
	staa IN_LATCH_STATUS
	
	;Set column to scan
	ldaa #$01
	staa COL_TO_SCAN
	
.col_scan_start
	
	ldaa IN_LATCH_STATUS
	anda COL_TO_SCAN
	bne .row_scan_end
	incb
	
	ldaa COL_TO_SCAN
	asla
	cmpa #$20
	beq .col_scan_end
	
	staa COL_TO_SCAN
	bra .col_scan_start
	
.col_scan_end
	
	ldaa ROW_TO_SCAN
	asla
	beq .row_scan_end
	
	staa ROW_TO_SCAN
	bra .row_scan_start
	
.row_scan_end

	;Disable KBD outputs
	ldaa PORT1_OUT
	anda #$0F
	staa PORT1_OUT

	;Store result
	stab KEYB_DATA_OUT

	ldaa #$D0	;set addr to 4rd line
	staa LCD_COMMAND
	jsr small_delay
	
	ldab KEYB_DATA_OUT
	
	;Pick correct key string
	ldx #key_msg_list
	abx
	abx
	ldd 0,x	
	xgdx

	;Put key string
	jsr print

	jsr delay

	jmp .progstart

print subroutine
.printstart
	ldaa 0,x
	cmpa #$00
	beq .printend
	staa LCD_DATA
	jsr small_delay
	inx
	jmp .printstart
.printend
	rts

delay subroutine
	ldaa #$00
.1
		ldab #$00
.2
		nop
		incb
		cmpb #$FF
		bne .2
	inca
	cmpa #$7f
	bne .1
	rts
	
small_delay subroutine
	ldaa #$00
.1
		ldab #$00
.2
		nop
		incb
		cmpb #$FF
		bne .2
	inca
	cmpa #$03
	bne .1
	rts

welc_message	dc "trwgQ26xxx, 2025", 0

ram_ok_msg		dc "RAM batt. is OK!", 0
ram_fail_msg	dc "RAM batt. is low", 0

hw_cfg_0_msg	dc "HW config.   0x0", 0
hw_cfg_1_msg	dc "HW config.   0x1", 0
hw_cfg_2_msg	dc "HW config.   0x2", 0
hw_cfg_3_msg	dc "HW config.   0x3", 0

no_key_msg		dc " PRESS ANY KEY! ", 0

r_key_msg		dc "RST KEY PRESSED!", 0
one_key_msg		dc "  1 KEY PRESSED!", 0
five_key_msg	dc "  5 KEY PRESSED!", 0
fc_key_msg		dc " FC KEY PRESSED!", 0
ok_key_msg		dc " OK KEY PRESSED!", 0

qm_key_msg		dc "  ? KEY PRESSED ", 0
two_key_msg		dc "  2 KEY PRESSED!", 0
six_key_msg		dc "  6 KEY PRESSED!", 0
nine_key_msg	dc "  9 KEY PRESSED!", 0
nok_key_msg		dc "NOK KEY PRESSED!", 0

m_key_msg		dc "  M KEY PRESSED!", 0
three_key_msg	dc "  3 KEY PRESSED!", 0
seven_key_msg	dc "  7 KEY PRESSED!", 0
zero_key_msg	dc "  0 KEY PRESSED!", 0
up_key_msg		dc " UP KEY PRESSED!", 0

es_key_msg		dc "E/S KEY PRESSED!", 0
four_key_msg	dc "  4 KEY PRESSED!", 0
eight_key_msg	dc "  8 KEY PRESSED!", 0
retry_key_msg	dc "RETRY KEY PRES.!", 0
down_key_msg	dc "DOWN KEY PRESS.!", 0

hw_cfg_msg_list	dc.w hw_cfg_0_msg,	hw_cfg_1_msg,	hw_cfg_2_msg,	hw_cfg_3_msg

key_msg_list	dc.w r_key_msg,		one_key_msg,	five_key_msg,	fc_key_msg,		ok_key_msg	;COLUMN 1
				dc.w qm_key_msg,	two_key_msg,	six_key_msg,	nine_key_msg,	nok_key_msg	;COLUMN 2
				dc.w m_key_msg,		three_key_msg,	seven_key_msg,	zero_key_msg,	up_key_msg	;COLUMN 3
				dc.w es_key_msg,	four_key_msg,	eight_key_msg,	retry_key_msg,	down_key_msg;COLUMN 4
				dc.w no_key_msg

	;reset vector
	org $FFFE
	dc.w #main
