;Práctica1/CAD10bitsLcdUsart/JuanAndrésValverdeJara/24.03.2007
		list		p=16f871
		#include	<p16f871.inc>
		__config 	0x3d39
		errorlevel	-302
						;Config LCD Port's
LCD_Control	equ	PORTB	;LCDcontrol'-----,RW*,E,RS'*NoUsado;,
LCD_RS		equ	1		;Comando o dato		0/1
LCD_E		equ	2		;EnableLCD			0(off)/1(on)
LCD_Data	equ	PORTD	;LCDbus'd7,d6,d5,d4,d3,d2,d1,d0'

	CBLOCK  0x20
Counter1
Counter2

REG_W
REG_S

ADREL_A
UNIDAD
DECENA
CENTENA
MIL
COMP_H
COMP_L

RECEIVE
UNIDAD_R
DECENA_R
CENTENA_R
MIL_R
	ENDC

		org		0x00
		goto	START
		org		0x04		;Inicio Interrupt Guardo W y Status
		MOVWF 	REG_W 		;Guardo W en Reg_W
		SWAPF 	STATUS,W 	;invierto nibbles Status y paso a W
		MOVWF 	REG_S 		;Guardo  STATUS
							;Atiendo interrupción
		MOVF	RECEIVE,W
		XORLW	0x01		;¿RECEIVE es
		BTFSS	STATUS,Z	;			0x01?
		GOTO    RCIV_C		;NO:

		MOVF	RCREG,W		;SI:
		MOVWF	MIL_R
		INCF	RECEIVE,F
		GOTO    INT_FIN

RCIV_C	MOVF	RECEIVE,W
		XORLW	0x02		;¿RECEIVE es
		BTFSS	STATUS,Z	;			0x02?
		GOTO    RCIV_D		;NO:

		MOVF	RCREG,W		;SI:
		MOVWF	CENTENA_R
		INCF	RECEIVE,F
		GOTO    INT_FIN

RCIV_D	MOVF	RECEIVE,W	;NO
		XORLW	0x03		;¿RECEIVE es
		BTFSS	STATUS,Z	;			0x03?
		GOTO    RCIV_U		;NO:

		MOVF	RCREG,W		;SI:
		MOVWF	DECENA_R
		INCF	RECEIVE,F
		GOTO    INT_FIN

RCIV_U	MOVF	RECEIVE,W	;NO
		XORLW	0x04		;¿RECEIVE es
		BTFSS	STATUS,Z	;			0x04?
		GOTO    RCIV		;NO:

		MOVF	RCREG,W		;SI:
		MOVWF	UNIDAD_R
		CLRF	RECEIVE
		GOTO    INT_FIN

RCIV	MOVF	RCREG,W		;NO
		XORLW	"+"			;¿RCREG es
		BTFSS	STATUS,Z	;			+?
		GOTO    INT_FIN		;NO:

		INCF	RECEIVE,F	;SI:

INT_FIN						;End Interrupt Restauro W y Status
		BCF		PIR1,RCIF	;Clear Receive flag
		SWAPF 	REG_S,W 	;invierto nibbles REG_S y paso a W
		MOVWF 	STATUS		;Restauro Status
		SWAPF 	REG_W,F		;invierto nibbles de Reg_W
		SWAPF 	REG_W,W		;invierto y paso a w
		RETFIE

START	bsf 	STATUS,RP0	;Bank 1
		MOVLW	b'11111001'	;LCDcontrol
		MOVWF	TRISB
		MOVLW	B'10111111'	;Rx,Tx,------
		MOVWF	TRISC
		MOVLW	b'00000000'	;LCDbus
		MOVWF	TRISD

		BSF		INTCON,GIE	;Enable Global Interrupts
		BSF		INTCON,PEIE	;Enable Peripherial Interrupt
		BSF		PIE1,RCIE	;Enable USART Receive Interrupt

		MOVLW	b'00100000'	;--,TransmitEnable,-----
		MOVWF	TXSTA
		MOVLW	D'00'		;Baud Rate
		MOVWF	SPBRG

		MOVLW	b'10001110'	;justDER,---,1canalRA0 Vref=VddVss
		MOVWF 	ADCON1	
		bcf 	STATUS,RP0	;Bank 0

		MOVLW	B'10010000'	;SerialPort,--,ContinuosReceive
		MOVWF	RCSTA

		MOVLW	b'01000001'	;Fosc/8-,RA0--,NoConv,-,ActivadoCAD
		MOVWF 	ADCON0

		CLRF	RECEIVE

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

        MOVLW	"+"			;SI:Transmiter
        MOVWF	TXREG

VISUAL	call	LCDLine1	;Situa cursor en 1ª linea
		MOVF	MIL,W		;W=MIL
		MOVWF	TXREG	
		CALL	TABLA		;W=ASCII(MIL)
		CALL	LCDWrite
		MOVLW	","			;W=ASCII(,)
		CALL	LCDWrite
		MOVF	CENTENA,W	;W=CENTENA
		MOVWF	TXREG
		CALL	TABLA		;W=ASCII(CENTENA)
		CALL	LCDWrite
		MOVF	DECENA,W	;W=DECENA
		MOVWF	TXREG
		CALL	TABLA		;W=ASCII(DECENA)
		CALL	LCDWrite
		MOVF	UNIDAD,W	;W=UNIDAD
		MOVWF	TXREG
		CALL	TABLA		;W=ASCII(UNIDAD)
		CALL	LCDWrite
		MOVLW	"V"			;W=ASCII(V)
		CALL	LCDWrite

		call	LCDLine2	;Situa cursor en 2ª linea
		MOVF	MIL_R,W		;W=MIL
		CALL	TABLA		;W=ASCII(MIL)
		CALL	LCDWrite
		MOVLW	","			;W=ASCII(,)
		CALL	LCDWrite
		MOVF	CENTENA_R,W	;W=CENTENA
		CALL	TABLA		;W=ASCII(CENTENA)
		CALL	LCDWrite
		MOVF	DECENA_R,W	;W=DECENA
		CALL	TABLA		;W=ASCII(DECENA)
		CALL	LCDWrite
		MOVF	UNIDAD_R,W	;W=UNIDAD
		CALL	TABLA		;W=ASCII(UNIDAD)
		CALL	LCDWrite
		MOVLW	"V"			;W=ASCII(V)
		CALL	LCDWrite

		GOTO	AD_CON

TABLA	ADDWF	PCL,1
		DT		"0123456789"

INCR	INCF	COMP_L,F	;
		MOVF	COMP_L,W	;¿COMP_L
		XORLW	0x00		;		es 
		BTFSC	STATUS,Z	;			0?
		INCF	COMP_H,F	;SI:

		MOVLW	0x05		;NO: Incrementa UNIDAD
		ADDWF	UNIDAD,F	;				de 5 en 5
		MOVF	UNIDAD,W	;
		XORLW	0x0A		;¿UNIDAD es 
		BTFSS	STATUS,Z	;			10?
		GOTO    COMPAR		;NO:

		CLRF	UNIDAD		;SI:
		INCF	DECENA,F	;
		MOVF	DECENA,W	;
		XORLW	0x0A		;¿DECENA es 
		BTFSS	STATUS,Z	;			10?
		GOTO    COMPAR		;NO

		CLRF	DECENA		;SI
		INCF	CENTENA,F
		MOVF	CENTENA,W
		XORLW	0x0A		;¿CENTENA es 
		BTFSS	STATUS,Z	;			10?
		GOTO    COMPAR		;NO

		CLRF	CENTENA		;SI
		INCF	MIL,F
		GOTO    COMPAR

		include "LCDsoft.asm"
		END
