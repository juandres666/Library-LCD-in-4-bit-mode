;ADC8bitsLcd4bits/JuanAndrésValverdeJara/18.06.2007
		list		p=16F871
		#include	<p16f871.inc>
		__config 	0x3d39
		errorlevel	-302
						;Config LCD Port's
LCD_Control	equ	PORTD	;LCDcontrol'-----,RW*,E,RS'*NoUsado;,
LCD_RS		equ	2		;Comando o dato		0/1
LCD_E		equ	3		;EnableLCD			0(off)/1(on)
LCD_Data	equ	PORTD	;LCDbus'd7,d6,d5,d4,d3,d2,d1,d0'

	CBLOCK  0x20
Counter1
Counter2
LCDdato

DECENA
CENTENA
MIL
CONT
CONT1
COMPARA
	ENDC

		org		0x00
		bsf 	STATUS,RP0
		MOVLW	B'10111111'	;Rx,Tx,------
		MOVWF	TRISC
		MOVLW	b'00000011'	;LCDbus&LCDcontrol
		MOVWF	TRISD

		MOVLW	b'00001110'	;justIZQ,---,1canalRA0 Vref=VddVss
		MOVWF 	ADCON1

		MOVLW	D'12'		;Baud Rate
		MOVWF	SPBRG
		MOVLW	b'00100100'	;--,TransmitEnable,-----
		MOVWF	TXSTA
		bcf 	STATUS,RP0

		MOVLW	b'01000001'	;Fosc/8-,RA0--,NoConv,-,ActivadoCAD
		MOVWF 	ADCON0		;
		MOVLW	B'10000000'	;SerialPort,-
		MOVWF	RCSTA

		call 	LCDReset	;Inicia LCD
		call   	CursorOff	;Sin Cursor

START	bsf 	ADCON0,2	;Comienza conversión
		CLRF	DECENA		;borrando registro
		CLRF	CENTENA		;borrando registro
		CLRF	MIL			;borrando registro
		CLRF	COMPARA		;borrando registro
STOP 	btfsc	ADCON0,2 	;ver si acaba de convertir
		goto 	STOP

		movf 	ADRESH,0	;SI: ¿Es
		MOVWF	TXREG		;envia dato uat

COMPAR	movf 	ADRESH,0	;SI: ¿Es
		MOVWF	TXREG		;envia dato uat
		XORWF	COMPARA,0	;		ADRESH
		BTFSS	STATUS,Z	;			= COMPARA?
        GOTO	INCR		;NO
		CALL 	VISUAL		;SI
		Goto	START

VISUAL	call	LCDLine1	;Situa cursor en 1ª linea
		MOVF	MIL,W		;W=MIL
		CALL	TABLA		;W=ASCII(MIL)
		CALL	LCDWrite
		MOVLW	","			;W=ASCII(,)
		CALL	LCDWrite
		MOVF	CENTENA,W	;W=CENTENA
		CALL	TABLA		;W=ASCII(CENTENA)
		CALL	LCDWrite
		MOVF	DECENA,W	;W=DECENA
		CALL	TABLA		;W=ASCII(DECENA)
		CALL	LCDWrite
		MOVLW	"V"			;W=ASCII(V)
		CALL	LCDWrite
		GOTO	START

TABLA	ADDWF	PCL,1
		DT		"0123456789"

INCR	INCF	COMPARA,1	;incremento COMPARA ahi mismo
		INCF	DECENA,1	;incremento decena ahi mismo
		INCF	DECENA,1	;incremento decena ahi mismo
		MOVF	DECENA,0	;muevo decena a w
		XORLW	0x0A		;hago xor entre 10 Y w
		BTFSS	STATUS,Z	;veo que tiene el Z del status
		GOTO    COMPAR

		CLRF	DECENA
		INCF	CENTENA,1
		MOVF	CENTENA,0
		XORLW	0x0A
		BTFSS	STATUS,Z
		GOTO    COMPAR

		CLRF	CENTENA
		INCF	MIL,1
		GOTO    COMPAR

		include "LCDsoft4bits.asm"
		END
