/*
 * Archivo: Lab8.c
 * Dispositivo: PIC16F887
 * Autor: Diego Mendez
 * Compilador: XC8 (v2.32), MPLABX v5.40
 * Programa: Utilizando Interrupts, un contadores decimales y luces
 * Hardware: Potenciometros en A, 1Displays y Leds
 * Created on April 19, 2021, 6:10 PM
 */
#include <xc.h>
#include <stdint.h>

/***************************Configuration Words********************************/
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (RC oscillator: 
                                // CLKOUT function on RA6/OSC2/CLKOUT pin, 
                                // RC on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and
                                // can be enabled by SWDTEN bit of the WDTCON
                                //register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR 
                                // pin function is digital input, MCLR 
                                // internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code 
                                // protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code 
                                // protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/
                                // External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit 
                                // (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit 
                                // (RB3 pin has digital I/O, HV on MCLR must be 
                                // used for programming)
// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out 
                                // Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits
                                // (Write protection off)


#define _XTAL_FREQ      4000000 //Definir la frecuencia de operacion

/******************************Prototipos**************************************/

void setup(void);   //Anunciar funcion setup
void decimal(uint8_t); //Funcion de restas
uint8_t table(uint8_t);     //Funcion tabla
void dispasign(uint8_t, uint8_t, uint8_t);//Funcion donde pasa por tabla y regresa valor para display
/********************************TABLA*****************************************/

uint8_t table(uint8_t val){
    uint8_t tempo;
    
    switch(val){
        case 0:
            tempo = 0b00111111;
            break;
            
        case 1:
            tempo = 0b00000110;
            break;
            
        case 2:
            tempo = 0b01011011;
            break;
            
        case 3:
            tempo = 0b01001111;
            break;
       
        case 4:
            tempo = 0b01100110;
            break;
            
        case 5:
            tempo = 0b01101101;
            break;
        
        case 6:
            tempo = 0b01111101;
            break;
        
        case 7:
            tempo = 0b00000111;
            break;
        
        case 8:
            tempo = 0b01111111;
            break;
            
        case 9:
            tempo = 0b01100111;
            break;
        
        default:
            tempo = 0b00111111;
    }
    return(tempo);
}

/********************************Variables*************************************/
uint8_t flagint;
uint8_t centenas;
uint8_t decenas;
uint8_t unidades;
uint8_t valor;
uint8_t disp0;
uint8_t disp1;
uint8_t disp2;
uint8_t multiplex;
uint8_t var;
/********************************Interrupcion**********************************/
void __interrupt()isr(void){
  
    if (T0IF==1){ 
    TMR0		 = 100;         //Resetear timer0
    INTCONbits.T0IF = 0; 
    PORTB = 0x00;
    switch(multiplex){      //Multiplexado de las displays 
        case 0:
            PORTC = disp0;
            RB4 = 1;
            multiplex++;
            break;
            
        case 1:
            PORTC = disp1;
            RB5 = 1;
            multiplex++;
            break;
            
        case 2:
            PORTC = disp2;
            RB6 = 1;
            multiplex = 0x00;
            break;
        }       
    }
    
    if(PIR1bits.ADIF){
        if(ADCON0bits.CHS == 0){    //Ver canal 0
            PORTD = ADRESH;     //Mover a leds
        }
        else{                   //ver canal 1
            var = ADRESH;       //Guardar en variable para display
        }
        PIR1bits.ADIF = 0;
    }
    
    
}
/****************************** MAIN ******************************************/
void main(void) {
    setup();
    ADCON0bits.GO = 1; //Activar el protocolo de lectura de pines

/****************************** LOOP ******************************************/
while(1) {
    if(ADCON0bits.GO == 0){
        if(ADCON0bits.CHS == 0){
            ADCON0bits.CHS = 1;        //Cambiar a canal 1
        }
        else{
            ADCON0bits.CHS = 0;        //Cambiar a canal 0
            
        }
        __delay_us(150);
        ADCON0bits.GO = 1;
    }
    
    decimal(var);
    dispasign(centenas, decenas, unidades);
    }
}


/********************************Subrutinas************************************/
void setup(void){
  
  ANSEL = 0b00000011;  //Apagar analogo
  ANSELH = 0b00000000;
  
  TRISA = 0b00000011;     //Output     
  TRISB = 0b00000000;//Output excepto por pin 0 y 1    
  TRISC = 0x00;     //Output
  TRISD = 0x00;     //Output
  TRISE = 0x00;     //Output
  
 
  ADCON0bits.CHS= 1;
  __delay_us(100);
  
  ADCON0bits.ADON = 1;      //Activar modulo
  ADCON0bits.ADCS = 1;      //ADC clock Fosc/8
 
  
  
  ADCON1bits.ADFM = 0;      //Justificado derecho
  ADCON1bits.VCFG0 = 0;     //Referencia alta 
  ADCON1bits.VCFG1 = 0;     //Referencia baja

  OPTION_REG = 0b11000100; //prescaler en 32, activar PULLUP y WDT en timer0
  TMR0		 = 100;
  
  
  OSCCONbits.SCS = 1;   //utilizar oscilador interno para reloj del sistema
 
  PORTA = 0x00;
  PORTB = 0x00;
  PORTC = 0x00; //Poner todos los puertos en 0
  PORTD = 0x00;
  PORTE = 0x00;
  INTCON = 0b11101000;
  PIE1 = 0b01000000;
  PIR1 = 0x00; //Limpiar banderas
}
void dispasign(uint8_t arg1, uint8_t arg2, uint8_t arg3){
    disp0 = table(arg1);
    disp1 = table(arg2); //Convertimos de numero binario al compatible con
    disp2 = table(arg3);//el display
    
}
void decimal(uint8_t variable){
    valor = variable;              //guardar el valor del port
    centenas = valor/100;       //dividir entre 100 para centenas
    valor = (valor - (centenas*100));
    decenas = valor/10;         //dividir entre 10 para decenas
    valor = (valor - (decenas*10));
    unidades = valor/1;         //dividir entre 1 para unidades
    
}