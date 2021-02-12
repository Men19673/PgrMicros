; Archivo: Lab2Pgr.s
; Dispositivo: PIC16F887
; Autor: Diego Mendez
; Compilador: pic-as (v2.30), MPLABX v5.40
; 
; Programa: contador 
; Hardware: Push buttons puerto A, leds puertos B,C,D
; 
; Creado: 9 feb, 2021
; Última modificación: 9 feb, 2021

PROCESSOR 16F887
#include<xc.inc>
;------------------------- CONFIGURATION WORDS----------------------------------

    ; config 1
	CONFIG FOSC=XT //OSCILADOR EXTERNO
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
	    
    
    PSECT resVect, class=CODE, abs, delta=2
;---------------------------VECTOR RESET--------------------------------------
   ORG 00h	;posicion 0000h para el reset
   resetVec:
	PAGESEL main
	goto main

   PSECT code, delta=2, abs
   ORG 100h ; posicion para el codigo
    
;----------------------------------CONFIGURACION--------------------------------
   
    main:
	banksel ANSEL
	clrf	ANSEL	;Configurar los puertos como digitales
	clrf	ANSELH
	
	
	MOVLW 00011111B ;Designar valor de W a los puertos que deseo como inputs
	
	banksel	TRISA
	
	MOVWF	TRISA	;Mover el valor de W al TRISA
	
	
	clrf	TRISB	;Configurar los puertos B.
	clrf	TRISC
	clrf	TRISD
	
	banksel	PORTA	;Moverme al banco de los PORTS
	clrf	PORTB	;Colocar los puertos en 0
	clrf	PORTC
	clrf	PORTD
	
    
;--------------------------------LOOP-------------------------------------------
    loop:
	btfss PORTA, 0
	call inc_portb
	btfss PORTA, 1
	call dec_portb
	btfss PORTA, 2
	call inc_portc
	btfss PORTA, 3
	call dec_portc
	btfss PORTA, 4
	call result
	goto loop

;---------------------------------SUBRUTINA-------------------------------------
    	
    inc_portb:
	btfss PORTA, 0	    ;Revisar si el boton sigue apachado o no
	goto $-1	    ;Esperar a que se deje de apachar
	incf PORTB, F	    ;Incrementar el contador
	btfsc PORTB, 4	    ;Si los 4 bits se encuentran encendidos resetear
	clrf  PORTB
	RETURN		    ;Regresar al loop
    
    dec_portb:
	btfss PORTA, 1	  ;Revisar que se haya dejado de apacahar
	goto $-1	  ;Regresar al anterior
	decf PORTB, F	  ;Decrementar el puerto
	MOVLW 0x0F	  ;Cargar valor a W para cuando se decrementa de 0 a F hex
	btfsc PORTB, 7	  ;Revisar si se encuentra el bit8 encendido
	MOVWF PORTB	  ;Cargar W en puerto para que solo esten encendido 4 bits
	RETURN
	
    inc_portc:
	btfss PORTA, 2	    ;Revisar que se haya dejado de apacahar
	goto $-1	    ;Regresar al anterior
	incf PORTC, F	    ;Incrementar el contador
	btfsc PORTC,4	    ;Si los 4 bits se encuentran encendidos resetear
	clrf  PORTC
	RETURN		    ;Regresar al loop
	
    dec_portc:
	btfss PORTA, 3	    ;Revisar que se haya dejado de apacahar
	goto $-1	    ;Regresar al anterior
	decf PORTC, F	    ;Decrementar el puerto
	MOVLW 0x0F	    ;Cargar valor a W para cuando se decrementa de 0 a F hex
	btfsc PORTC, 7	    ;Revisar si se encuentra el bit8 encendido
	MOVWF PORTC	    ;Cargar W en puerto para que solo esten encendido 4 bits
	RETURN
    
	
    result:
	btfss	PORTA, 4  ;Revisar si Boton de Resultado ya no esta presionado
	goto	$-1
	MOVF	PORTB ,0  ;Cargar Port B en W
	ADDWF   PORTC ,0  ;Sumar W con PORTC y guardar en W
	MOVWF	PORTD
	RETURN

RETURN