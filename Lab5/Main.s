; Archivo: Lab5Pgr.s
; Dispositivo: PIC16F887
; Autor: Diego Mendez
; Compilador: pic-as (v2.30), MPLABX v5.40
; 
; Programa: Utilizando Interrupts
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
	condisp:    DS 2; 2 bytes
	condisp1:   DS 3; 2 bytes
	W_Temp:	    DS 1; 1 byte
	STAT_Temp:  DS 1; 1 byte
	flagint:    DS 1; 1 byte 
	flagnum:    DS 1; 1 byte 
	nibblelow:  DS 1; 1 byte
	nibblehigh: DS 1; 1 byte
	centenas:   DS 1; 1 byte
	decenas:    DS 1; 1 byte
	unidades:   DS 1; 1 byte
	varbin:	    DS 1; 1 byte
    
    GLOBAL flagint, condisp, selec_disp, W_Temp, STAT_Temp, nibblelow
    GLOBAL nibblehigh, varbin, flagnum, centenas, decenas, unidades
	
	    
    
    
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
	call	timerflag
	
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
    bcf	    INTCON,0	;Limpiar bandera RBIF
    RETURN
    
   timerflag:
    BSF	    flagint, 2	;Encender una bandera externa
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
    
   display0:
    MOVF    condisp+1, W	    ;Mover el valor de la variable al PORT
    MOVWF   PORTC
    BSF	    PORTD,0	    ;Encender el display 0
    MOVLW   1		    ;Proximo interrupt ir a display1
    goto    next_disp	    
   
   display1:
    MOVF    condisp, W    ;Mover el valor de la variable al port
    MOVWF   PORTC	    
    BSF	    PORTD,1	    ;Encender el display 1
    MOVLW   2		   ;Proximo interrupt ir a display2
    goto    next_disp
    
   display2:
    MOVF    condisp1,W	   ;Mover el valor de centenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 2	    ;Encender el display 2
    MOVLW   4   ;Proximo display sea 3
    goto    next_disp
    
   display3:
    MOVF    condisp1+1,W    ;Mover el valor de decenas al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 3	    ;Encender el display 3
    MOVLW   8   ;Proximo display sea 4
    goto    next_disp
    
   display4:
    MOVF    condisp1+2,W	   ;Mover el valor de unidades al PORTC
    MOVWF   PORTC
    BSF	    PORTD, 4	    ;Encender el display 4
    MOVLW   0	    ;Proximo display sea 0
    goto    next_disp
    
   next_disp:
    MOVWF   selec_disp
    RETURN
    
   Ntimer0:
	banksel TMR0		;Buscar timer 0 en el banco
	MOVLW   6		;Cargar el valor de N  a W
	MOVWF   TMR0		;Cargar el valor de W a Timer0
	BCF	INTCON, 2	;Limpiar bandera de INTCON
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
	MOVLW 11111111B
	MOVWF	TRISB
	clrf	TRISC	;Configurar puerto C
	clrf	TRISD	;Configurar puerto D
	clrf	TRISE
	
	BSF INTCON, 7	;Activar global Int
	BSF INTCON, 5	;Timer0 INt
	BSF INTCON, 3	;PORTB int
	
	banksel	PORTA	;Moverme al banco de los PORTS
	clrf	PORTA	;Colocar pines de A en 0
	clrf	PORTC	;Colocar pines de C en 0
	clrf	PORTD	;Colocar pines de D en 0
	clrf	PORTE	;Colocar pines de E en 0
	
	banksel OPTION_REG  ;Configurar prescaler
	CLRWDT		    ;Limpiar WDT
	MOVLW	01000100B   ;Poner el prescaler en 32, activar PULLUP y WDT en timer0
	MOVWF	OPTION_REG
	
	;Weak PULLUP y IOCB se encuentran en el mismo banco que option_reg
	MOVLW	00000011B   ;Configurar b0 y b1 para que tengan weak pullup
	MOVWF	WPUB
	MOVWF	IOCB    ;Configurar b0 y b1 para que funcione int-on-change
	
	banksel OSCCON
	bsf	OSCCON,0    ; El reloj interno utiliza el oscilador interno
	
	banksel PORTA
	MOVLW 00111111B	  ;Darle un valor al puerto D
	MOVWF PORTD
	MOVWF PORTC
	
	clrf condisp
	clrf flagnum
	clrf centenas
	clrf decenas
	clrf unidades
	
;--------------------------------LOOP-------------------------------------------
    loop:
	BTFSC flagint, 0
	CALL  inc_portA
	BTFSC flagint, 1
	call  dec_portA
	call split_nibbles
	
	BTFSS flagnum, 0
	call rescen
	BTFSS flagnum, 1
	call resdec
	BTFSS flagnum, 2
	call resun
	
	call  disp_refresh
	
	goto  loop
 
;---------------------------------SUBRUTINA-------------------------------------
    	
   

	
    disp_refresh:
	BCF  flagint, 2	    ;Limpiar bandera de que hubo un int por el Timer0
	MOVF	nibblelow, W   
	call	table0	    ;Buscar el nibble menos significativo en la tabla 
	MOVWF	condisp	    ;Guardar en el condisp
	
	MOVF	nibblehigh, W  
	call	table0	    ;Buscar el nibble mas significativo en la tabla
	MOVWF	condisp+1   ;Guardar en el segundo byte de condisp
	
	MOVF	centenas, W
	call	table0
	MOVWF	condisp1    ;Guardar en variable las centenas
	
	
	MOVF	decenas, W
	call	table0
	MOVWF	condisp1+1  ;Guardar en variable las decenas
	
	MOVF	unidades, W
	call	table0
	MOVWF	condisp1+2  ;Guardar en variable las unidades
	
	RETURN

	
    inc_portA:
	clrf flagnum
	clrf flagint
	clrf centenas	    ;Limpiar contador
	clrf decenas	    ;Limpiar contador
	clrf unidades    ;Limpiar contador
	incf PORTA, F	    ;Incrementar el contador
	;btfsc PORTA,4	    ;Si los 4 bits se encuentran encendidos resetear
	;clrf  PORTA	    ;Limpiar si se pasa de los 4 bits
	;MOVF PORTA, 0	    ;Copiar el valor del contador para busacr en la tabla
	;call table0	    ;Llamar en la tabla los bits que deben estar encendidos
	;MOVWF PORTC	    ;Guardar en el port los bits para el display
	RETURN		    ;Regresar al loop

	
    dec_portA:
	clrf flagnum
	clrf flagint
	clrf centenas	    ;Limpiar contador
	clrf decenas	    ;Limpiar contador
	clrf unidades    ;Limpiar contador
	decf PORTA, F	 ;Decrementar el puerto
	;MOVLW 0x0F	;Cargar valor a W para cuando se decrementa de 0 a F hex
	;btfsc PORTA, 7;Revisar si se encuentra el bit8 encendido
	;MOVWF PORTA   ;Cargar W en puerto para que solo esten encendido 4 bits
	;MOVF PORTA, 0	;Cargar el valor de la variable contador a W
	;call table0	;Llamar a la tabla donde estan los bits para el display
	;MOVWF PORTC	;Mover el valor de W a PORTD con los bits de la table
	RETURN
	
    split_nibbles:
	MOVF  PORTA, W	    ;Mover el valor de PORTA a W
	ANDLW 0x0f	    ;Hacer un and de los primeros 4 bits
	MOVWF nibblelow	    ;Mover a variable
	SWAPF PORTA, W	    ;Swappear PORTA y guardar en W
	ANDLW 0x0f	    ;Hacer un And
	MOVWF nibblehigh    ;Guardar los 4bits superiores en variable
	RETURN
	
    rescen:
	BSF flagnum, 1
	BSF flagnum, 2
	MOVF PORTA, W
	MOVWF varbin	    ;Mover el valor binario a una variable
	MOVLW	100
	SUBWF	varbin, F   ;Restar 100 a varbin
	btfsc	STATUS, 0   ;Revisar si ocurrio un borrow
	INCF	centenas    ;Incrementar el contador de centenas
	btfss	STATUS, 0  
	BSF	flagnum,0
	btfss	STATUS, 0  
	BCF	flagnum,1
	btfss	STATUS, 0  
	BCF	flagnum,2
	btfss	STATUS, 0
	ADDWF	varbin	    ;Sumar 100 al valor anterior para regresar al numero
	RETURN

    resdec:
	BSF	flagnum,2
	MOVLW	10
	SUBWF	varbin, F   ;Restar 10 al valor
	btfsc	STATUS, 0   ;Revisar si ocurrio un borrow
	INCF	decenas	    ;Incrementar el contador de decenas
	btfss	STATUS,	0   ;Revisar si ocurrio un borrow
	BSF	flagnum, 1  ;Levantar la bandera
	RETURN
    
    resun:
	MOVLW	1
	SUBWF	varbin,F    ;Restar uno a una variable
	btfsc	STATUS, 0
	INCF	unidades    ;Incrementar el contador de unidades
	btfss	STATUS,0    ;Revisar si ocurrio un borrow
	BSF	flagnum, 2  ;Levantar bandera
	btfss	STATUS, 0
	ADDWF	varbin
	RETURN
    

END
