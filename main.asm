;
;  SimpleShell
;  Super Simple Shell-like Monitor
;  All it does for now is print
;  the header data and then echo
;  user input after pressing enter
;

; This will change as I go, especially when I add ROM
; Future Memory Map
;   ROM - 0000H - 7FFF
;   RAM - 8000H - $FFFF
;
;   Input buffer - 3FFF - 401F ; 32 bytes



;******************************************************************
; Special thanks to MatthewWCook for his UART chart and code!!!!!
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

; I'm using a ROM-less build for now, so this will be changed later
RAMEND:     EQU     $7FFF       ; Top address of RAM

;******************************************************************
;Init functions
;INIT_SYSTEM handles Stack Pointer and etc
;INIT_UART handles.... UART INIT
;******************************************************************
INIT_SYSTEM:
            LD     A,0          ; Quick cleanup to help with testing
            LD     B,0          ; I do frequent resets to check code
            LD     HL,0         ;
            LD     SP,RAMEND    ; Loads the contents of RAMEND to Stack Pointer
            CALL   INIT_UART
            

MAIN:
            CALL    CLEAR_SCREEN
            CALL    HEADER_START       ; This prints the header data on startup
            ;HALT                      ; Halts the system - I used it to debug my hardware
            JP      SHELLLOOP_START


;*******************************************************************
; SHELLLOOP will loop forever while display the cursor data and
; parse all data that in entered by the user
;
; At least.... it will :P
;*******************************************************************

SHELLLOOP_START:
            LD      HL,$3FFF            ; Manual memory assignment for the input buffer

SHELLLOOP_PROMPT:
            PUSH    HL
            LD      HL,SHELL_CURSORDATA
            CALL    UART_PRINTSTR
            POP     HL

SHELLLOOP:  
            CALL    USER_INPUT
            CP      0DH                 ; 0D is hex for carriage return AKA return button
            JP      Z,SHELLLOOP_INPUT_START ; If return is entered, go to shell loop input start function
            CP      08H                 ; 08 is hex for backspace
            CALL    Z,BACKSPACE         ; If backspace is input, then go to backspace function
            CALL    INPUT_BUFFER        ; If not, call Input buffer function 
            JP      SHELLLOOP           ; Start loop over
            
BACKSPACE:                              ; Function dedicated to backspace.. this good practice?
            LD      A,B                 ; Loads counter into A
            CP      0                   ; Check if counter is 0
            RET                         ; If it is, I don't want to backspace anymore to I ret
            DEC     B                   ; If it isn't 0 then it will DEC because backspace
            DEC     HL                  ; It'll also back up the input buffer as well
            CALL    UART_PRINT          ; Print the backspace
            RET                         ; Return
            
;
; Currently has no overflow protection     
; Just a test, this will echo back your input 
; after you type it and press enter.      

INPUT_BUFFER:
            LD      (HL),A              ; Loads input data into HL pointer
            INC     HL                  ; INC HL to get ready for next inputs
            INC     B                   ; INC the counter to keep tabs on where the cursor is and how many bytes I've typed
            CALL    UART_PRINT          ; Prints the input
            RET                         ; Return
           
           
           
SHELLLOOP_INPUT_START:
            LD      HL,$3FFF            ; Manually addressing the start of my input buffer
           
SHELLLOOP_INPUT:
            LD      A,B                 ; Load the counter to A
            CP      0                   ; See if the counter is at 0
            JP      Z,SHELLLOOP_START   ; If so, there is no (or shouldn't be..) data to output
            LD      A,(HL)              ; Loads A with data from buffer
            CALL    UART_PRINT          ; Prints data
            INC     HL                  ; Shifts HL to next byte for the next loop
            DEC     B                   ; DEC counter to keep up with remaining data
            JP      SHELLLOOP_INPUT     ; Start the loop over
            
SHELLLOOP_INPUT_END:
            LD      B,0                 ; Reset the counter back to 0
            CALL    NEW_LINE            ; Start a new blank line
            JP      SHELLLOOP_START     ; 

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
; Any functions that deal with prepping output - UART is excluded
;*******************************************************************
          
CLEAR_SCREEN:
            PUSH    AF
            LD      A,0CH         ; 0C hex is "form feed" in ASCII
            CALL    UART_PRINT
            POP     AF
            RET

NEW_LINE:
            PUSH    HL
            LD      HL,NEW_LINE_DATA        ; 0A hex is "line feed" in ASCII
            CALL    UART_PRINTSTR
            POP     HL
            RET

HEADER_START:
            LD      HL,HEADERDATA ; Loads the header data to HL            
            JP      UART_PRINTSTR
            
UART_PRINTSTR:
            LD      A,(HL)          ; Loads HL memory location to A
            CP      0               ; Compared data to 0 (which is EOF)
            JP      Z,UART_PRINTSTR_END     ; If it is 0, jump to end function
            CALL    UART_PRINT      ; Makes sure UART is ready to send
            INC     HL              ; Increments HL to next byte in string
            JP      UART_PRINTSTR         ; Starts loop over again to prnt the next byte
            
UART_PRINTSTR_END:
            RET                     ; Returns to function that called Header


;*******************************************************************
;UART Functions
;*******************************************************************
INIT_UART:
            LD     A,80H        ; Mask to Set DLAB Flag
			OUT    (03H),A
			LD     A,01         ; Divisor = 1 @ 115200 bps w/ 1.8432 Mhz
			OUT    (00H),A      ; Set BAUD rate to 115200
			LD     A,00
			OUT    (01H),A      ; Set BAUD rate to 115200
			LD     A,03H
			OUT    (03H),A      ; Set 8-bit data, 1 stop bit, reset DLAB Flag
            RET


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
NEW_LINE_DATA:      DB      "\r",0
SHELL_CURSORDATA:   DB      "\n\rSimpleShell>",0
HEADERDATA:         DB      "\n\rSimpleShell v0.1.1\r\nCreated by: JamesIsAwkward\r",0

END
