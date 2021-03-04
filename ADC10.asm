;ADC10bitsLcd4bits/JuanAndrésValverdeJara/18.06.2007
		list		p=16f871
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

ADREL_A
UNIDAD
DECENA
CENTENA
MIL
COMP_H
COMP_L
	ENDC

		org		0x00
		bsf 	STATUS,RP0	;Bank 1
		MOVLW	b'00000011'	;LCDbus&LCDcontrol
		MOVWF	TRISD

		MOVLW	b'10001110'	;justDER,---,1canalRA0 Vref=VddVss
		MOVWF 	ADCON1
		bcf 	STATUS,RP0	;Bank 0

		MOVLW	b'01000001'	;Fosc/8-,RA0--,NoConv,-,ActivadoCAD
		MOVWF 	ADCON0

		call 	LCDReset	;Inicia LCD
		call   	CursorOff	;Sin Cursor

AD_CON	bsf 	ADCON0,GO	;Comienza conversión
STOP 	btfsc	ADCON0,GO 	;¿acaba de convertir?
		goto 	STOP		;NO:

		bsf 	STATUS,RP0
		movf	ADRESL,W	;ADRESL en banco1
		bcf 	STATUS,RP0
		movwf	ADREL_A

		CLRF	UNIDAD		;borrando registro
		CLRF	DECENA		;borrando registro
		CLRF	CENTENA		;borrando registro
		CLRF	MIL			;borrando registro
		CLRF	COMP_H		;borrando registro
		CLRF	COMP_L		;borrando registro

COMPAR	movf 	ADREL_A,W	;SI: ¿Es
		XORWF	COMP_L,W	;		ADRESL
		BTFSS	STATUS,Z	;			= COMP_L?
        GOTO	INCR		;NO
		movf 	ADRESH,W	;SI: ¿Es
		XORWF	COMP_H,W	;		ADRESH
		BTFSS	STATUS,Z	;			= COMP_H?
        GOTO	INCR		;NO

VISUAL	call	LCDLine1	;SI:Situa cursor en 1ª linea
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
		MOVF	UNIDAD,W	;W=UNIDAD
		CALL	TABLA		;W=ASCII(UNIDAD)
		CALL	LCDWrite
		MOVLW	"V"			;W=ASCII(V)
		CALL	LCDWrite

		GOTO	AD_CON

TABLA	ADDWF	PCL,1
		DT		"0123456789"

INCR	INCF	COMP_L,1	;
		MOVF	COMP_L,0	;¿COMP_L
		XORLW	0x00		;		es 
		BTFSC	STATUS,Z	;			0?
		INCF	COMP_H,1	;SI:

		MOVLW	0x05		;NO: Incrementa UNIDAD
		ADDWF	UNIDAD,1	;				de 5 en 5
		MOVF	UNIDAD,0	;
		XORLW	0x0A		;¿UNIDAD es 
		BTFSS	STATUS,Z	;			10?
		GOTO    COMPAR		;NO:

		CLRF	UNIDAD		;SI:
		INCF	DECENA,1	;
		MOVF	DECENA,0	;
		XORLW	0x0A		;¿DECENA es 
		BTFSS	STATUS,Z	;			10?
		GOTO    COMPAR		;NO

		CLRF	DECENA		;SI
		INCF	CENTENA,1
		MOVF	CENTENA,0
		XORLW	0x0A		;¿CENTENA es 
		BTFSS	STATUS,Z	;			10?
		GOTO    COMPAR		;NO

		CLRF	CENTENA		;SI
		INCF	MIL,1
		GOTO    COMPAR

		include "LCDsoft4bits.asm"
		END
