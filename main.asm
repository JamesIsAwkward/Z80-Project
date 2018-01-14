;
;  SimpleShell
;
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

RAMEND:                 EQU     $7FFF ; Top address of RAM
INPUT_BUFFER_START:     EQU     $3FFF ; Input buffer space
INPUT_BUFFER_END:       EQU     $401F ; End of buffer for overflow protection later

;******************************************************************
;Init functions
;INIT_SYSTEM handles Stack Pointer and etc
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


;
; SHELLLOOP functions
;

SHELLLOOP_START:
            LD      DE,INPUT_BUFFER_START         ; Manual memory assignment for the input buffer

SHELLLOOP_PROMPT:
            PUSH    HL
            LD      HL,SHELL_CURSOR_DATA
            CALL    UART_PRINTSTR
            POP     HL

SHELLLOOP:  
            CALL    USER_INPUT
            CP      0DH                 ; 0D is hex for carriage return AKA return button
            JP      Z,SHELLLOOP_INPUT_START ; If return is entered, go to shell loop input start function
            CP      7FH                 ; 7F is hex for backspace in putty (default)
            JP      Z,BACKSPACE         ; If backspace is input, then go to backspace function
            CALL    INPUT_BUFFER        ; If not, call Input buffer function 
            JP      SHELLLOOP           ; Start loop over
            
            
BACKSPACE:                              ; Function dedicated to backspace.. this good practice?
            PUSH    AF
            LD      A,B                 ; Loads counter into A
            CP      0                   ; Check if counter is 0
            JP      Z,BACKSPACE_STOP    ;
            POP     AF
            CALL    UART_PRINT          ; Print the backspace
            DEC     B                   ; If it isn't 0 then it will DEC because backspace
            LD      A,00H
            LD      (DE),A
            DEC     DE                  ; It'll also back up the input buffer as well
            JP      SHELLLOOP
            
BACKSPACE_STOP:
            POP     AF
            JP      SHELLLOOP
 
;
; Input functions
; Any functions that deal with receiving inputs and parsing them
;



;
; Currently has no overflow protection    

INPUT_BUFFER:
            LD      (DE),A              ; Loads input data into HL pointer
            INC     DE                  ; INC DE to get ready for next inputs
            INC     B                   ; INC the counter to keep tabs on where the cursor is and how many bytes I've typed
            CALL    UART_PRINT          ; Prints the input
            RET                         ; Return

          
SHELLLOOP_INPUT_START:
            LD      A,0
            LD      (DE),A
            LD      DE,INPUT_BUFFER_START            ; Manually addressing the start of my input buffer
           
SHELLLOOP_INPUT:
            LD      A,B                 ; Load the counter to A
            CP      0                   ; See if the counter is at 0
            JP      Z,SHELLLOOP_START   ; If so, there is no (or shouldn't be..) data to output
            PUSH    BC
            CALL    INPUT_PARSE_START
            POP     BC
            JP      SHELLLOOP_INPUT_END
            
INPUT_PARSE_START:
            LD      HL,TEST_COMMAND     ; Loads HL with first command
            LD      DE,INPUT_BUFFER_START
            CALL    INPUT_PARSE
            CP      1
            JP      Z,TEST_CMD
            LD      HL,CALC_COMMAND     ; Loads HL with second command
            LD      DE,INPUT_BUFFER_START
            CALL    INPUT_PARSE
            CP      1
            JP      Z,CALC_CMD
            CALL    INVALID_CMD
            RET
            
INPUT_PARSE:
            LD      A,(DE)                   ; Loads input
            CP      (HL)                     ; CP first byte of input to first byte of cmd
            JP      NZ,INPUT_PARSE_FALSE     ; If it doesn't match, then end
            CP      0
            JP      Z,INPUT_PARSE_END
            INC     HL
            INC     DE
            JP      INPUT_PARSE
            
            
INPUT_PARSE_END:  
            LD      A,1
            RET

INPUT_PARSE_FALSE:
            LD      A,0
            RET
            
        
SHELLLOOP_INPUT_END:
            LD      B,0                 ; Reset the counter back to 0
            CALL    NEW_LINE            ; Start a new blank line
            JP      SHELLLOOP_START     ; 


USER_INPUT:
			IN      A,(05H)        ; Get the line status register's contents
			BIT     0,A            ; Test BIT 0, it will be set if the UART is ready to receive
			JP      Z,USER_INPUT
			IN      A,(00H)        ; Get a character from the UART 
            RET


;
; Terminal functions
; Any functions that deal with terminal output
;
          
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

INVALID_CMD:
            LD      HL,INVALID_COMMAND_DATA
            CALL    UART_PRINTSTR
            RET
            
            
HEADER_START:
            LD      HL,HEADERDATA ; Loads the header data to HL            
            JP      UART_PRINTSTR
            
UART_PRINTSTR:
            LD      A,(HL)          ; 
            CP      0               ; Compared data to 0 (which is EOF)
            JP      Z,UART_PRINTSTR_END     ; If it is 0, jump to end function
            CALL    UART_PRINT      ; Makes sure UART is ready to send
            INC     HL              ; Increments HL to next byte in string
            JP      UART_PRINTSTR         ; Starts loop over again to prnt the next byte
            
UART_PRINTSTR_END:
            RET                     ; Returns to function that called Header

            


UART_PRINT:
            PUSH    AF              ; Preserving AF data in the stack
            CALL    UART_TXCHECK    ; Check to see if the UART is ready to TX
            POP     AF              ; Load data from stack back to AF register
            OUT     (00H),A         ; Out to terminal 
            JP      UART_PRINT_END  ; Jumps to UART_PRINT_END function


UART_PRINT_END:
            RET                 ; Returns to function that called UART_PRINT
            

;
;UART Functions
;

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
            

;
; Command functions
; 


TEST_CMD:
            PUSH    HL
            LD      HL,TEST_COMMAND_DATA
            CALL    NEW_LINE
            CALL    UART_PRINTSTR
            POP     HL
            RET
            
CALC_CMD:
            LD      HL,CALC_COMMAND_DATA
            CALL    UART_PRINTSTR
            JP      SHELLLOOP_START



            
; Data and Strings
NEW_LINE_DATA:      DB      "\r",0
SHELL_CURSOR_DATA:  DB      "\n\rSimpleShell> ",0
HEADERDATA:         DB      "\n\rSimpleShell v0.3.0\r\nCreated by: JamesIsAwkward\r",0



; Command List
TEST_COMMAND:       DB      "test",0
TEST_COMMAND_DATA:  DB      "\n\rTesting 1, 2, 3!",0

CALC_COMMAND:       DB      "calc",0
CALC_COMMAND_DATA:  DB      "\n\rDo you want to add, subtract, multiply, or divide?",0
CALC_CURSOR_DATA:   DB      "\n\r\Calc> ",0
CALC_ADD_DATA:      DB      "add",0
CALC_SUBTRACT_DATA: DB      "subtract",0
CALC_ADD_PRINT:     DB      "Add!",0

INVALID_COMMAND_DATA:   DB  "\n\rYou have entered an invalid command.",0

END