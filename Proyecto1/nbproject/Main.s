; Archivo: Proyecto1.s
; Dispositivo: PIC16F887
; Autor: Diego Mendez
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: Utilizando Interrupts, un contadores decimales y luces
; Hardware: Push buttons puerto B, 2Displays y Leds
;
; Creado: 22 feb, 2021
; �ltima modificaci�n: 22 feb, 2021

PROCESSOR 16F887
#include<xc.inc>
;------------------------- CONFIGURATION WORDS----------------------------------

    ; config 1
	CONFIG FOSC=INTRC_NOCLKOUT  //Oscilador interno sin salida en puerto
	CONFIG WDTE=OFF	 // WDT disabled (reinicio repetitivo del PIC)
	CONFIG PWRTE=ON	 // PWRTE enabled  ESPERA 72MS AL INICIAR
	CONFIG MCLRE=OFF	 // El pin de MCLR se utiliza como I/O
	CONFIG CP=OFF	 // Sin proteccion de codigo
	CONFIG CPD=OFF	 // Sin proteccion de datos

	CONFIG BOREN=OFF	 // Sin reinicio cuando el voltaje es menor a 4V
	CONFIG IESO=OFF	 // Reinicio sin cambio de reloj de interno a externo
	CONFIG FCMEN=OFF // Cambio del reloj externo a interno en caso de falla
	CONFIG LVP=ON	// Programacion en bajo voltaje permitida

    ; configuration word 2
	CONFIG WRT=OFF	//Autoescritura off
	CONFIG BOR4V=BOR40V //Reinicio debajo de 4V

;------------------------------VARIABLES---------------------------------------
	PSECT udata_bank0 ;bank0

	selec_disp: DS 1; 1 byte    Completa
	W_Temp:	    DS 1; 1 byte
	STAT_Temp:  DS 1; 1 byte

	flagint:     DS 1; 1 byte    6 y 7 libre
	flagmode:    DS 1; 1 byte    4 para arriba libre
	flag:	     DS 1; 1 byte    7 libre
	flagnum:     DS 1; 1 byte    usada completa

	selector:    DS 1; 1 byte
        condisp:     DS 2; 2 bytes
	condisp1:    DS 2; 2 bytes
	condisp2:    DS 2; 2 bytes
	condisp3:    DS 2; 2 bytes
	condisp4:    DS 2; 2 bytes

        decenas:     DS 1; 1 byte
	decenas1:    DS 1; 1 byte
	decenas2:    DS 1; 1 byte
	decenas3:    DS 1; 1 byte
	decenas4:    DS 1; 1 byte

        unidades:    DS 1; 1 byte
	unidades1:   DS 1; 1 byte
	unidades2:   DS 1; 1 byte
	unidades3:   DS 1; 1 byte
	unidades4:   DS 1; 1 byte

	valorsemaf1: DS 1; 1 byte
	valorsemaf2: DS 1; 1 byte
	valorsemaf3: DS 1; 1 byte

	semaf1temp: DS 1; 1 byte
	semaf2temp: DS 1; 1 byte
	semaf3temp: DS 1; 1 byte

	flash:	    DS 1; 1 byte
	twofive:	    DS 1; 1 byte
	semaforo1:  DS 1; 1 byte
	semaforo2:  DS 1; 1 byte
	semaforo3:  DS 1; 1 byte
	oneseg:	    DS 1; 1 byte
	tempt:	    DS 1; 1 byte
	valor:	    DS 1; 1 byte
	threeseg:   DS 1; 1 byte

    GLOBAL flagint, condisp1, selec_disp, W_Temp, STAT_Temp
    GLOBAL decenas1, unidades1, condisp4, flash, flagnum, semaforo1, semaforo2




;---------------------------VECTOR RESET--------------------------------------
   PSECT resVect, class=CODE, abs, delta=2
    ORG 00h	;posicion 0000h para el reset
   resetVec:
	PAGESEL main
	goto main

;---------------------------VECTOR INTERRUPT------------------------------------
  ;Vector para la interrupci�n
   ORG 004h
   PUSH:
	BCF	INTCON, 7   ;Apagar el General Interrupt
	MOVWF	W_Temp	    ;Guardar lo que se encuentra en w
	SWAPF	STATUS, W   ;Guardar STATUS a W sin usar MOVF
	MOVWF	STAT_Temp   ;Guardar STATUS flippeado en temporal
   ISR:

	BTFSC	INTCON, 0   ;Revisar si existe cambio en b
	call	pushbt
	BTFSC	INTCON, 2   ;Revisar si la interrupcion fue por el timer overflow
	call	timer0flag
	BTFSC	PIR1, 0
	call	timer1flag
	BTFSC	PIR1, 1
	call	timer2flag

   POP:
	SWAPF	STAT_Temp, W ;Guardar STATUS original en W
	MOVWF	STATUS	    ;Regresamos el STATUS original a su variable
	SWAPF	W_Temp,F    ;Le damos vuelta a los nibbles de WTemp
	SWAPF	W_Temp,W    ;Regresamos al orden original y guardamos en W
	RETFIE		    ;Regreso de la Interrupcion y volvemos a activar GIE

;------------------------- SUBRUTINAS INTERRUPT -------------------------------
   pushbt:
    btfss   PORTB, 0	;Verificar si el RB0 esta presionado
    BSF	    flagint, 0
    btfss   PORTB, 1	;Verfiicar si el RB1 esta presionado
    BSF	    flagint, 1
    btfss   PORTB, 2	;Verfiicar si el RB1 esta presionado
    BSF	    flagint, 2
    bcf	    INTCON,0	;Limpiar bandera RBIF
    RETURN

   timer1flag:
    call    Ntimer1
    DECFSZ  oneseg	;Decrementar el contador para que sea un segundo
    RETURN
    MOVLW   10
    MOVWF   oneseg	;Ingresar el valor 10
    BSF	    flagint, 3	;Encender bandera externa
    RETURN

   timer2flag:
    banksel  PIR1
    BCF	     PIR1, 1
    DECFSZ  twofive	; Contamos 10 para que sea 10 x 25 asi 250ms
    RETURN
    MOVLW   10
    MOVWF   twofive	;Ingresar el valor 10
    BSF	    flagint, 5	;Encender bandera externa
    RETURN

   timer0flag:
    BSF	    flagint, 4	;Encender una bandera externa
    call    Ntimer0	;Reiniciar el timer0
    clrf    PORTD	;Limpiar el selector de pantalla
    btfsc   selec_disp, 0   ;Ver si la display pasada fue la 4
	goto    display1
    btfsc   selec_disp, 1   ;Ver si la display pasado fue la 1
	goto    display2
    btfsc   selec_disp, 2   ;Ver si el display anterior fue la 2
	goto    display3
    btfsc   selec_disp, 3   ;Ver si el display anterior fue la 3
	goto    display4
    btfsc   selec_disp, 4   ;Ver si el display anterior fue la 4
	goto    display5
    btfsc   selec_disp, 5   ;Ver si el display anterior fue la 5
	goto    display6
    btfsc   selec_disp, 6   ;Ver si el display anterior fue la 4
	goto    display7

   display0:
    BSF   selec_disp, 0		    ;Proximo interrupt ir a display1
    BTFSC   flag,3	    ;Control para titiliteo
    RETURN
    MOVF    condisp1, W	    ;Mover el valor de la variable al PORT
    MOVWF   PORTC
    BSF	    PORTD,0	    ;Encender el display 0
    RETURN

   display1:
    BCF	    selec_disp, 0   ;Limpiar bandera de display 1
    BSF	    selec_disp, 1		   ;Proximo interrupt ir a display2
    BTFSC   flag,3	    ;Control para titiliteo
    RETURN
    MOVF    condisp1+1, W    ;Mover el valor de la variable al port
    MOVWF   PORTC
    BSF	    PORTD,1	    ;Encender el display 1
    RETURN

   display2:
    BSF	    selec_disp, 2   ;Proximo display sea 3
    BCF	    selec_disp, 1   ;Limpiar bandera de display 2
    BTFSC   flag,4	    ;Control para titiliteo
    RETURN
    MOVF    condisp2,W	   ;Mover el valor de centenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 2	    ;Encender el display 2
    RETURN

   display3:
    BCF	    selec_disp, 2   ;Limpiar bandera de display 3
    BSF	    selec_disp,	3   ;Proximo display sea el 4
    BTFSC   flag,4	    ;Control para titiliteo
    RETURN
    MOVF    condisp2+1,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 3	    ;Encender el display 3
    RETURN

   display4:
    BSF	    selec_disp,	4   ;Proximo display sea el 5
    BCF	    selec_disp, 3   ;Limpiar bandera de display 3
    BTFSC   flag,5	    ;Control para titiliteo
    RETURN
    MOVF    condisp3,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 4	    ;Encender el display 4
    RETURN

   display5:
    BCF	    selec_disp, 4   ;Limpiar bandera de display 4
    BSF	    selec_disp,	5   ;Proximo display sea el 6
    BTFSC   flag,5	    ;Control para titiliteo
    RETURN
    MOVF    condisp3+1,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 5	    ;Encender el display 5
    RETURN

   display6:
    BCF	    selec_disp, 5   ;Limpiar bandera de display 5
    BSF	    selec_disp,	6   ;Proximo display sea el 7
    BTFSC   flag,6	    ;Control para titiliteo
    RETURN
    MOVF    condisp4,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 6	    ;Encender el display 6
    RETURN

   display7:
    clrf    selec_disp
    BTFSC   flag,6	    ;Control para titiliteo
    RETURN
    MOVF    condisp4+1,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 7	    ;Encender el display 7
    RETURN


   Ntimer0:
	banksel TMR0		;Buscar timer 0 en el banco
	MOVLW   6		;Cargar el valor de N  a W
	MOVWF   TMR0		;Cargar el valor de W a Timer0
	BCF	INTCON, 2	;Limpiar bandera de INTCON
	RETURN

   Ntimer1:		    ;Timer a 100ms
	banksel	TMR1L	    ;Seleccionar Banco
	MOVLW	0xB0	    ;Total HIgh y Low 15536
	MOVWF	TMR1L	    ;Meter en TMR1Low
	MOVLW	0x3C
	MOVWF	TMR1H	    ;Meter es TMR1High
	BCF	PIR1, 0	    ;Apagar bandera del interrupt
	RETURN
 ;----------------------------------TABLA----------------------------------------
   PSECT code, delta=2, abs
   ORG 100h ; posicion para el codigo
    table0:
	clrf PCLATH
	bsf  PCLATH,0	;Ubicar el PCLATH para que PC este en 100h
	ANDLW 0x0f	;Para que no sume mas de 15
	ADDWF PCL, 1
	RETLW 00111111B ;0
	RETLW 00000110B ;1
	RETLW 01011011B ;2
	RETLW 01001111B ;3
	RETLW 01100110B ;4
	RETLW 01101101B ;5
	RETLW 01111101B ;6
	RETLW 00000111B	;7
	RETLW 01111111B ;8
	RETLW 01100111B	;9
	RETLW 01110111B ;A
	RETLW 01111100B	;b
	RETLW 00111001B ;C
	RETLW 01011110B ;d
	RETLW 01111001B ;E
	RETLW 01110001B ;F
;----------------------------------CONFIGURACION--------------------------------
    main:
	banksel ANSEL
	clrf	ANSEL	;Configurar los puertos como digitales
	clrf	ANSELH

	banksel	TRISA	;Buscar banco del TRIS
	MOVLW 00000000B ;Designar valor de W a los puertos que deseo como inputs
	MOVWF	TRISA	;Mover el valor de W al TRISA
	MOVLW 00000111B
	MOVWF	TRISB
	clrf	TRISC	;Configurar puerto C
	clrf	TRISD	;Configurar puerto D
	clrf	TRISE

	bsf	OSCCON,0    ; El reloj interno utiliza el oscilador interno

	BSF INTCON, 7	;Activar global Int
	BSF INTCON, 6   ;Activar el external Interrupt para Timer 1
	BSF INTCON, 5	;Timer0 INt
	BSF INTCON, 3	;PORTB int


	banksel	PORTA	;Moverme al banco de los PORTS
	clrf	PORTA	;Colocar pines de A en 0
	clrf	PORTC	;Colocar pines de C en 0
	clrf	PORTD	;Colocar pines de D en 0
	clrf	PORTE	;Colocar pines de E en 0

	;T1CON y T2CON se encuentra en el mismo banco que los ports
	bsf	T1CON, 4    ;Colocar el prescaler de timer1 a 1:2
	bsf	T1CON, 0    ;Encender el timer 1
	MOVLW   00110110B   ;Configurar 1:16 Pre y 1:7 Post
	MOVWF	T2CON


	banksel OPTION_REG  ;Configurar Enable
	bsf	PIE1, 0	    ;Activar el Interrupt del Timer 1
	bsf	PIE1, 1	    ;Activar Interrupt Timer 2
	MOVLW	223	    ;Valor para el comparator
	MOVWF	PR2


	CLRWDT		    ;Limpiar WDT
	MOVLW	01000011B   ;Poner el prescaler en 1:16, activar el WeakPullup
	MOVWF	OPTION_REG  ;y WDT en timer0



	;Weak PULLUP y IOCB se encuentran en el mismo banco que option_reg
	MOVLW	00000111B   ;Configurar b0, b1 y b2 para que tengan weak pullup
	MOVWF	WPUB
	MOVWF	IOCB    ;Configurar b0 y b1 para que funcione int-on-change



	banksel PORTA
	MOVLW 00111111B	  ;Darle un valor al puerto D
	MOVWF PORTD
	MOVWF PORTC
	clrf  PORTB
	clrf  flagnum
	clrf  flag
	clrf  flash
	;valores iniciales de algunas variables
	MOVLW 10
	MOVWF oneseg
	MOVWF twofive
	MOVWF tempt
	MOVLW	3
	MOVWF threeseg


;--------------------------------LOOP-------------------------------------------
    loop:

	BTFSC flagint, 0
	call  modeselector
	call  modeselect


	BTFSC	flagmode, 0
	CALL  mode0
	BTFSC	flagmode, 1
	CALL  mode1
	BTFSC	flagmode, 2
	CALL  mode2
	BTFSC	flagmode, 3
	CALL  mode3
	BTFSC	flagmode, 4
	CALL  mode4

	CALL  decimales
	CALL  disp_refresh	;preparar para un refresh

	goto  loop

;---------------------------------SUBRUTINA-------------------------------------
    modeselector:
	BCF	flagint, 0	;Apagar bander de boton mode
	BCF	flagint, 2
	BCF	flag, 7		;Modificar bandera de pantalla 4
	incf	selector
	MOVF	selector, W
	XORLW	5
	BTFSC	STATUS, 2   ;Ver si paso de 4
	clrf	selector
	RETURN

    modeselect:
	clrf	flagmode
	MOVF	selector, W	;Revisar que modo es
	XORLW	0
	BTFSC	STATUS, 2
	BSF	flagmode, 0	;Modo 0

	MOVF	selector, W	;Revisar que modo es
	XORLW	1
	BTFSC	STATUS, 2
	BSF	flagmode, 1	;Modo 1

	MOVF	selector, W	;Revisar que modo es
	XORLW	2
	BTFSC	STATUS, 2
	BSF	flagmode, 2	;Modo 2

	MOVF	selector, W	;Revisar que modo es
	XORLW	3
	BTFSC	STATUS, 2
	BSF	flagmode, 3	;Modo3

	MOVF	selector, W	;Revisar que modo es
	XORLW	4
	BTFSC	STATUS, 2
	BSF	flagmode, 4	;Modo 4
        RETURN

    aceptar:

	MOVF	semaf1temp, W
	MOVWF	valorsemaf1
	MOVF	semaf2temp, W
	MOVWF	valorsemaf2
	MOVF	semaf3temp, W
	MOVWF	valorsemaf3

	bsf	flagnum, 3
	bsf	flagnum, 4  ;apagar el conteo
	bsf	flagnum, 5

	BTFSC	flagint, 5	;Interaccion de las led de modo
	BCF	PORTA, 4

	BTFSC	flagint, 5	;Interaccion de las led de modo
	BCF	PORTA, 5

	BTFSC	flagint, 5	;Interaccion de las led de modo
	BCF	PORTA, 6


	MOVLW	01111000B
	MOVWF	flash

	MOVLW	00111111B
	MOVWF	PORTC
	MOVLW	11111111B
	MOVWF	PORTD

	bsf	PORTA, 2
	bsf	PORTA, 5    ;Poner luces wn rojo
	bsf	PORTB, 3
	bcf	PORTA, 0


	BTFSC	flagint, 3
	DECFSZ	threeseg
	RETURN

	MOVLW	3
	MOVWF	threeseg
	bcf	flagint, 1
	clrf	flash
	clrf	flagnum
	RETURN
    mode4:
	BSF	PORTB, 4	;Luces de modo
	BSF	PORTB, 5
	BSF	PORTB, 6
	BTFSS	flag, 7
	CALL	offdisp4
	BSF	flag, 7

	BTFSC flagint, 1	;Verificar si la bandera de PORTB 0 on change
	CALL  aceptar		;Incrementar contador
	BTFSC flagint, 2	;Verificar si la bandera de PORTB 1 on change
	CALL  modeselector	;Decrementar contador

	BTFSS	flagnum, 3
	call	via1
	BTFSS	flagnum, 4
	call	via2
	BTFSS	flagnum, 5
	call	via3


	RETURN
    mode3:
	BTFSS	flag, 7
	CALL	initdisp4
	BSF	flag, 7

	BTFSC flagint, 1	;Verificar si la bandera de PORTB 0 on change
	CALL  inc_num		;Incrementar contador
	BTFSC flagint, 2	;Verificar si la bandera de PORTB 1 on change
	CALL  dec_num		;Decrementar contador

	MOVF	tempt, W	;Guardar el numero en el display en variable
	MOVWF	semaf3temp	;Temporal



	BTFSS	flagnum, 3
	call	via1
	BTFSS	flagnum, 4
	call	via2
	BTFSS	flagnum, 5
	call	via3

	BSF	PORTB, 4	;Luces de modo
	BCF	PORTB, 5
	RETURN
    mode2:
	BTFSS	flag, 7
	CALL	initdisp4
	BSF	flag, 7

	BTFSC flagint, 1	;Verificar si la bandera de PORTB 0 on change
	CALL  inc_num		;Incrementar contador
	BTFSC flagint, 2	;Verificar si la bandera de PORTB 1 on change
	CALL  dec_num		;Decrementar contador

	MOVF	tempt, W	;Guardar el numero en el display en variable
	MOVWF	semaf2temp	;Temporal

	BTFSS	flagnum, 3
	call	via1
	BTFSS	flagnum, 4
	call	via2
	BTFSS	flagnum, 5
	call	via3

	BSF	PORTB, 5
	BCF	PORTB, 6
	RETURN
    mode1:
	BTFSS	flag, 7
	CALL	initdisp4	;Reset del display
	BSF	flag, 7

	BTFSS	flagnum, 3
	call	via1
	BTFSS	flagnum, 4
	call	via2
	BTFSS	flagnum, 5
	call	via3

	MOVF	tempt, W	;Guardar el numero en el display en variable
	MOVWF	semaf1temp	;Temporal

	BTFSC flagint, 1	;Verificar si la bandera de PORTB 0 on change
	CALL  inc_num		;Incrementar contador
	BTFSC flagint, 2	;Verificar si la bandera de PORTB 1 on change
	CALL  dec_num		;Decrementar contador

	BSF	PORTB, 6	;Encender luz
	RETURN
    mode0:
	BTFSS	flag, 7
	CALL	offdisp4
	BSF	flag, 7

	MOVLW	10
	MOVWF	valorsemaf1
	MOVWF	valorsemaf2
	MOVWF	valorsemaf3
        BTFSS	flagnum, 3
	call	via1
	BTFSS	flagnum, 4
	call	via2
	BTFSS	flagnum, 5
	call	via3

	BCF	PORTB, 4	;Luces de modo
	BCF	PORTB, 5
	BCF	PORTB, 6
	RETURN


    initdisp4:
	BCF	flag, 6
	MOVLW	10
	MOVWF	tempt
	RETURN
    offdisp4:
	BSF	flag, 6
	clrf	PORTC
	BSF	PORTD, 6
	BSF	PORTD, 7
	RETURN
    setvar1:	 ;La via 1 empieza con 10
	MOVF	valorsemaf1, w
	MOVWF	semaforo1
	ADDLW	3
	MOVWF	semaforo2
	ADDWF	semaforo2, W
	MOVWF	semaforo3
	RETURN

    setvar2:
	MOVLW 3
	RETURN

    setvar3:
	MOVF	valorsemaf2, w
	MOVWF	semaforo2
	ADDLW	3
	MOVWF	semaforo3
	ADDWF	semaforo3, W
	MOVWF	semaforo1
	RETURN

    setvar4:
	MOVF	valorsemaf3, w
	MOVWF	semaforo3
	ADDLW	3
	MOVWF	semaforo1
	ADDWF	semaforo1, W
	MOVWF	semaforo2
	RETURN

    titileo:
	BCF	flagint, 5
	BTFSC	flash, 4
	    goto lightoff	;Toogle
    lighton:
	BTFSC	flash,	0	;Ver que luz se debe de encender
	bsf PORTA, 0
	BTFSC	flash,	0	;Display 1
	bcf flag, 3

	BTFSC	flash,	1	;Ver que luz se debe de encender
	bsf PORTA, 3
	BTFSC	flash,	1	;Display 2
	bcf flag, 4

	BTFSC	flash,	2	;Ver que luz se debe de encender
	bsf PORTA, 6
	BTFSC	flash,	2	;Display 3
	bcf flag, 5

	BTFSC	flash,	3	;Ver que luz se debe de encender
	bsf PORTB, 6
	BTFSC	flash,	3	;Ver que luz se debe de encender
	bsf PORTB, 5
	BTFSC	flash,	3	;Ver que luz se debe de encender
	bsf PORTB, 4
	bsf flash, 4
	RETURN
    lightoff:
	clrf	PORTC
	BTFSC	flash,	0
	bcf  PORTA, 0
	BTFSC	flash,	0	;Display 1
	bsf flag, 3
	BTFSC	flash,	0	;Display 1
	bsf  PORTD, 0
	BTFSC	flash,	0	;Display 1
	bsf  PORTD, 1


	BTFSC	flash,	1
	bcf  PORTA, 3
	BTFSC	flash,	1	;Display 2
	bsf flag, 4
	BTFSC	flash,	1	;Display 2
	bsf  PORTD, 2
	BTFSC	flash,	1	;Display 2
	bsf  PORTD, 3

	BTFSC	flash,	2	;Ver que luz se debe de encender
	bcf PORTA, 6
	BTFSC	flash,	2	;Display 3
	bsf flag, 5
	BTFSC	flash,	2	;Display 3
	bsf  PORTD, 4
	BTFSC	flash,	2	;Display 3
	bsf  PORTD, 5

	BTFSC	flash,	3	;Ver que luz se debe de encender
	bcf PORTB, 4
	BTFSC	flash,	3	;Ver que luz se debe de encender
	bcf PORTB, 5
	BTFSC	flash,	3	;Ver que luz se debe de encender
	bcf PORTB, 6
	bcf  flash, 4
	RETURN

    via1:
	BSF	flagnum, 4	;Desactivar el modulo via 2 y 3
	BSF	flagnum, 5	;
	BSF	PORTA, 5
	BSF	PORTB, 3
	BCF	PORTA, 2
	BCF	PORTA, 7    ;Apagar luz amarilla

	;Poner valores iniciales
	BTFSS	flagnum, 0	;Limpiar port A
	clrf	PORTA
	BTFSS	flagnum, 0	;Limpiar flash
	clrf	flash
	BTFSS	flagnum, 0	;Enceder la luz verde solo una vez
	BSF	PORTA, 0
	BTFSS	flagnum,0	;Hacer que solo se carguen valores 1 vez
	call	setvar1
	BSF	flagnum,0
	;Decrementar los contadores
	BTFSC	flagint, 3
	call	semafdec    ;decrementar semaforos
	;Titileo de las luz verde
	MOVF	semaforo2, w
	XORLW	00000110B
	BTFSC	STATUS, 2
	bsf     flash, 0    ;Activar el titiliteo
	BTFSC	flagint, 5  ;Verificar si pasaron 250ms
	call	titileo
	;3 segundos en verde
	BTFSC	flag, 0	;Revisar bandera de Zero en el semaforo 1
	call	setvar2
	BTFSC	flag, 0
	MOVWF	semaforo1   ;Cargar los 3 segundos de amarillo
	BTFSC	flag, 0
	BCF	PORTA, 0    ;Apagar la luz verde
	BTFSC	flag, 0
	BCF	flash, 0    ;Apagar titileo
	BTFSC	flag, 0
	BCF	flag, 3    ;Apagar titileo display
	BTFSC	flag, 0
	BSF	PORTA, 1    ;Encender luz amarilla
	BTFSC	flag, 0	    ;Apagar la bandera del semaforo1
	BCF	flag, 0


	BTFSC	flag, 1	    ;Ver si el semaforo2 llego a 0
	BSF	flagnum, 3  ;Avisar que la siguiente es via 2
	BTFSC	flag, 1
	BCF	flagnum, 4
	BCF	flag, 1
	RETURN

    via2:
	BSF	PORTA, 2    ;Enceder rojo de  semaforo 1
	BSF	PORTB, 3    ;Encender rojo de semaforo 3
	BCF	PORTA, 5    ;Apagar rojo de semaforo 2
	BCF	PORTA, 1    ;Apagar luz amarilla semaforo 1
	;Variables inciales
	BTFSS	flagnum, 1	;Enceder la luz verde solo una vez
	BSF	PORTA, 3
	BTFSS	flagnum, 1
	call	setvar3		;Colocar valores iniciales para la via dos
	BSF	flagnum, 1	;Encender la bandera para que no se repita
	BTFSC	flagint, 3	;Revisar si paso un segundo
	call	semafdec
	;Luz verde titilante
	MOVF	semaforo3, w
	XORLW	00000110B
	BTFSC	STATUS, 2
	bsf     flash, 1    ;Activar el titiliteo
	BTFSC	flagint, 5  ;Verificar si pasaron 250ms
	call	titileo

	;3 segundos amarillo
	BTFSC	flag, 1
	call	setvar2
	BTFSC	flag, 1
	MOVWF	semaforo2
	BTFSC	flag, 1
	BCF	PORTA, 3    ;Apagar la luz verde
	BTFSC	flag, 1
	BCF	flash, 1    ;Apagar el titileo
	BTFSC	flag, 1
	BCF	flag, 4    ;Apagar titileo display
	BTFSC	flag, 1
	BSF	PORTA, 4    ;Encender luz amarilla
	BTFSC	flag, 1	    ;Apagar la bandera del semaforo1
	BCF	flag, 1

	
	;Avisar que la siguiente es via 3
	BTFSC	flag, 2	    ;Revisar si el semaforo 3 esta en 0
	BSF	flagnum, 4  ;Avisar que la siguiente es via 2
	BTFSC	flag, 2
	BCF	flagnum, 5  ;Activar el modulo de via 3
	BCF	flag, 2
	RETURN

     via3:
	BSF	PORTA, 2    ;Encender luz roja semaforo 1
	BSF	PORTA, 5    ;Encender luz roja semaforo 2
	BCF	PORTB, 3    ;Apagar luz roja de semaforo 3
	BCF	PORTA, 4    ;Apagar luz amarilla de semaforo 2
	;Variables inciales
	BTFSS	flagnum, 2	;Enceder la luz verde solo una vez
	BSF	PORTA, 6
	BTFSS	flagnum, 2
	call	setvar4		;Colocar valores iniciales para la via dos
	BSF	flagnum, 2	;Encender la bandera para que no se repita
	BTFSC	flagint, 3	;Revisar si paso un segundo
	call	semafdec
	;Luz verde titilante
	MOVF	semaforo1, w
	XORLW	00000110B
	BTFSC	STATUS, 2
	bsf     flash, 2    ;Activar el titiliteo
	BTFSC	flagint, 5  ;Verificar si pasaron 250ms
	call	titileo
	;3 segundos amarillo
	BTFSC	flag, 2
	call	setvar2
	BTFSC	flag, 2
	MOVWF	semaforo3
	BTFSC	flag, 2
	BCF	PORTA, 6    ;Apagar la luz verde
	BTFSC	flag, 2
	BCF	flash, 2    ;Apagar el titileo
	BTFSC	flag, 2
	BCF	flag, 5    ;Apagar titileo display
	BTFSC	flag, 2
	BSF	PORTA, 7
	BTFSC	flag, 2	    ;Apagar la bandera del semaforo1
	BCF	flag, 2
	;Avisar que la siguiente es via 3
	BTFSC	flag, 0	    ;Revisar si el semaforo 1 esta en 0
	BSF	flagnum, 5  ;Avisar que via 3 ya paso
	BTFSC	flag, 0
	BCF	flagnum, 3  ;Activar el modulo de via 1

	
	;Activar la lectura de intial values
	BTFSC	flag, 0
	clrf	flagnum
	BCF	flag, 0
	RETURN

    semafdec:
	BCF	flagint, 3	;Limpiar la interrupcion
	DECF	semaforo1
	BTFSC	STATUS, 2	;Revisar bandera de Zero
	BSF	flag,0
	DECF	semaforo2
	BTFSC	STATUS, 2	;Revisar bandera de Zero
	BSF	flag,1
	DECF	semaforo3
	BTFSC	STATUS, 2	;Revisar bandera de Zero
	BSF	flag,2
	RETURN

    disp_refresh:
	BCF  flagint, 4	    ;Limpiar bandera de que hubo un int por el Timer0
	MOVF	decenas1, W
	call	table0	    ;Buscar el nibble menos significativo en la tabla
	MOVWF	condisp1	    ;Guardar en el condisp

	MOVF	unidades1, W
	call	table0	    ;Buscar el nibble mas significativo en la tabla
	MOVWF	condisp1+1   ;Guardar en el segundo byte de condisp

	MOVF	decenas2, W
	call	table0
	MOVWF	condisp2    ;Guardar en variable las centenas


	MOVF	unidades2, W
	call	table0
	MOVWF	condisp2+1  ;Guardar en variable las decenas

	MOVF	decenas3, W
	call	table0
	MOVWF	condisp3  ;Guardar en variable las unidades

	MOVF	unidades3, W
	call	table0
	MOVWF	condisp3+1  ;Guardar en variable las unidades

	MOVF	decenas4, W
	call	table0
	MOVWF	condisp4  ;Guardar en variable las unidades

	MOVF	unidades4, W
	call	table0
	MOVWF	condisp4+1  ;Guardar en variable las unidades

	RETURN


    inc_num:
	bcf	flagint,1
	incf	tempt, F	    ;Incrementar el contador

	MOVF	tempt, W
	XORLW	00010101B
	BTFSC	STATUS, 2   ;Ver si paso de 20
	BSF	flagnum, 7  ;Avisar que paso de 20
	BTFSC	flagnum, 7
	MOVLW	10	    ;Mover el valor deseado
	BTFSC	flagnum, 7
	MOVWF	tempt, F
	BCF	flagnum, 7

	RETURN		    ;Regresar al loop


    dec_num:
	bcf	flagint, 2
	decf    tempt, F	    ;Decrementar el puerto
	MOVF	tempt, W
	;Hacer el loop
	XORLW	9
	BTFSC	STATUS, 2	    ;Ver si es menor con la bander zero
	BSF	flagnum, 6	    ;Avisar si es menor
	BTFSC	flagnum, 6
	MOVLW	20		    ;Mover el valor deseado
	BTFSC	flagnum, 6
	MOVWF	tempt
	BCF	flagnum, 6
	RETURN

   decimales:
	MOVF    semaforo1, W
	call    restas	    ;Llamar a subrutina de restas

	MOVF    decenas, W  ;Mover el contador de decenas a variable de display
	MOVWF	decenas1, F

	MOVF    unidades, W ;Mover el contador de unidades a
	MOVWF	unidades1, F

	clrf	unidades
	clrf	decenas

	MOVF    semaforo2, W
	call    restas	    ;Llamar a subrutina de restas

	MOVF    decenas, W  ;Mover el contador de decenas a variable de display
	MOVWF	decenas2, F

	MOVF    unidades, W ;Mover el contador de unidades a
	MOVWF	unidades2, F

	clrf	unidades
	clrf	decenas

	MOVF    semaforo3, W
	call    restas	    ;Llamar a subrutina de restas

	MOVF    decenas, W  ;Mover el contador de decenas a variable de display
	MOVWF	decenas3, F

	MOVF    unidades, W ;Mover el contador de unidades a
	MOVWF	unidades3, F

	clrf	unidades
	clrf	decenas


	;Pasar a decimales display extra
	MOVF	tempt, W
	call	restas
	MOVF    decenas, W  ;Mover el contador de decenas a variable de display
	MOVWF	decenas4, F

	MOVF    unidades, W ;Mover el contador de unidades a
	MOVWF	unidades4, F

	clrf	unidades
	clrf	decenas
	RETURN

    restas:	;pasar a decimal
	MOVWF	valor, F
	MOVLW	10
	SUBWF	valor, F    ;Restar 10 al valor
	btfsc	STATUS, 0   ;Revisar si ocurrio un borrow, 1= no borrow, 0 = borrow
	INCF	decenas     ;Incrementar el contador de decenas
	btfsc	STATUS, 0   ;Revisar si ocurrio un borrow, 1= no borrow, 0 = borrow
	goto	$-4
	ADDWF	valor	    ;Sumar 10 al valor para no perder el numero
	;Termina decenas
	MOVLW	1
	SUBWF	valor,F    ;Restar uno a una variable
	btfsc	STATUS, 0
	INCF	unidades    ;Incrementar el contador de unidades
	btfsc	STATUS,0    ;Revisar si ocurrio un borrow
	goto    $-4	    ;Regresar para restar varias veces unidades
	ADDWF	valor
	RETURN

END
