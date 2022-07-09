TITLE Designing Low-Level I/O Procedures    (Proj6_backc.asm)

; Author: Chance Back
; Last Modified: 6/4/22
; OSU email address: backc@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:   6              Due Date: 06/05/2022
; Description: Program prompts user to input 10 signed decimal integers and records each individual input as a string. If the value
;		entered is not a signed integer the value is discarded and the program prompts the user to enter a valid integer.
;		Once a valid input is received, the string is converted to numerical form using string primitives. The values are then stored 
;		in a list. Each value in the list is then converted back to string form using string primitives before being displayed to the
;		user. Lastly, the sum and truncated average of the list of numbers are calculated and displayed as well.



INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGenerateString
;
; Prompts the user to input a string and stores the value in a given variable.
;
; Preconditions: do not use edi or edx as arguments.
;				 total_bytes_read is type DWORD.
;
; Receives:
;		prompt_address		= address of message to display to user when asking for input
;		user_input			= address to store string entered by user
;		total_bytes_read	= address to store length of string
;		MAX_STR_LENGTH is global variable/constant
;
; Returns: 
;		user_input			= address now contains string entered by user
;		total_bytes_read	= address now contains length of string
; ---------------------------------------------------------------------------------
mGetString MACRO prompt_address, user_input, total_bytes_read
  ; save registers used by MACRO
  PUSH	EAX
  PUSH	ECX
  PUSH	EDX
  PUSH	EDI

  ; prompt user for string
  MOV	EDX, prompt_address
  CALL	WriteString

  ; get user input
  MOV	EDX, user_input
  MOV	ECX, MAX_STR_LENGTH
  CALL	ReadString

  ; store user input data
  MOV	EDI, [total_bytes_read]
  MOV	[EDI], EAX

  ; restore registers used to orginal values
  POP	EDI
  POP	EDX
  POP	ECX
  POP	EAX

ENDM

; ---------------------------------------------------------------------------------
; Name: mGenerateString
;
; Displays a given string.
;
; Preconditions: do not use edx as argument.
;
; Receives:
;		string_address = address of string to be displayed
;
; returns: none.
; ---------------------------------------------------------------------------------
mDisplayString MACRO string_address
  ;save registers used by MACRO
  PUSH	EDX

  ; display string
  MOV	EDX, string_address
  CALL	WriteString

  ; restore registers used to original values
  POP	EDX
ENDM


MAX_STR_LENGTH = 29		
NUM_ARR_LENGTH = 10

.data

intro			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", 13,10
				BYTE	"Written by: Chance Back", 13,10,13,10
				BYTE	"Please provide 10 signed decimal integers.", 13,10
				BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 13,10
				BYTE	"After you have finished inputting the raw numbers I will display a list of the integers,", 13,10
				BYTE	"their sum, and their average value.", 13,10,13,10,0 
prompt			BYTE	"Please enter a signed integer: ", 0
prompt_error	BYTE	"ERROR: You did not enter a signed number or your number was too big.", 13,10
				BYTE	"Please try again: ", 0
message_1		BYTE	"You entered the following numbers:", 13,10,0
message_2		BYTE	"The sum of these numbers is: ", 0
message_3		BYTE	"The truncated average is: ", 0
goodbye			BYTE	"Thanks for playing!", 13,10,0
num_array		SDWORD	10 DUP(?)					; array to store valid numbers entered in by user
user_input		BYTE	30 DUP(?)					; empty string to store user input 
bytes_read		DWORD	?							; stores the number of bytes read by the mGetString MACRO
converted_num	SDWORD	?							; stores the user's input converted from string to decimal
list_spacing	BYTE	", ", 0
sum				SDWORD	?							; sum of numbers entered by user
trunc_avg		SDWORD	?							; truncated average of numbers entered


.code

main PROC

  ; display the introduction
  mDisplayString OFFSET intro

; --------------------------
; Gets 10 valid signed numbers capable of fitting in an SDWORD from the user
;	by calling ReadVal PROC. Stores the values received into num_array.
; --------------------------
  MOV	ECX, NUM_ARR_LENGTH
  MOV	ESI, OFFSET num_array
_GetNextVal:
  ; push required parameters and call ReadVal
  PUSH	OFFSET prompt
  PUSH	OFFSET prompt_error
  PUSH	OFFSET user_input
  PUSH	OFFSET bytes_read
  PUSH	OFFSET converted_num
  CALL	ReadVal

  ; move resulting value into num_array
  MOV	EAX, converted_num
  MOV	[ESI], EAX

  ; increment num_array and loop to _GetNextVal
  ADD	ESI, 4
  LOOP	_GetNextVal
  CALL	CrLf

; --------------------------
; Display values in num_array by calling WriteVal PROC and
;	incrementing through the list with a loop.
; --------------------------
  mDisplayString OFFSET message_1
  MOV	ECX, NUM_ARR_LENGTH
  MOV	ESI, OFFSET num_array

_DisplayVal:
  ; display value in num_array
  MOV	EAX, [ESI]
  PUSH	EAX
  CALL	WriteVal
  
  ; if last element in list displayed, do not print spacing
  CMP	ECX, 1
  JE	_Loop
  mDisplayString OFFSET list_spacing

_Loop:
  ; increment num_array and loop to _DisplayVal
  ADD	ESI, 4
  LOOP	_DisplayVal
  CALL CrLf

; --------------------------
; Display the sum and truncated average of the values in num_array.
; --------------------------
  ; calculate the sum of values in num_array
  PUSH	OFFSET num_array
  PUSH	OFFSET sum						
  CALL	calculateSum

  ; display the sum of the values
  mDisplayString OFFSET	message_2
  PUSH	sum									
  CALL	WriteVal
  CALL	CrLf

  ; calculate the truncated average of the values in num_array
  PUSH	sum								
  PUSH	OFFSET trunc_avg					
  CALL	calculateTruncAvg
  
  ; display the truncated average
  mDisplayString OFFSET	message_3
  PUSH	trunc_avg							
  CALL	WriteVal
  CALL	CrLf
  CALL	CrLf

  ; display the goodbye message
  mDisplayString OFFSET goodbye
  CALL	CrLf

	Invoke ExitProcess,0	
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Asks the user to input a numerical value that fits in an SDWORD. Validates the user
;	input and stores it in numerical form in at a passed parameter.
;
; Preconditions: variable used to store converted value is type SDWORD.
;				 variable usesd to store bytes read is type DWORD.
;
; Postconditions: none.
;
; Receives: 
;		[EBP + 24]	= address of message to display when asking user for input
;		[EBP + 20]	= address of error message to print when user input is invalid
;		[EBP + 16]	= address of empty string to store user input
;		[EBP + 12]	= address to store number of characters entered in by user
;		[EBP + 8]	= address to store valid user input
;
; Returns: [EBP + 8] = address of user input in numerical form
; ---------------------------------------------------------------------------------

ReadVal PROC USES ESI EAX EBX
  ; is_valid		: local variable passed to validate PROC as output parameter 
  ; overflow_check	: local variable passed to convertToDec PROC as output parameter
  LOCAL is_valid:DWORD, overflow_check:DWORD

  ; set local variables to zero
  MOV	DWORD PTR [is_valid], 0
  MOV	DWORD PTR [overflow_check], 0

  ; get string from user
  mGetString [EBP + 24], [EBP + 16], [EBP + 12]
  JMP	_Validation

_Error:
  ; get string from user with error message
  mGetString [EBP + 20], [EBP + 16], [EBP + 12]

; --------------------------
; Validates the string input contains only signed numerical 
;	characters with validate PROC. Then checks if the
;	procedure returns 1 in the local variable is_valid. If
;	number was not valid, jumps to _Error.
; --------------------------
_Validation:
  ; push required parameters and call validate PROC
  PUSH	[EBP + 16]			
  MOV	ESI, [EBP + 12]
  MOV	EBX, [ESI]
  PUSH	EBX					; push number of bytes read from user input
  LEA	EAX, is_valid
  PUSH	EAX					; push address of local variable is_valid
  CALL	validate

  ; check results of validate PROC
  MOV	EAX, is_valid	
  CMP	EAX, 0
  JE	_Error

; --------------------------
; Converts the user inputted string to its equivalent numerical
;	value with convertToDec PROC. Then checks if the number was 
;	too large by checking if the procedure returns 1 in the
;	local variable overflow_check. If number was too large,
;	jumps to _Error.
; -------------------------- 
  ; push required parameters and call convertToDec PROC
  PUSH	[EBP + 16]			
  MOV	ESI, [EBP + 12]
  MOV	EBX, [ESI]			
  PUSH	EBX					; push number of bytes read from user input
  PUSH	[EBP + 8]			
  LEA	EAX, overflow_check
  PUSH	EAX					; push address of local variable overflow_check
  CALL	convertToDec

  ; check if procedure indcated an overflow
  MOV	EAX, overflow_check	
  CMP	EAX, 0
  JNE	_Error

  RET	20
ReadVal	ENDP

; ---------------------------------------------------------------------------------
; Name: validate
;
; Validates that a given string is a signed numerical value in ASCII form.
;
; Preconditions: the array is type BYTE.
;
; Postconditions: none.
;
; Receives: 
;		[EBP + 32]	= string to be validated
;		[EBP + 28]	= length of string
;		[EBP + 24]	= address to store results of validation: 1(True) or 0(False)
;
; Returns: [EBP + 24] = result of validation
; ---------------------------------------------------------------------------------

validate PROC USES EBP EDI ESI EAX ECX
  MOV	EBP, ESP
; --------------------------
; Increments through the given string making sure each byte is valued
;	below 57. If one is greater than 57 then the string is not valid
;	and the program jumps to _False.
; --------------------------
  ; set counter to length of string
  MOV	ECX, [EBP + 28]	

  ; point EDI to the beginning of the given string
  MOV	EDI, [EBP + 32]		

_UpperCheck:
  ; check if byte value is below 57
  MOV	AL, 57
  CLD
  SCASB
  JL	_False
  LOOP	_UpperCheck

; --------------------------
; Increments through the given string making sure each byte is valued
;	above 48. If one is less than 48 it checks if the value is a sign
;	character, '+'/'-', at the begining of the string. If it is, then
;	it continues on to validate the rest of the bytes in the string.
;	If it is not, then the string is not valid and it jumps to _False.
; --------------------------
  ; set counter to length of string
  MOV	ECX, [EBP + 28]		

  ; point EDI to the beginning of the given string
  MOV	EDI, [EBP + 32]		

_LowerCheck:
  ; check if byte value is above 48
  MOV	AL, 48
  CLD
  SCASB
  JG	_SignCheck
  LOOP	_LowerCheck
  JMP	_True

_SignCheck:
  ; check if byte address is equal to address at beginning of string
  DEC	EDI					; undo SCASB increment
  MOV	ESI, [EBP + 32]	
  CMP	ESI, EDI			
  JNE	_False				

  ; check if byte is sign '+'/'-'
  MOV	AL, [ESI]
  CMP	AL, 43			
  JE	_IsSigned
  CMP	AL, 45			
  JE	_IsSigned
  JMP	_False

_IsSigned:
  ; restore SCASB increment and loop to _LowerCheck
  INC	EDI				
  LOOP	_LowerCheck
  
_True:
 ; set results variable to 1(True)
  MOV	EDI, [EBP + 24]	
  MOV	DWORD PTR [EDI], 1
  JMP	_End

_False:
; set results variable to 0(False)
  MOV	EDI, [EBP + 24]	
  MOV	DWORD PTR [EDI], 0

_End:
  RET	12
validate ENDP

; ---------------------------------------------------------------------------------
; Name: convertToDec
;
; Converts given string to its numerical value.
;
; Preconditions: variable used to store results is type SDWORD.
;				 variable used to check for overflow is type DWORD
;
; Postconditions: none.
;
; Receives: 
;		[EBP + 20]	= address of string to be converted
;		[EBP + 16]	= number of bytes in given string
;		[EBP + 12]	= address to store converted number
;		[EBP + 8]	= address to store overflow check: 1(True) or 0(False)
;		
;
; Returns: 
;		[EBP + 20]	= coverted number
;		[EBP + 8]	= overflow check result
; ---------------------------------------------------------------------------------

convertToDec PROC USES ESI EDI EAX EBX ECX
  ; inter_val	: stores the intermediate value during conversion
  ; is_negative	: stores (1) if passed value is positive or (0) if positive
  LOCAL	inter_val:DWORD, is_negative:DWORD

  ; set local variables to zero
  MOV	DWORD PTR [inter_val], 0
  MOV	DWORD PTR [is_negative], 0

  ; set variable used to check for an overflow to 0
  MOV	EDI, [EBP + 8]
  MOV	DWORD PTR [EDI], 0

  ; load given string into ESI
  MOV	ESI, [EBP + 20]

  ; set counter to number of bytes in given string
  MOV	ECX, [EBP + 16]

; --------------------------
; Checks if string of digits begins with sign '+'/'-'.
;	If the string begins with '+', the charcter is skipped.
;	If the string begins with '-', the character is skipped,
;	and the is_negative variable is set to 1. The is_negative
;	variable will be used later to negate the result.
; --------------------------
  ; move first charcter into AL
  CLD
  LODSB
  
  ; check if the first character in string is '+'
  DEC	ECX
  CMP	AL, 43				
  JE	_NextChar			

  ; check if first character in string is '-'
  CMP	AL, 45
  JNE	_ResetRegisters
  MOV	DWORD PTR [is_negative], 1			
  JMP	_NextChar							

_ResetRegisters:
  ; restore ESI and ECX if value is not '+'/'-'
  DEC ESI
  INC ECX

; --------------------------
; String together numerical values via algorithm from Module 8.1
;	If result is too large to fit in SDWORD, set the overflow 
;	checker and make no changes to variable designated to store
;	result.
; --------------------------
_NextChar:
  ; move character into AL
  CLD
  LODSB

  ; convert ASCII character to numerical value and move into EBX
  SUB	AL, 48
  MOVZX	EBX, AL

  ; add numerical value of ASCII charcter to the total 
  MOV	EAX, 10
  IMUL	inter_val
  JO	_Overflow
  MOV	inter_val, EAX
  ADD	inter_val, EBX

  ; check if new total fits in a SDWORD
  JO	_EdgeCaseCheck
  LOOP	_NextChar

  ; move final value into EAX
  MOV	EAX, inter_val
  JMP	_IsNegativeCheck

  ; check if overflow instance is the valid number -2147483648
_EdgeCaseCheck:
  CMP	is_negative, 1
  JNE	_Overflow
  CMP	inter_val, 2147483648
  JNE	_Overflow

  ; negate result if given value was negative
_IsNegativeCheck:
  CMP	is_negative, 1
  JNE	_StoreVal
  NEG	EAX

  ; store result in designated variable
_StoreVal:
  MOV	EDI, [EBP + 12]
  MOV	[EDI], EAX
  JMP	_End

_Overflow:
  ; set overflow check variable to 1(True)
  MOV	EDI, [EBP + 8]
  MOV	DWORD PTR [EDI], 1

_End:
  RET	16
convertToDec ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts a given number into a string and displays that number.
;
; Preconditions: number must be signed and fit within a 32 bit register.
;
; Postconditions: none.
;
; Receives: 
;		[EBP + 8]	= value to be displayed
;
; Returns: none.
; ---------------------------------------------------------------------------------

WriteVal PROC USES EDI ESI EAX EBX ECX EDX
  ; string_arr_1	: stores the initially generated string 
  ; string_arr_2	: stores string with characters in the proper order
  ; digit_total		: represents the value of a single digit at th end of the given number
  ; inter_value		: stores the intermediate value during conversion
  ; is_negative		: stores (1) if passed value is positive or (0) if positive
  LOCAL string_arr_1[11]:BYTE, string_arr_2[11]:BYTE, digit_total:BYTE, inter_value:DWORD, is_negative:DWORD

  ; set local variables to zero
  MOV	BYTE PTR [digit_total], 0
  MOV	BYTE PTR [is_negative], 0

  ; fill local string_arr_1 with zeros
  MOV	ECX, 11
  LEA	EAX, string_arr_1
  MOV	EDI, EAX
  MOV	AL, 0
  CLD
  REP STOSB

  ; fill local string_arr_2 with zeros
  MOV	ECX, 11
  LEA	EAX, string_arr_2
  MOV	EDI, EAX
  MOV	AL, 0
  CLD
  REP STOSB

  ; load string_arr_1 address into EDI
  LEA	EBX, string_arr_1
  MOV	EDI, EBX
  ADD	EDI, 10

  ; load given value into local variable inter_value
  MOV	EBX, [EBP + 8]
  MOV	inter_value, EBX

  ; check if value is negative
  MOV	EBX, inter_value
  CMP	EBX, 0
  JNS	_CheckVal
  NEG	inter_value				; change value to positive if negative
  INC	is_negative				; set is_negative to true

; --------------------------
; Decrements inter_value while simultaneously incrementing digit_total 
;	until the last digit in interm_value is zero. This is checked by
;	dividing the number by 10 and checking if the remainder is zero.
; --------------------------
_CheckVal:
  ; check if number is divisible by 10
  MOV	EAX, inter_value
  MOV	EDX, 0
  MOV	EBX, 10
  DIV	EBX
  CMP	EDX, 0					
  JE	_AddToString

  ; adjust inter_value and digit_total by 1 if not a multiple of 10
  DEC	inter_value
  INC	digit_total

  JMP	_CheckVal

; --------------------------
; Converts digit_total to its ASCII value and moves it into string_arr_1.
;	starting at the end of list and working backwards. This is done to
;	ensure characters are in the correct order at the end of the
;	string.
; --------------------------
_AddToString:
  ; convert digit_total to ASCII equivalent
  MOV	AL, digit_total
  ADD	AL, 48

  ; add ASCII character to string_arr_1
  STD
  STOSB

  ; reset digit_total to zero
  MOV	BYTE PTR digit_total, 0

; --------------------------
; Checks if interm_value is zero. If it is zero then jumps to _PrintVal
;	because the string now contains the full number. Else the number is
;	divided by 10 and the next digit of the sequence is examined.
; --------------------------
  ; check if interm_value is zero
  CMP	inter_value, 0
  JE	_PrintVal

  ; divide interm_value by 10
  MOV	EAX, inter_value
  MOV	EDX, 0
  MOV	EBX, 10
  DIV	EBX
  MOV	inter_value, EAX

  ; repeat process for next digit in interm_value
  JMP	_CheckVal

; --------------------------
; Moves ASCII values from string_arr_1 into string_arr_2.
;	The values are copied from the end of first string
;	array into the beginning of the second string array.
;	This allows the string to be displayed using
;	mDisplayString. If the passed number was negative, the
;	ASCII value for '-' is added to the beginning of the
;	second string prior to transfer.
; --------------------------
_PrintVal:

  ; move address of first string array to ESI
  LEA	EAX, string_arr_1
  MOV	ESI, EAX

  ; move address of second string array to EDI
  LEA	EAX, string_arr_2
  MOV	EDI, EAX

  ; set counter to length of the first and second string
  MOV	ECX, 11

_NegativeVal:
  ; add '-' sign to beginning of second string if passed value was negative
  CMP	is_negative, 1
  JNE	_ReadChar
  MOV	AL, 45
  CLD
  STOSB

_ReadChar:
  ; load byte value from first string array and check if equal to zero
  CLD
  LODSB
  CMP	AL, 0
  JNE	_CopyToNewArr
  LOOP	_ReadChar

_CopyToNewArr:
  ; add byte value to the second string array 
  CLD
  STOSB
  LOOP	_ReadChar

  ; display converted value
  LEA	EAX, string_arr_2
  mDisplayString EAX

  RET	4
WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: calculateSum
;
; Calculates the sum of a given list of numbers.
;
; Preconditions: list must be type SDWORD. The list of numbers length should
;	be equal to the value in the constant NUM_ARR_LENGth.
;
; Postconditions: none.
;
; Receives: 
;		[EBP + 12]	= list of numbers
;		[EBP + 8]	= address of empty variable to store sum
;		NUM_ARR_LENGTH is global variable/constant
;
; Returns: [EBP + 8] = sum of values in list
; ---------------------------------------------------------------------------------

calculateSum PROC USES EDI ESI EAX ECX
  ; inter_sum	: used to track the value of sum between calculations
  LOCAL inter_sum:SDWORD

  ; set local variables to zero
  MOV	SDWORD PTR [inter_sum], 0

  ; set counter to length of array
  MOV	ECX, NUM_ARR_LENGTH

  ; move num list into ESI
  MOV	ESI, [EBP + 12]

; --------------------------
; Loop through the given array. Add each indexed value in
;	num list to inter_sum. Then move result into designated
;	sum variable.
; --------------------------
_NextVal:
  ; add value at [ESI] to local sum
  MOV	EAX, [ESI]
  ADD	inter_sum, EAX

  ; move to next index num array
  ADD	ESI, 4
  LOOP	_NextVal

  ; move the sum value into designated sum variable
  MOV	EDI, [EBP + 8]
  MOV	EAX, inter_sum
  MOV	[EDI], EAX

  RET	8
calculateSum ENDP

; ---------------------------------------------------------------------------------
; Name: calculateTruncAvg
;
; Calculates the truncated average from a given sum.
;
; Preconditions: The value passed should be the sum of a list of numbers. The list of numbers
;	length should be equal to the value in the constant NUM_ARR_LENGTH.
;
; Postconditions: none.
;
; Receives: 
;		[EBP + 24]	= sum of a list of numbers
;		[EBP + 20]	= address of empty variable to store truncated average 
;		NUM_ARR_LENGTH is global variable/constant
;
; Returns: [EBP + 20] = truncated average
; ---------------------------------------------------------------------------------

calculateTruncAvg PROC USES	EBP EDI EAX EBX EDX
  MOV	EBP, ESP

  ; divide sum by the size of the list
  MOV	EAX, [EBP + 28]
  CDQ
  MOV	EBX, NUM_ARR_LENGTH
  IDIV	EBX

  ; move results into truncated average variabled passed on the stack
  MOV	EDI, [EBP + 24]
  MOV	[EDI], EAX

  RET	8
calculateTruncAvg ENDP

END main


