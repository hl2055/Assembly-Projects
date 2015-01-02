; ECE-222 Lab 3... Fall 2014 term 

; Victor Szeto and Austin Wong
; 2014 11 11

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	           LAB REPORT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	1.
;	  8 bits - 25.6ms 
;	  16 bits - 6.5536 sec
;	  24 bits - 1677.7216 sec
;	  32 bits - 429497 sec
;	
;	2. 
;	  Average human reaction time is 260ms - we should therefore use 16 bits to hold
;   the reaction time. Anything more than that would have extra unnecessary bits at the end.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Lab 3 code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

				
				; Store the address of the pin
				LDR 		R9, =FIO2PIN
				
				; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports
				LDR			R10, =LED_BASE_ADR
				LDR R6, [R9];

START
				; TURN OFF THE LIGHTS
				BL 		LED_OFF

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			COUNTER 0 - FF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				
                ; Move the value 3E8 into R0
				MOVT R0, #0x0;
				MOV R0, #0x03E8;
                
                ; Clear R3
				MOV R3, #0x0;

; Count down loops
countdown					
                
                ; Branch to display number sequence
				BL DISPLAY_NUM
                ; Branch to delay sequence
				BL DELAY
				
                ; Add one to R3, the counter
				ADDS R3, #0x1;
                ; Compare the counter with 255
				CMP R3, #0xFF;
                
                ; If R3 is not equal to 255, continue count down
				BNE countdown
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			SET UP REACTION TIMER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				
				; Turn off lights
				BL			LED_OFF
				
				; Get a random number, store it in R11
				BL 			RandomNum 
				
				; Clear R0
				MOV 		R0, #0x0;
				; Move 16 bits of random number in to R0
                BFI 		R0, R11, #0, #16
				
				; Scale and offset
				;MOV			R8, #0x64			; 100
				;MOV         R12,#0x7A			; 122
				;MUL			R0, R12		
				;UDIV		R0, R8
				
				; Wait the random time interval
				BL DELAY
				
				; Turn on just LED p1.29 to indicate when to push the button
				MOV			R3, #0x90000000		
				STR 		R3, [R10, #0x20] 	
                
                ; Branch to reaction timer
				BL REACTION_TIMER
                
                ; Branch to turn the led off
				BL 			LED_OFF

; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1		; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				LDMFD		R13!,{R1, R2, R3, R15}

;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}
				MOV			R2, #0x007D;
				MUL 		R2, R2, R0;
wait			SUBS 		R2, #1 			; Decrement r0 and set N,Z,V,C status bits
				BNE			wait
exitDelay		LDMFD		R13!,{R2, R15}
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			LED OFF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Turn the LED off
; push R3 and Link Register (return address) on stack
LED_OFF   	STMFD		R13!,{R3, R14}	
			
            ; Move the value used to turn off the LED
            MOV 		R3, #0xB0000000		 
			; Turn off three LEDs on port 1 by moving the turn-off value into the port 1 address
            STR 		R3, [r10, #0x20]
            
            ; Move the value used to turn off the LED
			MOV 		R3, #0x0000007C
            ; Turn off five LEDs on port 2 
			STR 		R3, [R10, #0x40] 	
			; restore R3 and LR to R15 the Program Counter to return
            LDMFD		R13!,{R3, R15}	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			LED ON
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Turn the LEd on
; push R3 and Link Register (return address) on stack
LED_ON   	STMFD		R13!,{R3, R14}	
			
            ; Move the value used to turn on the LED
            MOV 		R3, #0x0			
			; Turn on three LEDs on port 1 
            STR 		R3, [r10, #0x20]	 
			; Turn on five LEDs on port 2
            STR 		R3, [R10, #0x40] 	 
			; Restore R3 and LR to R15 the Program Counter to return
            LDMFD		R13!,{R3, R15}	
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			DISPLAY NUM
;	Displays the number passed in R3.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; push R0, R1, R2, R3, R4 and Link Register (return address) on stack
DISPLAY_NUM	STMFD		R13!, {R0, R1, R2, R3, R4, R14}			
			
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;	SETUP
			; 		Clear the registers we're going to use
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			;	R1 holds the value for port 1 that will be loaded on; clear first
			MOV 		R1, #0x0
			
			; 	R2 holds the value for port 2 that will be loaded on; clear first
			MOV 		R2, #0x0
			
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;	SLICE
			; 		Split the number in R0 into two registers
			;			R1: Port 1
			;			R2: Port 2
			; 		depending on which port that bit is on
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			; Take the first five bits of R3 and store it in R2
			; We need these values for port2 : 6, 5, 4, 3, 2, 1
			BFI 		R2, R3, #0, #5
			
			; We just removed the 5 bits for R2, shift the remaining bits over
			LSR 		R3, R3, #5				;shifting the 5 bits that are put into R2

			; Take the first three bits of R3 and store in R1
			; We need these values in port 1: 31, 29, 28
			BFI 		R1, R3, #0, #3 
			
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;	PORT 1
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			; Reverse the bits in R1. R0 was bit 28, 29, 31 and we need it in 31, 29, 28
			RBIT 		R1, R1
			
			; Shift R1 to the right, then add 0b010... to move the 30th bit to the 31st position
			;						 ; If we had `111...`
			LSR 		R1, R1, #1			; => `0111....`
			ADD 		R1, #0x40000000		; => `1011...`
			
			; Invert R1 since `1` is LED OFF and `0` is LED ON
			EOR 		R1, #0xFFFFFFFF	

			; Turn on the correct lights for port 1
			STR 		R1, [R10, #0x20]	; Turn on three LEDs on port 1  
			
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;	PORT 2
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			; Reverse the bits in R2. R0 was 1, 2, 3, 4, 5, 6, and we want 6, 5, 4, 3, 2, 1
			RBIT		R2, R2
			
			; Shift R2 to the right by 25 to put it in the correct position for pin address
			LSR 		R2, R2, #25  
			
			; Invert R1 since `1` is LED OFF and `0` is LED ON
			EOR 		R2,#0xFFFFFFFF			;0 becomes 1 and 1 becomes 0:	Register for Port 2 complete

			; Turn on the correct lights for port 2
			STR 		R2, [R10, #0x40]	
			
            ; Restore R3 and LR to R15 the Program Counter to return
			LDMFD		R13!, {R0, R1, R2, R3, R4, R15}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			REACTION TIMER
;	Turns on the light, count how much time has passed since light turned on
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; push R0 and Link Register (return address) on stack
REACTION_TIMER	STMFD		R13!, {R0, R14}
				
                ; Move a value of one into R0
                MOV 		R0, #0x1;
				
				; Use R7 as the reaction timer and clear
				MOV			R7, #0

; Reaction time loops subroutine				
reac_loop		BL DELAY
                
                ; Add one to the counter for the reaction timer
				ADD R7, #0x1
                ; Load the value of the button's state
				LDR R6, [R9];
				
                ; Clear R12
				MOVT R12, #0x0;
				; This is the value when the button is pressed stored in R12
				MOV R12, #0x3B83;
				
                ; Compare the button's state with the pressed down value
				CMP R6, R12
                ; If equal, it is pressed down and the game is over, branch
                ; to game over
				BEQ GAME_OVER
				
                ; If not equal continue reaction loop timer
				B reac_loop
                
; Go to this subroutine when the button is pushed
GAME_OVER		

				; COUNTER in R5 for 32 bits of reaction time, split into 4 8 bit numbers
				MOV R5, #0x4;
				
                ; Move the reaction time into R6
				MOV R6, R7
			
; Display the time on the LED's            
TIME_DISPLAY
				; Clear out R3 at the beginning of each loop
				MOV R3, #0x0
				
				; Move least significant 8 bits to R3 to display
				BFI R3, R6, #0, #8 
                ; Display the 8 bit number stored in R6
				BL DISPLAY_NUM
                ; Load the next 8 bits into 
				LSR R6, #8;
				
				; Delay for two seconds
				MOVT R0, #0x0;
				MOV R0, #0x4E20;
				BL DELAY

                ; Decremenet the counter of 4 by 1
				SUBS R5, #0x1;
				
                ; Display the time if not equal to 0
				BNE TIME_DISPLAY
				
				; Delay for five seconds
				MOVT R0, #0x0;
				MOV R0, #0xC350;
				BL DELAY
				
                ; Display the time all over again
				B GAME_OVER

LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 		; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 		; Address of Pin Select Register 4 for P2[15:0]
FIO2PIN 		EQU 	0x2009c054
;BTN_PRESSED		EQU				; When the value at the pin is this, then the button is down
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

				ALIGN 

				END 
