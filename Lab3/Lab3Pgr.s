; Archivo: Lab3Pgr.s
; Dispositivo: PIC16F887
; Autor: Diego Mendez
; Compilador: pic-as (v2.30), MPLABX v5.40
; 
; Programa: Contador en timer0 
; Hardware: Push buttons puerto A, Display y Led
; 
; Creado: 15 feb, 2021
; Última modificación: 15 feb, 2021

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
	
	var500ms: DS 1 ; 1 byte
	flag: DS 1 ; 1 byte
	condisp: DS 1 ; 1 byte
	
	    
    
    PSECT resVect, class=CODE, abs, delta=2
;---------------------------VECTOR RESET--------------------------------------
   ORG 00h	;posicion 0000h para el reset
   resetVec:
	PAGESEL main
	goto main
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
	RETLW 01111100B ;6
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
	MOVLW 11111111B ;Designar valor de W a los puertos que deseo como inputs
	MOVWF	TRISA	;Mover el valor de W al TRISA
	MOVLW 11110000B
	MOVWF	TRISB
	clrf	TRISD	;Configurar puerto D
	
	banksel	PORTA	;Moverme al banco de los PORTS
	clrf	PORTB
	clrf	PORTD	;Colocar pines de D en 0
	
	banksel OPTION_REG  ;Configurar prescaler
	CLRWDT		    ;Limpiar WDT
	MOVLW	11000101B   ;Poner el prescaler en 32 y timer0
	MOVWF	OPTION_REG
	
	banksel OSCCON
	bsf	OSCCON,4  ;Colocamos la frecuencia a 8MHz
	bsf	OSCCON,5
	bsf	OSCCON,6
	bsf	SCS	  ; El reloj interno utiliza el oscilador interno
	
	call SETVAR	  ;Darle valor a la variable para que cuente 500ms
	call Ntimer0	  ;Colocar el valor N del timer, limpiar flag de INTCON
	clrf condisp	  ;Darle un valor a la variable del contador
	movlw 00111111B	  ;Darle un valor al puerto D 
	movwf PORTD, F
;--------------------------------LOOP-------------------------------------------
    loop:
	btfsc INTCON, 2
	call INCVAR
	btfsc var500ms, 7
	call inc_portb
	btfss PORTA, 0
	call antirrebote1
	btfsc PORTA,0
	call inc_portD
	btfss PORTA,1
	call antirrebote2
	btfsc PORTA,1
	call dec_portD
	call compare
	goto loop

;---------------------------------SUBRUTINA-------------------------------------
    	
    Ntimer0:
	banksel TMR0		;Buscar timer 0 en el banco
	MOVLW   131		;Cargar el valor de N  a W
	MOVWF   TMR0		;Cargar el valor de W a Timer0
	BCF	INTCON, 2	;Limpiar bandera de INTCON
	RETURN
    
    SETVAR:
	MOVLW	0		;Debido a que timer0 cuenta 2ms
	MOVWF	var500ms	;Definir el valor de la variable o reiniciarla
	BCF	PORTD, 7
	RETURN
	
    INCVAR:
	call Ntimer0	;Reiniciar timer 0
	INCF var500ms	;Incrementar variable de control de tiempo
	RETURN
	
    inc_portb:
	call Ntimer0
	incf PORTB, F	    ;Incrementar el contador
	call SETVAR
	btfsc PORTB, 4	    ;Si los 4 bits se encuentran encendidos resetear
	clrf  PORTB
	RETURN		    ;Regresar al loop
	
	
    antirrebote1:
	bsf flag,0  ;Levantar la bandera
	RETURN
	
    inc_portD:
	btfss flag,0	    ;antirrebote
	RETURN
	clrf flag
	incf condisp, F	    ;Incrementar el contador
	btfsc condisp,4	    ;Si los 4 bits se encuentran encendidos resetear
	clrf  condisp	    ;Limpiar si se pasa de los 4 bits
	MOVF condisp, 0	    ;Copiar el valor del contador para busacr en la tabla
	call table0	    ;Llamar en la tabla los bits que deben estar encendidos
	MOVWF PORTD	    ;Guardar en el port los bits para el display
	RETURN		    ;Regresar al loop

    antirrebote2:
	bsf flag,1  ;Levantar la bandera
	RETURN
	
    dec_portD:
	btfss flag,1
	RETURN
	clrf flag
	decf condisp, F	    ;Decrementar el puerto
	MOVLW 0x0F	;Cargar valor a W para cuando se decrementa de 0 a F hex
	btfsc condisp, 7;Revisar si se encuentra el bit8 encendido
	MOVWF condisp   ;Cargar W en puerto para que solo esten encendido 4 bits
	MOVF condisp, 0	;Cargar el valor de la variable contador a W
	call table0	;Llamar a la tabla donde estan los bits para el display
	MOVWF PORTD	;Mover el valor de W a PORTD con los bits de la table
	RETURN
	
    compare:
	MOVF condisp, W	    ;Mover el valor eb el que esta el display a W
	SUBWF PORTB, W	    ;Restarle al valor del puerto B, W
	btfss STATUS, 2	    ;Revisar si la bandera de 0 esta encendida
	RETURN		    ;Regresar si no esta encendida
	bsf PORTD,7	    ;Encender la luz led de alarma
	clrf PORTB	    ;Limpiar el contador del timer si esta encendida
	RETURN		    

END


