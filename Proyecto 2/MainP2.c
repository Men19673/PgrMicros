/*
 * Archivo: Proyecto2.c
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
void extraservo(void);
void chselect (void); //Canal
void ctrservo (void); //Control del servo
void record(void);
uint8_t writeEEPROM(uint8_t, uint8_t);
uint8_t readEEPROM(uint8_t);
void play(void);
/********************************Variables*************************************/
uint8_t flagint;
uint8_t valor;
uint8_t RXREC;
uint16_t contpwm;
uint8_t order;
uint8_t orderp;
uint8_t multiplex;
uint8_t varUART;
uint8_t varUART2;
uint8_t var0;
uint8_t var1;
uint8_t var2;
uint8_t var3;
uint16_t PWMEX;
uint16_t PWMEX2;
char grabar = 114;
char reproducir = 112;
unsigned char  str[77] = " \nQue accion desea ejecutar?\n(r)Guardar posicion\n(p)Reproducir posiciones \n";
unsigned char  pos1[28] = " \nSe encuentra en posicion 1\n";
unsigned char  pos2[28] = " \nSe encuentra en posicion 2\n";
unsigned char  pos3[28] = " \nSe encuentra en posicion 3\n";

/********************************Interrupcion**********************************/
void __interrupt()isr(void){
  
  if (T0IF==1){ 
                
        contpwm++; //Contador 
        if (contpwm <= PWMEX) {
            RC3=1; //Encender el pin 
        }  
        else {      //Apagar el pin cuando pasa de la cantidad PWMEX
            RC3=0;
        } 
        
        if (contpwm <= PWMEX2) {    //Lo mismo que el anterior
            RC4=1;
        }  
        else {
            RC4=0;
        } 
        
       if (contpwm >=250){      //Contar hasta 20ms y reiniciar el perido
           contpwm=0;
       }
        TMR0     = 176; //Reinciar Timer 0 y apagar la bandera
        T0IF	 = 0;
    }
 
        

    if(PIR1bits.ADIF){
        switch (ADCON0bits.CHS){    //Switch para lectura de analogicos
         case (0):
            var0 = ADRESH;          //Asignacion de las variables segun el canal
            break;
           
         case (1):
            var1= ADRESH;           
            break;
            
         case (2):
            var2= ADRESH;
            break;
            
         case (3):
            var3 = ADRESH;
            break;
        }     
       PIR1bits.ADIF = 0;
    }
   
     if(PIR1bits.TMR2IF ==1){ 
        PIR1bits.TMR2IF = 0; //Apagar la bandera del timer 2
    }
    
    if(PIR1bits.RCIF == 1){
        RXREC = RCREG;      //Guardar el dato que se recibe en uart 
    }
}
/****************************** MAIN ******************************************/
void main(void) {
    setup();
    ADCON0bits.GO = 1; //Activar el protocolo de lectura de pines
    varUART =0;
/****************************** LOOP ******************************************/
while(1) {
      
    
    chselect();
    ctrservo();
    if (RXREC == 0){
        
       while(varUART <= 75){      //verficar que no pase del limite 
           varUART++;          //Ir cambiando de character
                   
       if(TXIF == 1){
        TXREG = str[varUART]; //Enviar a terminal palabras
       }
        __delay_ms(15);
     }
    }
    
    if(RXREC == grabar){ //Si se apacha la r en la terminar grabar valores
        record();
    }
    if(RXREC == reproducir){    //Si se apacha p en terminar reproducir valores
        play();
    }
   }
}


/********************************Subrutinas************************************/
void setup(void){
  
  ANSEL = 0b00001111;  //Encender analogo
  ANSELH = 0b00000000;
  
  TRISA = 0b00001111;     //Output     
  TRISB = 0b00000000;//Output excepto  
  TRISC = 0b10000110;     //Output bit 7 recibe SERIAL
  TRISD = 0x00;     //Output
  TRISE = 0x00;     //Output
  


  //Timer0 0.08ms
  OPTION_REG = 0x88; //prescaler en 1:1, desactivar PULLUP y WDT en timer0
  TMR0		 = 176;

  //Timer 1
  //T1CON	 = 0x00; //prescaler 1:1
  //TMR1IF = 0;
  //TMR1H	 = 0xFC;
  //TMR1L	 = 0x18;
  //0.01ms
  //TMR1H	 = 0xFF;
  //TMR1L	 = 0xF6;


  //Timer2 20ms
  T2CON	 = 0x26;        //Prescaler 1:16; TMR2 ON, Postscaler 1:5;   
  PR2	 = 250;
  PIR1bits.TMR2IF = 0;  
  
 //ADC
  ADCON0bits.CHS= 1;
  __delay_us(100);
  
  ADCON0bits.ADON = 1;      //Activar modulo
  ADCON0bits.ADCS = 1;      //ADC clock Fosc/8
  ADCON1bits.ADFM = 0;      //Justificado derecho
  ADCON1bits.VCFG0 = 0;     //Referencia alta es VCC
  ADCON1bits.VCFG1 = 0;     //Referencia baja es Ground*/
  PIR1bits.ADIF = 0;           // Limpiar bandera  ADC
  //Osccon
  OSCCONbits.IRCF = 0b110; //Oscilador 4MHZ
  OSCCONbits.SCS = 1;   //utilizar oscilador interno para reloj del sistema
 
 //CCP1 Y CCP2
  CCP1CON = 0b00001100; //Single Output; XX; PWM P1A
  CCP2CON = 0b00001111; //XX, PWM 1100
  
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
  INTCON = 0b11100000;  //GIE, PIE, TOIE, inte, rbie, t0if, intf, rbif
  PIE1 = 0b01100010; // 0, ADIE, RCIE, txie, sspie, ccp1ie, TMR2, tmr1
  PIE2 = 0b00000000; // osfie, c2ie, c1ie, eeie, bclie, 0, ccpie2
  
  //Limpieza profunda
  
  PORTA = 0x00;
  PORTB = 0x00;
  PORTC = 0x00; //Poner todos los puertos en 0
  PORTD = 0x00;
  PORTE = 0x00;
  PIR1 = 0x00; //Limpiar banderas
  PIR2 = 0x00;
  TRISC = 0b10000000; //PONER EN OUTPUT PORTC PARA USAR PWM
  //T1CON = 0x01;
}


void ctrservo (void) {
   CCPR1L = ((0.247 * var1) + 62); //Ecuaciones de mapeo para los servos 
   CCPR2L = ((0.247 * var0) + 62);
   PWMEX = ((0.049* var2)+7);
   PWMEX2= ((0.049 * var3)+7);
   
    
    
}

void chselect (void){
    if(ADCON0bits.GO == 0){
       
        switch (ADCON0bits.CHS){
         case (0):
             ADCON0bits.CHS = 1;        //Cambiar a canal 1
            break;
           
         case (1):
             ADCON0bits.CHS = 2;        //Cambiar a canal 2
            break;
            
         case (2):
            ADCON0bits.CHS = 3;        //Cambiar a canal 3
            break;
            
         case (3):
            ADCON0bits.CHS = 0;        //Cambiar a canal 0
            break;
        }     
       
            __delay_us(150);
            ADCON0bits.GO = 1;
    }
}

void record(void){
    RXREC = 0;
    
    switch (order){
        case (0): //Guardar los valores para posición 1
            writeEEPROM(0x00, var0);
            writeEEPROM(0x01, var1);
            writeEEPROM(0x02, var2);
            writeEEPROM(0x03, var3);
            order=1;
            RD0 =1; //encender led para avisar ocupacion del espacio 1
            break;
        case (1): //Guardar los valores para posicion 2
            writeEEPROM(0x04, var0);
            writeEEPROM(0x05, var1);
            writeEEPROM(0x06, var2);
            writeEEPROM(0x07, var3);

            order=2;
            RD1 =1;
            break;
        case (2): //Guardar los valores para posicion3 
            writeEEPROM(0x08, var0);
            writeEEPROM(0x09, var1);
            writeEEPROM(0x0A, var2);
            writeEEPROM(0x0B, var3);

            order=3;
            RD2 =1; //Encender led para posicion 3 guardada
            break;
        case (3): 
            order=0;
            RD0 =0;
            RD1 = 0;
            RD2 = 0; //Reiniciar
            break;
    
    }
    
}

void play(void){
    RXREC = 0;
    
    switch (orderp){
        case (0): //Reproducir Grabacion 1
            varUART2 =0;            //Limpiar contador para UART
            ADCON0bits.ADON = 0; //Apagar la lectura de los pines analogicos
            
            var0 = readEEPROM(0x00);
            var1 = readEEPROM(0x01);
            var2 = readEEPROM(0x02);//Asiganr valor a las variables para hacer 
            var3 = readEEPROM(0x03);//PWM
            orderp=1;
            
            while (varUART2 <= 26){
                varUART2++; //Ir cambiando de caracter
                 if(TXIF == 1){
                    TXREG = pos1[varUART2]; //Enviar a terminal palabras
                   }
                __delay_ms(15);
            }
            break;
            
        case (1): //Reproducir Grabacion 2
            varUART2 =0;            //Limpiar contador para UART
            var0 = readEEPROM(0x04);
            var1 = readEEPROM(0x05);
            var2 = readEEPROM(0x06);
            var3 = readEEPROM(0x07);
            orderp=2;
           
            while (varUART2 <= 27){
                varUART2++; //Ir cambiando de caracter
                 if(TXIF == 1){
                    TXREG = pos2[varUART2]; //Enviar a terminal palabras
                   }
                __delay_ms(15);
            }
            break;
            
        case (2): // Reproducir Grabacion 3
            varUART2 =0;            //Limpiar contador para UART
            var0 = readEEPROM(0x08);
            var1 = readEEPROM(0x09);
            var2 = readEEPROM(0x0A);
            var3 = readEEPROM(0x0B);
            orderp=3;
            
            while (varUART2 <= 26){
                varUART2++; //Ir cambiando de caracter
                 if(TXIF == 1){
                    TXREG = pos3[varUART2]; //Enviar a terminal palabras
                   }
                __delay_ms(15);
            }
            break;
            
        case (3):
            ADCON0bits.CHS= 1; //Salir del modo reproducir
             __delay_us(200);
            ADCON0bits.ADON = 1;      //Activar modulo ADC de nuevo
            orderp = 0;
            varUART = 0; //Limpiar bandera de menu principal
            break;

}
}
    
uint8_t writeEEPROM(uint8_t address, uint8_t data){
    EEADR = address; //Ingresar la direccion
    EEDAT = data;    //Escribir el Dato
    
    EECON1bits.EEPGD = 0; //Access Data Memory
    EECON1bits.WREN = 1;  //Write enable
    
    INTCONbits.GIE = 0;   //Apagar las interrupciones
    
    EECON2 = 0x55;
    EECON2 = 0xAA;
    
    EECON1bits.WR = 1;    //Write control bit inciar escritura
    
    while(PIR2bits.EEIF == 0);
    PIR2bits.EEIF = 0;
    
    EECON1bits.WREN = 0;  //Apagar el Write enable
    
    INTCONbits.GIE = 1;
    
return EECON1bits.WRERR;  //Error Flag Bit
}

uint8_t readEEPROM(uint8_t address){

    EEADR = address;            //Ingresar la direccion
    EECON1bits.EEPGD = 0;       //EEPROM data memory
    EECON1bits.RD =1 ;          //Activar lectura
    uint8_t data = EEDATA;      //Recuperar el dato
    return data;               
    
}