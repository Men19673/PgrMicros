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

uint8_t table(uint8_t);     //Funcion tabla

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

uint8_t valor;
uint8_t var0;
uint8_t var1;
uint8_t var2;
uint8_t var3;
uint8_t var4;
unsigned char  str[96] = " Que accion desea ejecutar?\r(1)Desplegar cadena de caracteres\r(2)Cambiar PORTA\r(3)Cambiar PORTB\0";
unsigned char  cad[26] = " \rBienvenido, como estas?\r";
unsigned char  car[24] = " \rQue caracter desea?\r";
/********************************Interrupcion**********************************/
void __interrupt()isr(void){
 
    
}
/****************************** MAIN ******************************************/
void main(void) {
    setup();
    var0 = 0;

/****************************** LOOP ******************************************/
while(1) {
    
    if (var0 == 0){
       if(var1 <= 96){      //verficar que no pase del limite 
           var1++;          //Ir cambiando de character
       }
       else{
            if(RCIF == 1){
                        var0 = RCREG; //Asignar el valor de selector de accion  
            }
       }       
       if(TXIF == 1){
        TXREG = str[var1]; //Enviar a terminal palabras
       }
        __delay_ms(100);
    }
    
   //Cadena de caracteres
    if (var0 == 49){
       if(var2 <= 26){
           var2++;          //Ir cambiando de character
       }
       else {
           var0=0;
           var1=0;
           var2=0;
       }
       if(TXIF == 1){
        TXREG = cad[var2]; //Enviar a termial palabras
       }
        __delay_ms(100);
    }
    //PORTA
     if (var0 == 50){
       if(var3 <= 24){
           var3++;          //Ir cambiando de character
       }
       else {
          while(RCIF == 0){ //Esperar a valor 
           }
          if(RCIF ==1){
             PORTA = RCREG; //Asignar el valor a una variable   
            } 
           
           var0=0;
           var1=0;
           var2=0;
           var3=0;
           var4=0;
       }
       if(TXIF == 1){
        TXREG = car[var3]; //Enviar a termial palabras
       }
        __delay_ms(100);
    }
    //PORTB
    if (var0 == 51){
       if(var4 <= 24){
           var4++;          //Ir cambiando de character
       }
       else {
          while(RCIF == 0){ //Esperar el valor 
           }
          if(RCIF ==1){
             PORTB = RCREG; //Asignar el valor a una variable   
            } 
           var0=0;
           var1=0;
           var2=0;
           var3=0;
           var4=0;
       }
       if(TXIF == 1){
        TXREG = car[var4]; //Enviar a termial palabras
       }
        __delay_ms(100);
    }
    
    
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
  
  
  //Osccon
  OSCCONbits.IRCF = 0b110; //Oscilador 4MHZ
  OSCCONbits.SCS = 1;   //utilizar oscilador interno para reloj del sistema
 
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
  INTCON = 0b00000000;  //GIE, PIE, toie, inte, rbie, t0if, intf, rbif
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
  
}
