; Archivo: Proyecto1.s
; Dispositivo: PIC16F887
; Autor: Diego Mendez
; Compilador: pic-as (v2.30), MPLABX v5.40
; 
; Programa: Utilizando Interrupts, un contadores decimales y luces
; Hardware: Push buttons puerto B, 2Displays y Leds
; 
; Creado: 22 feb, 2021
; Última modificación: 22 feb, 2021

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
	PSECT udata_bank0 ;common memory
	
	selec_disp: DS 1; 1 byte
	W_Temp:	    DS 1; 1 byte
	STAT_Temp:  DS 1; 1 byte
    
	flagint:    DS 1; 1 byte
	flagmode:   DS 1; 1 byte
	flag:	    DS 1; 1 byte
	flagnum:    DS 1; 1 byte
    
        condisp:    DS 2; 2 bytes
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
	
	semaforo1:  DS 1; 1 byte
	semaforo2:  DS 1; 1 byte
	semaforo3:  DS 1; 1 byte
	oneseg:	    DS 1; 1 byte
	tempt:	    DS 1; 1 byte
	valor:	    DS 1; 1 byte
    
    GLOBAL flagint, condisp1, selec_disp, W_Temp, STAT_Temp
    GLOBAL decenas1, unidades1, condisp4
	
	    
    
    
;---------------------------VECTOR RESET--------------------------------------
   PSECT resVect, class=CODE, abs, delta=2
    ORG 00h	;posicion 0000h para el reset
   resetVec:
	PAGESEL main
	goto main
	
;---------------------------VECTOR INTERRUPT------------------------------------
  ;Vector para la interrupción
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
    MOVF    condisp1, W	    ;Mover el valor de la variable al PORT
    MOVWF   PORTC
    BSF	    PORTD,0	    ;Encender el display 0
    BSF   selec_disp, 0		    ;Proximo interrupt ir a display1
    RETURN	    
   
   display1:
    BCF	    selec_disp, 0   ;Limpiar bandera de display 1
    MOVF    condisp1+1, W    ;Mover el valor de la variable al port
    MOVWF   PORTC	    
    BSF	    PORTD,1	    ;Encender el display 1
    BSF	    selec_disp, 1		   ;Proximo interrupt ir a display2
    RETURN
    
   display2:
    BCF	    selec_disp, 1   ;Limpiar bandera de display 2
    MOVF    condisp2,W	   ;Mover el valor de centenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 2	    ;Encender el display 2
    BSF	    selec_disp, 2   ;Proximo display sea 3
    RETURN
    
   display3:
    BCF	    selec_disp, 2   ;Limpiar bandera de display 3
    MOVF    condisp2+1,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 3	    ;Encender el display 3
    BSF	    selec_disp,	3   ;Proximo display sea el 4
    RETURN
    
   display4:
    BCF	    selec_disp, 3   ;Limpiar bandera de display 3
    MOVF    condisp3,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 4	    ;Encender el display 4
    BSF	    selec_disp,	4   ;Proximo display sea el 5
    RETURN
   
   display5:
    BCF	    selec_disp, 4   ;Limpiar bandera de display 4
    MOVF    condisp3+1,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 5	    ;Encender el display 5
    BSF	    selec_disp,	5   ;Proximo display sea el 6
    RETURN
    
   display6:
    BCF	    selec_disp, 5   ;Limpiar bandera de display 5
    MOVF    condisp4,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 6	    ;Encender el display 6
    BSF	    selec_disp,	6   ;Proximo display sea el 7
    RETURN
    
   display7:
    BCF	    selec_disp, 6   ;Limpiar bandera de display 6
    MOVF    condisp4+1,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 7	    ;Encender el display 7
    clrf    selec_disp
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
	
	;T1CON se encuentra en el mismo banco que los ports
	bsf	T1CON, 4    ;Colocar el prescaler de timer1 a 1:2
	bsf	T1CON, 0    ;Encender el timer 1 
	
	
	banksel OPTION_REG  ;Configurar prescaler
	bsf	PIE1, 0	    ;Activar el Interrupt del Timer 1
	
	CLRWDT		    ;Limpiar WDT
	MOVLW	01000100B   ;Poner el prescaler en 32, activar PULLUP y WDT en timer0
	MOVWF	OPTION_REG
	
	
	
	;Weak PULLUP y IOCB se encuentran en el mismo banco que option_reg
	MOVLW	00000111B   ;Configurar b0, b1 y b2 para que tengan weak pullup
	MOVWF	WPUB
	MOVWF	IOCB    ;Configurar b0 y b1 para que funcione int-on-change
	
	
	
	banksel PORTA
	MOVLW 00111111B	  ;Darle un valor al puerto D
	MOVWF PORTD
	MOVWF PORTC
	
	MOVLW 10
	MOVWF oneseg
	 
	
;--------------------------------LOOP-------------------------------------------
    loop:
	;BTFSC flagint, 0
	
	BTFSC flagint, 1	;Verificar si la bandera de PORTB 0 on change
	CALL  inc_num		;Incrementar contador
	BTFSC flagint, 2	;Verificar si la bandera de PORTB 1 on change
	CALL  dec_num		;Decrementar contador
	
	CALL  mode0
	
	CALL  decimales
	CALL  disp_refresh	;preparar para un refresh
	
	goto  loop
 
;---------------------------------SUBRUTINA-------------------------------------
<<<<<<< HEAD
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
	
	clrf	flash
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
	RETURN
    
    mode0:
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
	
	
	RETURN
	
    
    setvar1:	 ;La via 1 empieza con 10
	MOVF	valorsemaf1
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
	MOVF	valorsemaf2
	MOVWF	semaforo2
	ADDLW	3
	MOVWF	semaforo3
	ADDWF	semaforo3, W
	MOVWF	semaforo1
	RETURN
	
    setvar4:
	MOVF	valorsemaf3
	MOVWF	semaforo3
	ADDLW	3
	MOVWF	semaforo1
	ADDWF	semaforo1, W
	MOVWF	semaforo2
	RETURN
    
    via1:
	BSF	flagnum, 4	;Desactivar el modulo via 2 y 3
	BSF	flagnum, 5
	BSF	PORTA, 0
	BTFSS	flagnum,0	    ;Hacer que solo se carguen valores 1 vez
	call	setvar1	    
	BSF	flagnum,0
	BTFSC	flagint, 3
	call	semafdec    ;decrementar semaforos 
	
	BTFSC	flag, 0	;Revisar bandera de Zero en el semaforo 1
	call	setvar2
	BTFSC	flag, 0
	MOVWF	semaforo1   ;Cargar los 3 segundos de amarillo
	BTFSC	flag, 0	    
	BCF	PORTA, 0
	BTFSC	flag, 0	    
	BSF	PORTA, 1
	
	BTFSC	flag, 0	    
	BCF	flag, 0
	
	BTFSC	flag, 1
	BSF	flagnum, 3  ;Avisar que la siguiente es via 2
	BTFSC	flag, 1
	BCF	flagnum, 4
	BCF	flag, 1
	RETURN

    via2:
	clrf	PORTA
	BSF	PORTA, 2
	BSF	PORTA, 3
	BTFSS	flagnum, 1
	call	setvar3		;Colocar valores iniciales para la via dos 
	BSF	flagnum, 1	;Encender la bandera para que no se repita 
	BTFSC	flagint, 3	;Revisar si paso un segundo 
	call	semafdec
	;3 segundos amarillo
	BTFSC	flag, 1
	call	setvar2
	BTFSC	flag, 1
	MOVWF	semaforo2
	BTFSC	flag, 1
	BCF	flag, 1
	;Avisar que la siguiente es via 3
	BTFSC	flag, 2	    ;Revisar si el semaforo 3 esta en 0
	BSF	flagnum, 4  ;Avisar que la siguiente es via 2
	BTFSC	flag, 2
	BCF	flagnum, 5  ;Activar el modulo de via 3
	BCF	flag, 2
	RETURN
	
     via3:
	BTFSS	flagnum, 2
	call	setvar4  	;Colocar valores iniciales para la via dos 
	BSF	flagnum, 2	;Encender la bandera para que no se repita 
	BTFSC	flagint, 3	;Revisar si paso un segundo 
	call	semafdec
	;3 segundos amarillo
	BTFSC	flag, 2
	call	setvar2
	BTFSC	flag, 2
	MOVWF	semaforo3
	BTFSC	flag, 2
	BCF	flag, 2
	;Avisar que la siguiente es via 3
	BTFSC	flag, 0	    ;Revisar si el semaforo 1 esta en 0
	BSF	flagnum, 5  ;Avisar que la siguiente es via 2
	BTFSC	flag, 0
	BCF	flagnum, 3  ;Activar el modulo de via 1
	
	;Activar la lectura de intial values
	BTFSC	flag, 0	    
	BCF	flagnum, 0  
	BTFSC	flag, 0
	BCF	flagnum, 1 
	BTFSC	flag, 0
	BCF	flagnum, 2 
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
	call	restas
	MOVF    decenas, W  ;Mover el contador de decenas a variable de display
	MOVWF	decenas4, F
	
	MOVF    unidades, W ;Mover el contador de unidades a 
	MOVWF	unidades4, F
	
	clrf	unidades
	clrf	decenas
	RETURN		    ;Regresar al loop

	
    dec_num:
	bcf	flagint, 2
	decf    tempt, F	    ;Decrementar el puerto
	MOVF	tempt, W
	call    restas
	MOVF    decenas, W  ;Mover el contador de decenas a variable de display
	MOVWF	decenas4, F
	
	MOVF    unidades, W ;Mover el contador de unidades a 
	MOVWF	unidades4, F
	
	clrf	unidades
	clrf	decenas
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


