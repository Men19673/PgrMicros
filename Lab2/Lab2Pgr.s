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
	    cont_small: DS 1 ; 1 byte
	    cont_big:	DS 1 
    
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
	
	
	MOVLW 11111111B ;Designar valor de W a los puertos que deseo como inputs
	
	banksel	TRISA
	
	MOVWF	TRISA	;Mover el valor de W al TRISA
	clrf	TRISB	;Configurar los puertos B,C,D como salidas
	clrf	TRISC
	clrf	TRISD
	
	banksel	PORTA	
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
	goto loop

;---------------------------------SUBRUTINA-------------------------------------
    	
    inc_portb:
	btfsc PORTA, 0
	goto  $-1
	call delay_small
	btfsc PORTA, 0
	goto loop
	incf PORTB, F
	goto loop
    
    dec_portb:
	btfsc PORTA, 1
	goto  $-1
	call delay_small
	btfsc PORTA, 1
	goto loop
	decf PORTB, F
	goto loop
	
    inc_portc:
	btfsc PORTA, 2
	goto  $-1
	call delay_small
	btfsc PORTA, 2
	goto loop
	incf PORTC, F
	goto loop
	
    dec_portc:
	btfsc PORTA, 3
	goto  $-1
	call delay_small
	btfsc PORTA, 3
	goto loop
	decf PORTC, F
	goto loop
    
	
    
    delay_big:
	movlw   200		    ;valor inicial del contador
	movwf   cont_big
	call    delay_small	    ;rutina del delay 
	decfsz  cont_big, 1	    ;decrementar el contador
	goto    $-2		    ; ejecutar las lineas de atras
	return

    delay_small:
	movlw   250		    ;valor inicial del contador
	movwf   cont_small
	decfsz  cont_small, 1	    ;decrementar el contador
	goto    $-1		    ; ejecutar las lineas de atras
	return

return


