; Archivo: Lab4Pgr.s
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
	
	var500ms:   DS 1; 1 byte
	condisp:    DS 1; 1 byte
	W_Temp:	    DS 1; 1 byte
	STAT_Temp:  DS 1; 1 byte
	flagint:    DS 1; 1 byte 
    
    GLOBAL flagint, condisp, var500ms, W_Temp, STAT_Temp
	
	    
    
    
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
	BCF	INTCON, 7
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
 
   pushbt:
    btfss   PORTB, 0	;Verificar si el RB0 esta presionado
    BSF	    flagint, 0
    btfss   PORTB, 1	;Verfiicar si el RB1 esta presionado 
    BSF	    flagint, 1
    bcf	    INTCON,0	;Limpiar bandera RBIF
    RETURN
    
   timerflag:
    BSF flagint, 2	;Encender una bandera externa
    BCF	INTCON, 2	;Apagar la bandera timer0
    RETURN
 ;----------------------------------TABLA----------------------------------------
   PSECT code, delta=2, abs
   ORG 100h ; posicion para el codigo       
    table0:
	clrf PCLATH
	bsf  PCLATH,0	;Ubicar el PCLATH para que PC este en 100h
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
	MOVLW 11110000B ;Designar valor de W a los puertos que deseo como inputs
	MOVWF	TRISA	;Mover el valor de W al TRISA
	MOVLW 11111111B
	MOVWF	TRISB
	clrf	TRISC
	clrf	TRISD	;Configurar puerto D
	
	BSF INTCON, 7	;Activar global Int
	BSF INTCON, 5	;Timer0 INt
	BSF INTCON, 3	;PORTB int
	
	banksel	PORTA	;Moverme al banco de los PORTS
	clrf	PORTA
	clrf	PORTC
	clrf	PORTB
	clrf	PORTD	;Colocar pines de D en 0
	
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
	MOVLW	125	   	;Debido a que timer0 cuenta 2ms
	MOVWF	var500ms	;Definir el valor de la variable o reiniciarla
	call Ntimer0	  ;Colocar el valor N del timer, limpiar flag de INTCON
	
;--------------------------------LOOP-------------------------------------------
    loop:
	BTFSC flagint, 0
	CALL  inc_portA
	BTFSC flagint, 1
	call  dec_portA
	BTFSC flagint, 2
	call  INCVAR
	goto  loop
 
;---------------------------------SUBRUTINA-------------------------------------
    	
    Ntimer0:
	banksel TMR0		;Buscar timer 0 en el banco
	MOVLW   6		;Cargar el valor de N  a W
	MOVWF   TMR0		;Cargar el valor de W a Timer0
	BCF	INTCON, 2	;Limpiar bandera de INTCON
	RETURN

	
    INCVAR:
	BCF  flagint, 2
	call Ntimer0	;Reiniciar timer 0
	DECFSZ var500ms	;Decrementar variable de control de tiempo
	RETURN
	call inc_portb	;Llamar al incremento
	RETURN
	
    inc_portb:
	incf	condisp, F	    ;Incrementar el contador
	MOVLW	125	   	;Debido a que timer0 cuenta 8ms
	MOVWF	var500ms	;Definir el valor de la variable o reiniciarla
	btfsc	condisp, 4	    ;Si los 4 bits se encuentran encendidos resetear
	clrf	condisp
	MOVF	condisp, W	;Mover el numero deseado a W
	call	table0
	MOVWF	PORTD
	RETURN		    ;Regresar al loop*/

	
    inc_portA:
	clrf flagint
	incf PORTA, F	    ;Incrementar el contador
	btfsc PORTA,4	    ;Si los 4 bits se encuentran encendidos resetear
	clrf  PORTA	    ;Limpiar si se pasa de los 4 bits
	MOVF PORTA, 0	    ;Copiar el valor del contador para busacr en la tabla
	call table0	    ;Llamar en la tabla los bits que deben estar encendidos
	MOVWF PORTC	    ;Guardar en el port los bits para el display
	RETURN		    ;Regresar al loop

	
    dec_portA:
	clrf flagint
	decf PORTA, F	 ;Decrementar el puerto
	MOVLW 0x0F	;Cargar valor a W para cuando se decrementa de 0 a F hex
	btfsc PORTA, 7;Revisar si se encuentra el bit8 encendido
	MOVWF PORTA   ;Cargar W en puerto para que solo esten encendido 4 bits
	MOVF PORTA, 0	;Cargar el valor de la variable contador a W
	call table0	;Llamar a la tabla donde estan los bits para el display
	MOVWF PORTC	;Mover el valor de W a PORTD con los bits de la table
	RETURN
	
    

END


