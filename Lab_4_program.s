;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s
;* Purpose: 	Lab-4 code
; Victor Szeto and Austin Wong
; 2014 11 27
;* Term:		Fall 2014
;*-------------------------------------------------------------------

;*-------------------------------------------------------------------
				; Declare THUMB instruction set
								THUMB
								AREA 	My_code, CODE, READONLY
				; Label __MAIN is used externally
								EXPORT 		__MAIN
				ENTRY


;*-------------------------------------------------------------------
;*
;*          __MAIN - program entry point
;*
;*-------------------------------------------------------------------

__MAIN

			; Enable EINT3 by storing a value into the correct bit of ISER0
			LDR		R8, =ISER0

						; Move the address for the interrupt button into R1
						MOV		R1, #0x200000

						; store the address of the interrupt button pushed into the address at R8, which is the interrupt handler
						STR		R1, [R8]

						; Move a value of 1 into R6 for flagging the interrupt when it is pushed
						MOV 	R6, #0x1

			; The button is active low we want it to interrupt on the falling edge, so it triggers when we press the button
			LDR		R8, =IO2IntEnf

						; Move the value of the address into R1
						MOV		R1, #0x400

						; Store the value in R1 into the address at R8, which allows the interrupt to be handled
						STR		R1, [R8]

						; Load the address at the label LED_BASE_ADR into R10
						LDR		R10, =LED_BASE_ADR

; The following lines are similar to previous labs.
; They just turn off all LEDs

				; R10 is a  pointer to the base address for the LEDs
				LDR			R10, =LED_BASE_ADR

; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				; Init the random number generator with a non-zero number
				MOV			R11, #0xABCD
LOOP 		BL 			RNG


				; Move 16 bits of random number in to R1
				MOV 		R1, #0x0;
				BFI 		R1, R11, #0, #4

				; Branch to blink slow to count down a random number of seconds
				BL BLINK_SLOW



;*-------------------------------------------------------------------
; Subroutine RNG ... Generates a pseudo-Random Number in R11
;*-------------------------------------------------------------------
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
; Random Number Generator - GIVEN CODE, thus left uncommented.

RNG 			STMFD		R13!,{R1-R3, R14}
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				; The new bit to go into the LSB is present
								EOR			R3, R3, R1
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				; Restore the registers and save Registers 1-3 to to the stack
								LDMFD		R13!,{R1-R3, R15}

;*-------------------------------------------------------------------
; DELAY
;*-------------------------------------------------------------------
;     Causes a delay of 1ms * R0 times
DELAY		STMFD		R13!,{R9, R14}

				; Move 7d, 0.25 milliseconds into R9
				MOV			R9, #0x007D;

				; Multiply R9 by the value passed through R0 (1000 times)
				MUL 		R9, R9, R0;

; Decrement R9 and set N,Z,V,C status bits
wait		SUBS 		R9, #1

				; Branch until R9 is zero.
				BNE			wait

				; Store R9 onto the stack
exitDelay		LDMFD		R13!,{R9, R15}

;*-------------------------------------------------------------------
; Interrupt Service Routine (ISR) for EINT3_IRQHandler
;*-------------------------------------------------------------------
;     This ISR handles the interrupt triggered when the INT0 push-button is pressed
;     with the assumption that the interrupt activation is done in the main program

EINT3_IRQHandler  PROC

			; Move the value 0 into the R6 flag for the interrupt
			MOV   R6, #0x0

			; Clear the interrupt so that the program does not come back
			LDR   R1, =IO2IntClr

			; Move the value 400 into R0
			MOV   R0, #0x400

			; Store the value R0 into R1
			STR   R0, [R1]

			; Branch back to the program
			BX LR

			; End the procedure
			ENDP

;*-------------------------------------------------------------------
;			BLINK_SLOW
;*-------------------------------------------------------------------
; 		Blinks lights for the time specified in R1

BLINK_SLOW

			; Clear r0
			MOVT R0, #0x0;

			; 9C4 = 2500 = .25s delay
			MOV R0, #0x09C4

			; Move a value into R2 to turn the lights off
			MOV R2, #0xB0000000

			; Turn off three LEDs on port 1
			STR R2, [R10, #0x20]

			; Move a value into R2 to turn the lights on
			MOV R2, #0x4

			; Turn on three LEDs on port 2
			STR R2, [R10, #0x40]

			; Delay
			BL DELAY

			; Move a value into R2 to turn the lights on
			MOV R2, #0x00000000

			; Turn on three LEDs on port 1
			STR R2, [R10, #0x20]

			; Move a value into R2 to turn the lights off
			MOV R2, #0x78

			; Turn the lights on the left side on port 2 off
			; Turn off three LEDs on port 2
			STR R2, [R10, #0x40]

			; Delay
			BL DELAY

			; R1 is the random number, keep blinking for a random amount of time until R1 is zero
			SUBS R1, #0x1;

			; Once the random number is at 0 branch to blink fast
			BEQ BLINK_FAST

			; If not branch to blink slow (continue)
			B BLINK_SLOW

;*-------------------------------------------------------------------
;     BLINK_FAST
;*-------------------------------------------------------------------
;    Blink all the LED's fast to start the reaction timer

BLINK_FAST

		; R10 is a  pointer to the base address for the LEDs
		LDR			R10, =LED_BASE_ADR

		; Counter R4 - keep track of our reaction time.
		MOV R4, #0x0;

		; Clear R0
		MOVT	R0, #0x0;

		; 3E8 = 1000 = .1s delay
		MOV 	R0, #0x03E8

		; Move a value of 1 into R6
		MOV 	R6, #0x1

;*-------------------------------------------------------------------
;     REACTION
;*-------------------------------------------------------------------
;     Count the reaction time

REACTION

		; Clear r2
		MOV R2, #0x0

		; Turn on three LEDs on port 1
		STR R2, [R10, #0x20]

		; Clear R2
		MOV R2, #0x0

		; Turn on three LEDs on port 1
		STR R2, [R10, #0x40]

		; Delay
		BL DELAY

		; Add one to the R4 reaction timer
		ADD R4, #0x1;

		; Value to turn the lights off at port 1

		MOV R2, #0xB0000000

		; Turn on three LEDs on port 1
		STR R2, [R10, #0x20]

		; Value to turn the lights off at port 2
		MOV R2, #0x0000007C

		; Turn on three LEDs on port 2
		STR R2, [R10, #0x40]

		; Delay
		BL DELAY

		; Add one to the reaction counter
		ADD R4, #0x1;


		; Check if we got interrupted (R6 == 0)
		TEQ R6, #0x0;

		; Stop counting and this subroutine if there was an interrupt
		; (if button was pushed)

		BEQ GAME_OVER
		; If not branch back to reaction

		B REACTION

;*-------------------------------------------------------------------
;     GAME_OVER
;*-------------------------------------------------------------------
;     Code for when game is done and button is pushed for reaction timer

GAME_OVER

			; COUNTER in R5 - show the bits four times
			MOV R5, #0x4;

			; Reaction time is stored in R4. Move it to var R6
			MOV R6, R4

;*-------------------------------------------------------------------
;     TIME_DISPLAY
;*-------------------------------------------------------------------
;     Code for when game is done and button is pushed for reaction timer and we display the reaction time

TIME_DISPLAY

			; Clear out R3 at the beginning of each loop
			MOV R3, #0x0

			; Move least significant 8 bits to R3 to display
			BFI R3, R6, #0, #8
			BL DISPLAY_NUM
			LSR R6, #8;

			; Delay for two seconds
			MOVT R0, #0x0;
			MOV R0, #0x4E20;
			BL DELAY

			; Subtract one from the counter for the 4 times 8 bit display
			SUBS R5, #0x1;

			; Display the time if not equal to 0
			BNE TIME_DISPLAY

			; Delay for five seconds
			MOVT R0, #0x0;
			MOV R0, #0xC350;
			BL DELAY

			; Display the time all over again
			B GAME_OVER


;*-------------------------------------------------------------------
;			DISPLAY NUM
;*-------------------------------------------------------------------
; 		Displays the number passed in R3.

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

			LDMFD		R13!, {R0, R1, R2, R3, R4, R15}

;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*-------------------------------------------------------------------
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge
IO2IntClr		EQU		0x400280AC
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0

				ALIGN

				END
