; 2014 10 28
; Group 74: Austin William Wong and Victor Szeto
;*----------------------------------------------------------------------------
;* Name:    Lab_2_program.s 
;* Purpose: This code template is for Lab 2
;* Author: Eric Praetzel and Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
		; Declare THUMB instruction set 
        THUMB 		
                AREA 		My_code, CODE, READONLY 	; 
                ; Label __MAIN is used externally q
                EXPORT 		__MAIN 		
		ENTRY 
; The main program        
__MAIN

; The following lines are similar to Lab-1 but use an address, in r4, to make it easier.
; Note that one still needs to use the offsets of 0x20 and 0x40 to access the ports
;

; Turn off all LEDs 
		
		; Save the port address to R12
		
		; Move 0xC000 into R2
		MOV 		R2, #0xC000
		; Initialize R12 to build an address
		MOV 		R12, #0x0
		; Assign 0x2009 into R12 
		MOVT 		R12, #0x2009
		
		; R12 now stores the base address for dealing with the ports 0x2009C000 
		ADD 		R12, R2, R12 		
		
		; Declaring a global variable: R11 holds the value to turn off the LED at port 1
		MOV 		R11, #0xB0000000	
		
		; Turn off five LEDs on port 2
		
		; move initial value for port P2 into R3 
		MOV 		R3, #0x0000007C
		; Turn off five LEDs on port 2
		STR 		R3, [R12, #0x40] 
		
		; Declaring a global variable: R12 holds the address of the LEDS port 1
		MOV 		R12, #0xC020
		MOVT 		R12, #0x2009
				
		; Move value 0x0 into R1
		MOV R1, #0x0
		; Move value 0xB000 to the top of R1
		MOVT R1, #0xB000
		
		; Store 0xB000 to the address of R12 to turn off the first light in port 1
		STR R1, [R12]
		
; Load the address at label =InputLut into R5
ResetLUT
		; assign R5 to the address at label LUT
		LDR         R5, =InputLUT            

; Read the next character
NextChar
		; Read a character to convert to Morse
        LDRB        R0, [R5], #1		
		; If we hit 0 (null at end of the string) then reset to the start of lookup table
        TEQ         R0, #0              
		; If we have a character process it
        BNE		ProcessChar	
		
        ; Delay for 4 ticks between words
		MOV		R0, #4	
        ; Delay for another 3 ticks at the end of each character
		BL		DELAY
        ; Branch to ResetLut at the end of each word
		BEQ         ResetLUT

; Convert ASCII to Morse pattern in R1	
ProcessChar	BL		CHAR2MORSE		
    
    ; Init R6 with the value for the bit, 16th, which we wish to test
	MOV	R6, #0x10000	
	; RESET FLAG to zero
    MOV R4, #0x000000	
	; R8 is a counter
    MOV R8, #0x10		

; CheckCharacter decides if we moves onto the next character or not	
CheckCharacter
	; Compare the character value stored in R1 to 0
    CMP R1, #0x0;
	; If R1 is negative, we're done - go to the next character.
	BMI NextChar;
	
	;STRB R8, [R0, R1];
	;CMP R8, #0x0;
	
; Shift R1 left by 1, store in R1    
Shift	LSL		R1, R1, #1	
    ; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
	ANDS		R7, R1, R6	
	
    ; Branch if bit is zero
	BEQ CheckFlag
	; Turn on LED if bit is one
    BNE LED_ON

; CheckFlag tells us if we are in between characters or in the character value	
CheckFlag
    ; Compare the flag in R4 with 0
	CMP R4, #0x0
    ;	flag == 1 => Turn off LED
	BNE LED_OFF
    ;   flag == 0 => We're aren't at the morse. Decrement counter and shift again.
	BEQ	Decrement

; Decrement the counter accordingly
Decrement
	; Subtract 1 from R8 as the counter 
    SUBS		R8, #0x1;
	; Counter is not zero - we shift to the next character
    BNE 	 Shift		
	; Counter is zero - we are done this character.
    BEQ 	 Done		

; The procedure for when a character is finished
Done
	; Move the value 0xB000000 into R9 to use to turn off the lights in port 12
	MOV R9, #0x0
	MOVT R9, #0xB000
    
	; Store 0xB000 turns off the first light in port 1
	STR R9, [R12]
	
    ; Delay for 1.5s in between characters
	MOV R0, #0x00000003 
	BL DELAY;	
    ; Branch to NextChar
	B NextChar

;	This is a different way to read the bits in the Morse Code LUT than is in the lab manual.
; 	Choose whichever one you like.
; 
;	First - loop until we have a 1 bit to send  (no code provided)
;
;	This is confusing as we're shifting a 32-bit value left, but the data is ONLY in the lowest 16 bits, so test at bit 16 for 1 or 0
;	Then loop thru all of the data bits:
;

;		BEQ		; branch somewhere it's zero
;		BNE		; branch somewhere - it's not zero

;		....  lots of code
;		B 		somewhere in your code! 	; This is the end of the main program 

;	Alternate Method #2
;
; Ok - you are a hot coder and you've got time to burn and want to shorten your code.  Try this:
; Reverse the Morse Code LUT and encode the bits as follows (01 = short, 11 = 3 delay long, 00 = done)
; By doing this one could just shift right and peel off 2 bits at a time, without the need to count to know when you're
; done or peel off a bunch of empty 0's.  This method means that the encoded information ALTERNATES between on and off!
; The first 01 or 11 count is LED on, and the following one is off, then the next is on ....  till you hit 00

;
;	Additional Work
; 
; Are you still bored?  You want to make sweet Morse Code Music?
; Well - lets get the speaker humming.
;
; Note: If you do use this then decrease the delay to 50 to 100ms so that one can both "read" the LED and audio pattern
;
; By modifying your 500ms delay loop to be two loops - an inner loop of 0x200 that toggles the speaker when done
;  and an outer loop to ensure that the total delay is 500ms
;
; The speaker is on Port 0 ping 26 and by toggling it's at an audible frequency one can make a sound
;
; A simple hack to this code is to modify the EOR line to use another register.  If the register is
; 0x4000000 then the speaker will sound; but if it's 0x0 then the speaker stays silent
;
;		LDR	R4, =LED_PORT_ADR	; setup speaker address
;		MOV	R5, #0x4000000		; This is bit 26 which goes to the speaker
;Again		MOV	R3, #0x200
;loopBuzz	MOV	R2, #0x200		; aprox 1kHz since looping 0x10000 times is ~ 10Hz
;loopMore	SUBS	R2, #1			; decreament inner loop to make a sound;
;		BNE	loopMore
;		EOR	R5, #0x4000000		; toggle speaker output
;		STR	R5, [R4]		; write to speaker output
;		SUBS	R3, #1
;		B	Again



; Subroutines
;
;			convert ASCII character to Morse pattern
;			pass ASCII character in R0, output in R1
;			index into MorseLuT must be by steps of 2 bytes

; Pass ASCII Character and covert to Morse pattern
; push Link Register (return address) on stack
CHAR2MORSE	STMFD		R13!,{R5, R14}	
		
        ; assign R2 to the address at MorseLUT
		LDR  R3, =MorseLUT            

        ; Read a character to convert to Morse
		MOV        R2, R0		
		SUB 		R2, R0, #0x41; 
		
        ; Move the value two into R5
		MOV R5, #0x02; 
        ; Multiply the value of R2 by 5 and store the new value into R2 since
        ; the characters are spaced out by two as there are 16 bits per char
        ; and each char needs two bytes
		MUL 		R2, R2, R5;
		
        ; Read a character to convert to Morse
        LDRH        R1, [R3, R2]		
		
        ; restore LR to R15 the Program Counter to return
		LDMFD		R13!,{R5, R15}	


; Turn the LED on, but deal with the stack in a simpler way
; NOTE: This method of returning from subroutine (BX  LR) does NOT work if subroutines are nested!!
;

; Turn the LED On and preserve R3 and R4 on the R13 stack
LED_ON 	   	push 		{r3-r4}		
        
        ; Set the value in R9 to be 0
		MOV R9, #0x0
		
        ; SET THE FLAG TO ONE - WE ARE INSIDE MORSE
		MOV R4, #0x1  
		
		; Store 0xA000 turns on the first light in port 1
		MOVT R9, #0xA000
		; Turn on the light by moving the on value in R9 into the address 
        ; of port 1 stored in R12
        STR R9, [R12]
		
        ; Move the value of 1 into R0
		MOV R0,#0x1	
        
        ; Branch to delay
		BL DELAY
        ; Branch to Decrement
		B Decrement
		
        ; Preserve R3 and R4 on the stack
		pop 		{r3-r4}
		; branch to the address in the Link Register.  Ie return to the caller
        BX 		LR		

; Turn the LED off, but deal with the stack in the proper way
; the Link register gets pushed onto the stack so that subroutines can be nested
;
; push R3 and Link Register (return address) on stack
LED_OFF	   	STMFD		R13!,{R3, R14}	
        ; Set the value in R9 to be 0
		MOV R9, #0x0
        ; Set the value in R9 to turn off the LED
		MOVT R9, #0xB000
		
		; Store 0xB000 turns off the first light in port 1
		STR R9, [R12]
		
        ; Move the value of 1 into R0
		MOV R0,#0x1	
		; Branch to delay
		BL DELAY
        ; Branch to Decrement
		B Decrement
		
        ; restore R3 and LR to R15 the Program Counter to return
		LDMFD		R13!,{R3, R15}	

;	Delay 500ms * R0 times
;	Use the delay loop from Lab-1 but loop R0 times around
DELAY			STMFD		R13!,{R2, R1, R14}
; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE
MultipleDelay		TEQ		R0, #0		
	; Zero seconds
    TEQ     R0,#0x0        
	; No delay
    BEQ		exitDelay	   
	
    ; Base delay
	MOV 	R10, #0x000B0000 
	
    ; Multiply the base delay by the actual delay in R0 and store in R0
	MUL 		R0, R0, R10 
wait
	; Decrement r0 and set N,Z,V,C status bits
    SUBS 		R0, #1 			
	BNE			wait
; Exit the delay and store the register values in R2, R1, and R15 to the stack.
exitDelay		LDMFD		R13!,{R2, R1, R15}

;
; Data used in the program
; DCB is Define Constant Byte size
; DCW is Define Constant Word (16-bit) size
; EQU is EQUate or assign a value.  This takes no memory but instead of typing the same address in many places one can just use an EQU
;
		ALIGN				; make sure things fall on word addresses

; One way to provide a data to convert to Morse code is to use a string in memory.
; Simply read bytes of the string until the NULL or "0" is hit.  This makes it very easy to loop until done.
;
; strings must be stored, and read, as BYTES
InputLUT	DCB		"VSAWE", 0	
; make sure things fall on word addresses
		ALIGN
; Look-up table MorseLut        
MorseLUT 
		DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D
		DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
		DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
		DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
		DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
		DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
		DCW 	0x1D77, 0x775 				; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

		END 