; Archivo: Lab1.s
; Dispositivo: PIC16F887
; Autor: Diego Mendez
; Compilador: pic-as (v2.30), MPLABX v5.40
; 
; Programa: contador en el puerto A
; Hardware: LEDs en el puerto A
; 
; Creado: 2 feb, 2021
; Última modificación: 2 feb, 2021

PROCESSOR 16F887
#include<xc.inc>
;------------------------- CONFIGURATION WORDS----------------------------------

    ; config 1
	CONFIG FOSC=INTRC_NOCLKOUT //OSCILADOR INTERNO SIN SALIDAS
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
	bsf STATUS, 5   ; banco 11
	bsf STATUS, 6
	clrf ANSEL	    ;pines digitales
	clrf ANSELH

	bsf STATUS, 5   ; banco 01 
	bcf STATUS, 6

	clrf TRISA	    ; port A como salida

	bcf STATUS, 5   ; banco 00
	bcf STATUS, 6   
    
;--------------------------------LOOP-------------------------------------------
    loop:
	incf PORTA, 1
	call delay_big
	goto loop

;---------------------------------SUBRUTINA-------------------------------------
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