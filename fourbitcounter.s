; Archivo: fourbitcounter.s 
; Dispositivo: PIC16F887
; Autor: Lourdes Ruiz 
; Compilador: pic-as (v2.30), MPLABX V5.40
; 
; Programa: dos contadores de 4 bits que incrementa y decrementa en RA0, RA1 y RA3, RA4, respectivamente
  ;sumador de los dos contadores en RA2 y resultado en puerto C
; Hardware: LEDs en el puerto B, D y C, pushbuttons en pulldown en puerto A
; 
; Creado: 1 de agosto, 2021
; Ultima modificación: 5 de agosto, 2021


; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC=INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE=OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE=ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE=OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP=OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD=OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN=OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO=OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN=OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP=ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  WRT=OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  CONFIG  BOR4V=BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)


PSECT udata_bank0 ;common memory
  cont_small: DS 1 ;1 byte // variables 
  cont_big: DS 1
  bts: DS 8
    
PSECT resVect, class=CODE, abs, delta=2
;------------------------------vector reset-------------------------------
ORG 00h ;posición 0000h para el reset 

resetVec: 
    PAGESEL main
    goto main
    
; configuración del microcontrolador 
    
PSECT code, delta=2, abs 
ORG 100h ;posición para el código

;------------------configuración-------------------
 
main: 
    call conf 
    call configr
    banksel PORTA
    
     ;-----------------loop principal--------------------
 loop: 
    btfsc PORTA, 0      ;bit test f, skip if clear; si se presiona el pushbutton, entonces se llama a la función de incrementar 
    call inc_portb
    
    btfsc PORTA, 1
    call dec_portb      ;si se presiona el pushbutton, entonces se llama a la función de incrementar 
    
    btfsc PORTA, 3
    call inc_portd2
   
    btfsc PORTA, 4
    call dec_portd2
    
    btfsc PORTA, 2
    call add
    goto loop
 
;-----------------------------configuración de los puertos------------------------
conf: 
  
    bsf    STATUS, 5  
    bsf    STATUS, 6 ; Banco 03 (11)
    clrf   ANSEL     ; pines digitales 
    clrf   ANSELH
    
    bsf    STATUS, 5  ; banco 01
    bcf    STATUS, 6  
    clrf   TRISB      ; port B como salidas
  
    bsf    TRISA, 0   ; RA0 como entrada para pushbutton
    bsf    TRISA, 1   ; RA1 como entrada para pushbutton
    bsf    TRISA, 2   ; RA2 como entrada para pushbutton de sumador     
   
    ;segundo contador 
    clrf TRISD
    bsf  TRISA, 3
    bsf  TRISA, 4
    
    ;puerto para sumador 
    clrf TRISC
    
    ;---------------------valores iniciales en banco 00--------------------------
    bcf    STATUS, 5  ; banco 00
    bcf    STATUS, 6
    clrf   PORTB  ; valor inicial de 0
    clrf   PORTA
    clrf   PORTC
    clrf   PORTD 
    return 
   
 
 configr: 
    banksel OSCCON 
    bcf     IRCF2
    bsf     IRCF1
    bsf     IRCF0 
    bsf     SCS 
    return

    
 ;---------------------sub rutinas--------------------
 inc_portb:             ;incrementar el puerto B
    btfsc PORTA, 0      ;vuelve a revisar si está presionada (valor de 1)
    goto $-1            ;hasta que suelte (valor de 0) ya salta y ejecuta el resto del código 
    incf   PORTB
    btfsc PORTB, 4
    clrf  PORTB
    
    return

 dec_portb:           ;derementar el puerto B
   btfsc PORTA, 1 
   goto $-1
   decf   PORTB
   btfsc PORTB, 7
   call four 
   return 
   
inc_portd2:
    btfsc PORTA, 3 
    goto $-1
    incf   PORTD
    btfsc PORTD, 4
    clrf  PORTD
    
    return
 
 dec_portd2: 
   btfsc PORTA, 4 
   goto $-1
   decf   PORTD
   btfsc PORTD, 7
   call four2            ;llama a la subrutina four
   return 
 
 four:                   ;se hace un clear en los 4 bits más signifactivos 
    bcf    PORTB, 4
    bcf    PORTB, 5
    bcf    PORTB, 6
    bcf    PORTB, 7
    return
 
  four2:
    bcf    PORTD, 4
    bcf    PORTD, 5
    bcf    PORTD, 6
    bcf    PORTD, 7
    return
 
add:
    btfsc PORTA, 2
    clrw
    movf PORTB, W 
    addwf PORTD, W
    movwf PORTC
    btfsc PORTC, 5
    clrf  PORTC
    return
    
; velocidad default es de 4MHz -- cada instrucción a 1uS
 ; tiempo de delay (uS) = 1+1+2+3x (x = valor inicial del contador)
 ; operación 1 (delay_small a 500 uS) // 500 = 1+1+2+3x -> 496/3 = x -> x = 165.33
 ; op. 2 (delay_big a 100 mS) // 
delay_big:
    movlw 200   ;valor inicial del contador (200*0.5mS = 100mS)
    movwf cont_big 
    call delay_small ;rutina de delay
    decfsz cont_big, 1 ;decrementar el contador 
    goto   $-2   ;ejecutar dos líneas atrás
    return
    
delay_small: ;(0.5 mS)
    movlw 165   ;valor inicial del contador 
    movwf cont_small 
    decfsz cont_small, 1 
    goto $-1
    return
    
END 


