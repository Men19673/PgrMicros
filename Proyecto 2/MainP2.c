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
uint8_t REC;
uint16_t contpwm;
uint8_t order;
uint8_t orderp;
uint8_t multiplex;
uint8_t var0;
uint8_t var1;
uint8_t var2;
uint8_t var3;
uint16_t PWMEX;
uint16_t PWMEX2;
char grabar = 114;
char reproducir = 112;

/********************************Interrupcion**********************************/
void __interrupt()isr(void){
  
  if (T0IF==1){ 
        TMR0     = 6;
        contpwm = 0;
        T0IF	 = 0; 
        TMR1IF = 1;
        
    }
    
    if (TMR1IF == 1 ){ 
        TMR1IF = 0;
        TMR1	 = PWMEX;
        //TMR1H	 = 0xFF;
        //TMR1L	 = 0xF6;

        contpwm++;
        if (contpwm == 1) {
            RC3=1;
        }  
        else {
            RC3=0;
        }
    }
                    
        /*contpwm++;
        if (contpwm <= PWMEX) {
            RC3 =1;
        }
        else {
            RC3 =0;   
        }
            contpwm =0;*/
        

    if(PIR1bits.ADIF){
        switch (ADCON0bits.CHS){
         case (0):
            var0 = ADRESH;
            break;
           
         case (1):
            var1= ADRESH;
            break;
            
         case (2):
            var2= ADRESH;
            break;
        }     
       PIR1bits.ADIF = 0;
    }
   
     if(PIR1bits.TMR2IF ==1){ 
        PIR1bits.TMR2IF = 0; 
    }
    
    if(PIR1bits.RCIF == 1){
        REC = RCREG;
    }
}
/****************************** MAIN ******************************************/
void main(void) {
    setup();
    ADCON0bits.GO = 1; //Activar el protocolo de lectura de pines

/****************************** LOOP ******************************************/
while(1) {
   /*if(TXIF == 1){
        TXREG = 97; //Enviar @
    }
   __delay_ms(500);*/
   
       
    
    chselect();
    ctrservo();
    if(REC == grabar){
        record();
    }
    if(REC == reproducir){
        play();
    }
 }
}


/********************************Subrutinas************************************/
void setup(void){
  
  ANSEL = 0b00000111;  //Encender analogo
  ANSELH = 0b00000000;
  
  TRISA = 0b00000111;     //Output     
  TRISB = 0b00000000;//Output excepto  
  TRISC = 0b10000110;     //Output bit 7 recibe SERIAL
  TRISD = 0x00;     //Output
  TRISE = 0x00;     //Output
  


  //Timer0 0.1ms
  //OPTION_REG = 0b01000110; //prescaler en 1:128, activar PULLUP y WDT en timer0
  //TMR0		 = 100;
  OPTION_REG	 = 0x83;
  TMR0		 = 6;

  //Timer 1
  T1CON	 = 0x00; //prescaler 1:1
  TMR1IF = 0;
  TMR1H	 = 0xFC;
  TMR1L	 = 0x18;
  //0.01ms
  //TMR1H	 = 0xFF;
  //TMR1L	 = 0xF6;


  //Timer2 20ms
  T2CON	 = 0x26;        //Prescaler 1:16; TMR2 ON, Postscaler 1:5;   
  PR2	 = 250;
  
  
 //ADC
  ADCON0bits.CHS= 1;
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
  CCP1CON = 0b00001100; //Single Output; XX; PWM P1A
  CCP2CON = 0b00001100; //XX, PWM 1100
  
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
  PIE1 = 0b01100011; // 0, ADIE, RCIE, txie, sspie, ccp1ie, TMR2, TMR1
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
  T1CON = 0x01;
}


void ctrservo (void) {
   CCPR1L = ((0.247 * var1) + 62);
   CCPR2L = ((0.247 * var0) + 62);
   PWMEX = ((3.92 * var2) + 63536);
   //PWMEX2= ((3.9 * var2)+1000);
    
    
    
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
            ADCON0bits.CHS = 0;        //Cambiar a canal 0
            break;
        }     
       
            __delay_us(150);
            ADCON0bits.GO = 1;
    }
}

void record(void){
    REC = 0;
    
    switch (order){
        case (0): 
            writeEEPROM(0x00, var0);
            writeEEPROM(0x01, var1);
            writeEEPROM(0x02, var2);
            order=1;
            break;
        case (1):
            writeEEPROM(0x03, var0);
            writeEEPROM(0x04, var1);
            writeEEPROM(0x05, var2);
            order=2;
            break;
        case (2):
            writeEEPROM(0x06, var0);
            writeEEPROM(0x07, var1);
            writeEEPROM(0x08, var2);
            order=0;
            break;
    }
}

void play(void){
    REC = 0;
    
    switch (orderp){
        case (0): 
            ADCON0bits.ADON = 0;
            var0 = readEEPROM(0x00);
            var1 = readEEPROM(0x01);
            var2 = readEEPROM(0x02);
            orderp=1;
            break;
        case (1):
            var0 = readEEPROM(0x03);
            var1 = readEEPROM(0x04);
            var2 = readEEPROM(0x05);
            orderp=2;
            break;
        case (2):
            var0 = readEEPROM(0x06);
            var1 = readEEPROM(0x07);
            var2 = readEEPROM(0x08);
            orderp=3;
            break;
        case (3):
            ADCON0bits.CHS= 1;
             __delay_us(100);
            ADCON0bits.ADON = 1;      //Activar modulo de nuevo
            orderp = 0;
            break;
    
    PORTD = readEEPROM(0x02);

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