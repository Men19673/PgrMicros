; Archivo: Lab6Pgr.s
; Dispositivo: PIC16F887
; Autor: Diego Mendez
; Compilador: pic-as (v2.30), MPLABX v5.40
; 
; Programa: Utilizando Interrupts, un contador hex 
; Hardware: Displays multiplexadas y un led
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
	W_Temp:	    DS 1; 1 byte
	STAT_Temp:  DS 1; 1 byte
	flagint:    DS 1; 1 byte 
	flagnum:    DS 1; 1 byte
	centenas:   DS 1; 1 byte
	decenas:    DS 1; 1 byte
	unidades:   DS 1; 1 byte
	varbin:	    DS 1; 1 byte
	varconteo:  DS 1; 1 byte
	oneseg:	    DS 1; 1 byte
	twofive:    DS 1; 1 byte
    
    GLOBAL flagint, condisp, selec_disp, W_Temp, STAT_Temp
    GLOBAL varbin, flagnum, decenas, unidades, oneseg
	
	    
    
    
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
   timer2flag:
    banksel  PIR1
    BCF	     PIR1, 1
    DECFSZ  twofive	; Contamos 10 para que sea 10 x 25 asi 250ms
    RETURN
    MOVLW   10
    MOVWF   twofive	;Ingresar el valor 10
    BSF	    flagint, 4	;Encender bandera externa
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
    BSF	    flagint, 2	;Encender una bandera externa
    call    Ntimer0	;Reiniciar el timer0
    btfss   flagnum, 0
    call    dispoff
    btfsS   flagnum, 0
    RETURN
    clrf    PORTD	;Limpiar el selector de pantalla
    btfsc   selec_disp, 0   ;Ver si la display pasada fue la 4
	goto    display1	    

   display0:
	MOVF    condisp, W	    ;Mover el valor de la variable al PORT
	MOVWF   PORTC
	BSF	PORTD,0	    ;Encender el display 0
	BSF   selec_disp, 0		    ;Proximo interrupt ir a display1
	RETURN	    

   display1:
	BCF	selec_disp, 0   ;Limpiar bandera de display 1
	MOVF    condisp+1, W    ;Mover el valor de la variable al port
	MOVWF   PORTC	    
	BSF	PORTD,1	    ;Encender el display 1
	clrf    selec_disp		   ;Proximo interrupt ir a display2
	RETURN
    
   dispoff:
	BSF  PORTD, 0
	BCF  PORTD, 1
	clrf PORTC
	BSF  PORTD, 1
	BCF  PORTD, 0
	clrf PORTD
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
	
	banksel	TRISA	 ;Buscar banco del TRIS
	BCF	TRISA, 0 ;Mover el valor de W al TRISA
	clrf	TRISC	 ;Configurar puerto C
	clrf	TRISD	 ;Configurar puerto D
	
	
	BSF INTCON, 7	;Activar global Int
	BSF INTCON, 6
	BSF INTCON, 5	;Timer0 INt
	
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
	bsf	PIE1, 1	    ;ctivar Interrupt Timer 2
	MOVLW	223	    ;Valor para el comparator
	MOVWF	PR2	    ;Guardar
	
	CLRWDT		    ;Limpiar WDT
	MOVLW	11000001B   ;Poner el prescaler en 1:4, y WDT en timer0
	MOVWF	OPTION_REG
	
	
	banksel OSCCON
	bsf	OSCCON,0    ; El reloj interno utiliza el oscilador interno
	
	banksel PORTA
	MOVLW 00111111B	  ;Darle un valor al puerto D
	MOVWF PORTC
	
	
	clrf condisp	    ;Limpiar todas las variables
	clrf flagnum
	clrf decenas
	clrf unidades
	clrf varbin
	MOVLW  10
	MOVWF  oneseg
	MOVWF  twofive
	
;--------------------------------LOOP-------------------------------------------
    loop:
		
	BTFSC flagint, 3	;Verificar si la bandera deTimer 1
	call  inc_var		;Incrementar contador
	call  disp_refresh	;preparar para un refresh
	
	
	BTFSS flagnum, 1	;Revisar banderas de terminar decenas
	call resdec
	BTFSS flagnum, 2	;Revisar banderas de terminar unidades
	call resun
	
		
	BTFSC	flagint, 4	;Hacer el titileo
	call	titileo
	
	
	goto  loop
 
;---------------------------------SUBRUTINA-------------------------------------
    	
    dispmultiplex:
	

	
    disp_refresh:
	BCF	flagint, 2  ;Limpiar bandera de que hubo un int por el Timer0
	MOVF	decenas, W   
	call	table0	    ;Buscar el nibble menos significativo en la tabla 
	MOVWF	condisp	    ;Guardar en el condisp
	
	MOVF	unidades, W  
	call	table0	    ;Buscar el nibble mas significativo en la tabla
	MOVWF	condisp+1   ;Guardar en el segundo byte de condisp
	

	RETURN

	
    inc_var:
	bcf flagint, 3
	clrf flagnum
	clrf decenas	    ;Limpiar contador
	clrf unidades    ;Limpiar contador
	incf varconteo, F   ;Incrementar el contador
	MOVF varconteo, W   
	XORLW 0x64	    ;Revisar si ya llego a 99
	BTFSC	STATUS, 2
	clrf varconteo
	MOVF varconteo, W
	MOVWF varbin, F
	RETURN		    ;Regresar al loop
	
    titileo:
	bcf	flagint, 4
	clrf	PORTC
	bsf	PORTD, 0
	bsf	PORTD, 1
	BTFSC	flagnum, 0
	    goto lightoff
    lighton:
	bsf PORTA,0 
	bsf flagnum, 0
	RETURN
    lightoff:
	bcf  PORTA, 0
	bcf  flagnum,0
	RETURN
	
    resdec:
	BSF	flagnum, 2
	MOVLW	10
	SUBWF	varbin, F   ;Restar 10 al valor
	btfsc	STATUS, 0   ;Revisar si ocurrio un borrow
	INCF	decenas	    ;Incrementar el contador de decenas
	
	btfss	STATUS,	0   ;Revisar si ocurrio un borrow
	BSF	flagnum, 1  ;Levantar la bandera
	btfss	STATUS, 0   ;Encender la resta de unidades
	BCF	flagnum,2
	
	btfss	STATUS, 0
	ADDWF	varbin	    ;Sumar 10 al valor para no perder el numero 
	
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


