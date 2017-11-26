;************************************
;  SimpleShell                      *
;  Super Simple Shell-like Monitor  *
;  All it does for now is print     *
;  the header data and then echo    *
;  user input                       *
;************************************

;******************************************************************
;UART Info
;
;DLAB A2 A1 A0 Register
;0    0  0  0  Receiver Buffer (read),
;              Transmitter Holding
;              Register (write)
;0    0  0  1  Interrupt Enable
;X    0  1  0  Interrupt Identification (read)
;X    0  1  0  FIFO Control (write)
;X    0  1  1  Line Control
;X    1  0  0  MODEM Control
;X    1  0  1  Line Status
;X    1  1  0  MODEM Status
;X    1  1  1  Scratch
;1    0  0  0  Divisor Latch
;              (least significant byte)
;1    0  0  1  Divisor Latch
;              (most significant byte)
;******************************************************************

ORG                 $0000
RAMEND:     EQU     $7FFF       ; Top address of RAM

;******************************************************************
;Init functions
;INIT_SYSTEM handles Stack Pointer and etc
;INIT_UART handles.... UART INIT
;******************************************************************
INIT_SYSTEM:
            LD     SP,RAMEND    ; Loads the contents of RAMEND to Stack Pointer

INIT_UART:
            LD     A,80H        ; Mask to Set DLAB Flag
			OUT    (03H),A
			LD     A,12         ; Divisor = 12 @ 9600bps w/ 1.8432 Mhz
			OUT    (00H),A      ; Set BAUD rate to 9600
			LD     A,00
			OUT    (01H),A      ; Set BAUD rate to 9600
			LD     A,03H
			OUT    (03H),A      ; Set 8-bit data, 1 stop bit, reset DLAB Flag
            JP     MAIN

MAIN:
            LD      HL,HEADERDATA ; Loads the header data to HL
            CALL    HEADER        ; This prints the header data on startup
            ;HALT                 ; Halts the system - I use it to debug my hardware
            CALL    SHELLLOOP


SHELLLOOP:   
            CALL    USER_INPUT
            CALL    UART_PRINT
            JP      SHELLLOOP

;*******************************************************************
; Input functions
; Any functions that deal with grabbing inputs or processing them
;*******************************************************************

USER_INPUT:
			IN      A,(05H)        ; Get the line status register's contents
			BIT     0,A            ; Test BIT 0, it will be set if the UART is ready to receive
			JP      Z,USER_INPUT
			IN      A,(00H)        ; Get a character from the UART 
            RET


;*******************************************************************
; Output functions
; Any functions that deals with prepping output - UART is excluded
;*******************************************************************
          
            
            
HEADER:
            LD      A,(HL)          ; Loads HL memory location to A
            CP      0               ; Compared data to 0 (which is EOF)
            JP      Z,HEADEREND     ; If it is 0, jump to end function
            CALL    UART_PRINT      ; Makes sure UART is ready to send
            INC     HL              ; Increments HL to next byte in string
            JP      HEADER          ; Starts loop over again to prnt the next byte
            
HEADEREND:
            RET                     ; Returns to function that called Header

;*******************************************************************
;"System calls" section - this will include UART checks and outs
;In an attempt to make this modular I'm breaking these functions up.
;This will hopefully make code expansion much easier to deal with.
;*******************************************************************


;*******************************************************************
;UART Functions
;*******************************************************************

UART_PRINT:
            PUSH    AF              ; Preserving AF data in the stack
            CALL    UART_TXCHECK    ; Check to see if the UART is ready to TX
            POP     AF              ; Load data from stack back to AF register
            OUT     (00H),A         ; Out to terminal 
            JP      UART_PRINT_END  ; Jumps to UART_PRINT_END function


UART_PRINT_END:
            RET                 ; Returns to function that called UART_PRINT


UART_TXCHECK:
            IN      A,(05H)           ; Check line status
            BIT     5,A               ; See if the UART is ready to send
            JP      Z,UART_TXCHECK    ; If not, go back and check again
            RET


UART_RXCHECK:
            PUSH    AF
            IN      A,(05H)           ; Check line status
            BIT     0,A               ; See if the UART is ready to receive
            JP      Z,UART_RXCHECK    ; If not, go back and check again
            POP     AF
            RET








            
;Data and Strings            
HEADERDATA:  DB      "\n\rSimpleShell\r\nrev 0.1\r\nCreated by: JamesIsAwkward\r\n",0