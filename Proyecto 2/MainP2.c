/*
 * Archivo: Lab10.c
 * Dispositivo: PIC16F887
 * Autor: Diego Mendez
 * Compilador: XC8 (v2.32), MPLABX v5.40
 * Programa: Utilizando USART
 * Hardware: Potenciometros en A, servos en ccp1 y ccp2
 * Created on April 26, 2021, 6:10 PM
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
void chselect (void); //Canal
void ctrservo (void); //Control del servo
/********************************TABLA*****************************************/

/*uint8_t table(uint8_t val){
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
*/
/********************************Variables*************************************/
/*uint8_t flagint;
uint8_t centenas;
uint8_t decenas;
uint8_t unidades;
uint8_t valor;
uint8_t disp0;
uint8_t disp1;
uint8_t disp2;
uint8_t multiplex;
uint8_t var0;
uint8_t var1;*/
/********************************Interrupcion**********************************/
void __interrupt()isr(void){
  
  /*  if (T0IF==1){ 
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
    }*/
    
   /* if(PIR1bits.ADIF){
        if(ADCON0bits.CHS == 0){    //Ver canal 0
            var0 = ADRESH;     //Mover a leds
        }
        else{                   //ver canal 1
            var1 = ADRESH;       //Guardar en variable para display
        }
        PIR1bits.ADIF = 0;
    }
   
    if (PIR1bits.TMR2IF ==1){ 
        PIR1bits.TMR2IF = 0; 
  }*/
    
    
    if(RCIF == 1){
        PORTB = RCREG;
    }
}
/****************************** MAIN ******************************************/
void main(void) {
    setup();
    //ADCON0bits.GO = 1; //Activar el protocolo de lectura de pines

/****************************** LOOP ******************************************/
while(1) {
   if(TXIF == 1){
        TXREG = 97; //Enviar @
    }
   __delay_ms(500);
    /*chselect();
    ctrservo();*/
    }
}


/********************************Subrutinas************************************/
void setup(void){
  
  ANSEL = 0b00000000;  //Apagar analogo
  ANSELH = 0b00000000;
  
  TRISA = 0b00000000;     //Output     
  TRISB = 0b00000000;//Output excepto por pin 0 y 1    
  TRISC = 0b10000000;     //Output bit 7 recibe SERIAL
  TRISD = 0x00;     //Output
  TRISE = 0x00;     //Output
  


  //Timer0
  OPTION_REG = 0b11000100; //prescaler en 32, activar PULLUP y WDT en timer0
  //TMR0		 = 100;
  
  //Timer2 -- 20 ms TMR2 Preload = 250; 
  /*T2CON	 = 0x26;        //Prescaler 1:16; TMR2 ON, Postscaler 1:5;   
  PR2    = 250;*/
  
  
 //ADC
  /*ADCON0bits.CHS= 1;
  __delay_us(100);
  
  ADCON0bits.ADON = 1;      //Activar modulo
  ADCON0bits.ADCS = 1;      //ADC clock Fosc/8
  ADCON1bits.ADFM = 0;      //Justificado derecho
  ADCON1bits.VCFG0 = 0;     //Referencia alta es VCC
  ADCON1bits.VCFG1 = 0;     //Referencia baja es Ground*/
  
  //Osccon
  OSCCONbits.IRCF = 0b110; //Oscilador 4MHZ
  OSCCONbits.SCS = 1;   //utilizar oscilador interno para reloj del sistema
 
 //CCP1 Y CCP2
  /*CCP1CON = 0b00001100; //Single Output; XX; PWM P1A
  CCP2CON = 0b00001100; //XX, PWM 1100*/
  
 //CONFIG EUSART
  
  //TX CONFIG
  TXSTAbits.SYNC = 0;       //Modo Asincrono
  TXSTAbits.BRGH = 1;       //HIGH SPEED
  TXSTAbits.TX9 = 0;       //Desactivar envio de 9 bits
  TXSTAbits.TXEN= 1;        //Encender TX
  RCSTAbits.SPEN = 1;       //Activar Serial PORT
  
  //RX CONFIG
  RCSTAbits.RX9 = 0;        //Desactivar recepcion de 9 bits
  RCSTAbits.CREN = 1;       //Activa la recepcion continua 
  
  //BAUD RATE CONTROL
    BAUDCTLbits.BRG16 = 0;  //Generador de 8bits activo)
    SPBRG =25;
    SPBRGH = 1;
   
  
  //Interrupciones
  INTCON = 0b11000000;  //GIE, PIE, toie, inte, rbie, t0if, intf, rbif
  PIE1 = 0b00100000; // 0, adie, RCIE, txie, sspie, ccp1ie, tmr2, tmr1
  PIE2 = 0b00000000; // osfie, c2ie, c1ie, eeie, bclie, 0, ccpie2
  
  //Limpieza profunda
  
  PORTA = 0x00;
  PORTB = 0x00;
  PORTC = 0x00; //Poner todos los puertos en 0
  PORTD = 0x00;
  PORTE = 0x00;
  PIR1 = 0x00; //Limpiar banderas
  PIR2 = 0x00;
  //TRISC = 0b00000000; //PONER EN OUTPUT PORTC PARA USAR PWM
}
/*void dispasign(uint8_t arg1, uint8_t arg2, uint8_t arg3){
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

void ctrservo (void) {
    CCPR1L = ((0.247 * var0) + 62);
    CCPR2L = ((0.247 * var1) + 62);
}

void chselect (void){
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
}*/