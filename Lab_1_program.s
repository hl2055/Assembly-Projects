;*----------------------------------------------------------------------------
;* Name:    Lab_1_program.s
;* Purpose: This code flashes one LED at approximately 1 Hz frequency
;* Author: 	Rasoul Keshavarzi
;*----------------------------------------------------------------------------*/
	THUMB		; Declare THUMB instruction set
	AREA		My_code, CODE, READONLY 	;
	EXPORT		__MAIN 		; Label __MAIN is used externally q
	ENTRY
__MAIN
; The following operations can be done in simpler methods. They are done in this
; way to practice different memory addressing methods.
; MOV moves into the lower word (16 bits) and clears the upper word
; MOVT moves into the upper word
; show several ways to create an address using a fixed offset and register as offset
;   and several examples are used below
; NOTE MOV can move ANY 16-bit, and only SOME >16-bit, constants into a register

; Group:  Victor Szeto and Austin Wong
; Date: 2014 09 30

	; Move 0xC000 into R2
	MOV 		R2, #0xC000

	; Initialize and clear R4 register to 0 so the new address of port 1 can be stored
	; in Register 4
	MOV 		R4, #0x0

	; Assign 0x20090000 into R4, which is the first part of the address of port 1,
	; so that it can be used and referenced in future operations
	MOVT 		R4, #0x2009

	; Add 0xC000 to R4 to get 0x2009C000 and store the result in R4
	; which adds the second part of the port 1 address to the register
	ADD 		R4, R4, R2

	; Move initial value for port P2 into R3 which turns off the LEDs
	MOV 		R3, #0x0000007C

	; Turn off five LEDs on port 2 by storing R3 value, the light status value, in the
	; port addresses (R4 has the port 1 address and the #0x40 value offsets it for the
	; other ports 2-5)
	STR 		R3, [R4, #0x40]

	; Move initial value for port P1 into R3 which can be used to turn off the LED's
	MOV 		R3, #0xB0000000

  ; Turn off three LEDs on Port 1 using an offset
	STR 		R3, [R4, #0x20]

  ; Put Port 1 offset into R2
	MOV 		R2, #0x20

; Create a reset counter loop which will continuously run
resetCounter

  ; Initialize R0 to a word value to start counting down at (lower values for smaller
	; wait periods and higher values for higher wait periods)
	MOV 		R0, #0x000A3000

; Create a wait statement to act appropriately and accordingly with respect to the value
; of the stored counter value in R0
wait

	; Decrement the countdown register, R0, by 1 every time this branch is run
	SUBS 		R0, #1

	; Go back to the wait instruction if the branch is no equal to 0 (countdown is not
	; completed)
	BNE			wait

	; Toggle the number in R3 from 0xA0 using the "XOR" instruction once
	; the countdown hits zero, effectively turning off or on the lights
	EOR			R3, #0x10000000

	; Store the register 3 value, the light status, in 0x20090020, which is the port 1
	; address
	STR 		R3, [R4, R2]

	; Continue this process by resetting the counter and repeat.
	B 			resetCounter

	; This is the end of the program
 	END
