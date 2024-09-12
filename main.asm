; *****************************************************************
;  Name: [Isabella]
;  Description: Using threading, find how many happy nums and sad nums are between a given
;                index. Happy nums are sums of squares that = 1, sad nums are sums of squares
;                that = 4. Using threading allows this process to be completed faster,
;                better run times will be achieved using threading.

; -----
;  Results:
;	Count of happy/sad numbers between 1 and 1000 (5bc, b-13): 
;		Happy Numbers: 143
;		Sad Numbers:   857

;	Count of happy/sad numbers between 1 and 40000000 (8396851, b-13):
;		Happy Count: 5577647
;		Sad Count:   34422353

; ***************************************************************

section	.data

; -----
;  Define standard constants.

LF		equ	10			; line feed
NULL		equ	0			; end of string
ESC		equ	27			; escape key

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; Successful operation
NOSUCCESS	equ	1			; Unsuccessful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; call code for read
SYS_write	equ	1			; call code for write
SYS_open	equ	2			; call code for file open
SYS_close	equ	3			; call code for file close
SYS_fork	equ	57			; call code for fork
SYS_exit	equ	60			; call code for terminate
SYS_creat	equ	85			; call code for file open/create
SYS_time	equ	201			; call code for get time

; -----
;  Variables/constants for thread function.

msgThread1	db	"    ...Thread starting...", LF, NULL
spc		db	"   ", NULL

idxCounter	dq	1
myLock		dq	0

COUNT_SET	equ	100

; -----
;  Variables for printMessageValue

newLine		db	LF, NULL

; -----
;  Variables/constants for getCommandLineArgs function

THREAD_MIN	equ	1
THREAD_MAX	equ	4

LIMIT_MIN	equ	10
LIMIT_MAX	equ	4000000000

errUsage	db	"Usgae: ./happyNums -t<1|2|3|4> ",
		db	"-lm <base13Number>", LF, NULL
errOptions	db	"Error, invalid command line options."
		db	LF, NULL
errTSpec	db	"Error, invalid thread count specifier."
		db	LF, NULL
errLMSpec	db	"Error, invalid limit specifier."
		db	LF, NULL
errLMValue	db	"Error, limit invalid."
		db	LF, NULL

tmpNum	dd	0

; ***************************************************************

section	.text

; ******************************************************************
;  Function getCommandLineArgs()
;	Get, check, convert, verify range, and return the
;	sequential/parallel option and the limit.

global getCommandLineArgs
getCommandLineArgs:

;push needed registers
push r12
push rbx

mov r12, 0
mov r12, rsi

;check arg count is correct
cmp rdi, 1
je	errorUse
cmp rdi, 4
jne	errorOp

;check for valid args
mov rbx, 0
mov r8, 0
mov rbx, qword[r12+8]   ;argv[1] address
mov r8b, byte[rbx]		;argv[1]
cmp r8b, 45				;"-"
jne errorOp
mov r8b, byte[rbx+1]
cmp r8b, 116			;"t"
jne errorOp
mov r8b, byte[rbx+2]
sub r8b, "0"			;get thread count to integer
cmp r8b, THREAD_MIN		;1
jb errTs	
cmp r8b, THREAD_MAX		;4
ja errTs	
mov r8b, byte[rbx+3]
cmp r8b, NULL
jne errTs

mov r8b, byte[rbx+2]	;get the thread count again
sub r8b, "0"

mov dword[rdx], r8d		;set thread count
mov edx, dword[rdx]		;get thread count

mov rbx, qword[r12+16]  ;argv[2] address
mov r8b, byte[rbx]		;argv[2]
cmp r8b, 45				;"-"
jne errLMS
mov r8b, byte[rbx+1]
cmp r8b, 108			;"l"
jne errLMS	
mov r8b, byte[rbx+2]
cmp r8b, 109			;"m"
jne errLMS	
mov r8b, byte[rbx+3]
cmp r8b, NULL		
jne errLMS

;Take final argument
mov rdi, 0				;reset rdi
mov rdi, qword[r12+24]	;argv[3] value
mov rsi, tmpNum			;for converted value address
call cvtB132int			;convert value for checking
cmp rax, 1				;function return true
jne errLMV				;if not successful cnvt then error

;check limits of converted value
mov r9, 0					;reset r9
mov r9d, dword[tmpNum]		;grab value
cmp r9d, LIMIT_MIN			
jb errLMV
cmp r9d, LIMIT_MAX
ja errLMV

mov dword[rcx], r9d
mov ecx, dword[rcx]


mov rax, 0				;clear junk
;no other errors thrown, we set rax to true
mov rax, 1
jmp endParam

;*****Error Jumps****
errorUse:
	mov rdi, errUsage
	call printString
	mov rax, 0
	jmp endParam
errorOp:
	mov rdi, errOptions
	call printString	
	mov rax, 0
	jmp endParam	
errTs:
	mov rdi, errTSpec
	call printString	
	mov rax, 0
	jmp endParam	
errLMS:
	mov rdi, errLMSpec
	call printString	
	mov rax, 0
	jmp endParam	
errLMV:
	mov rdi, errLMValue
	call printString	
	mov rax, 0
	jmp endParam
;******************
endParam:
mov rsi, r12	;preserve

pop rbx
pop r12
ret

; ******************************************************************
;  Function: Check and convert ASCII/base13 string
;  		to integer.

global cvtB132int
cvtB132int:

;push registers
push rdx
push r12
push r13
push r14
push r15

;********CONVERSION*********
mov rax, 0			;running sum
mov r10, 0
mov r11, 0
mov r11b, byte[rdi+r10]
	convertLoop:
		;check for NULL 
		cmp r11b, NULL
			je endFunc	;if so break out of loop

		;the char is an upper case letter
		cmp r11b, 65
			je isUpper
		cmp r11b, 66
			je isUpper
		cmp r11b, 67
			je isUpper

		;the char is a lower case letter
		cmp r11b, 97
			je isLower
		cmp r11b, 98
			je isLower
		cmp r11b, 99
			je isLower
	
		;the char is a NUMBER 0 - 9
		cmp r11b, 48
			je isNum
		cmp r11b, 49
			je isNum
		cmp r11b, 50
			je isNum
		cmp r11b, 51
			je isNum
		cmp r11b, 52
			je isNum
		cmp r11b, 53
			je isNum
		cmp r11b, 54
			je isNum
		cmp r11b, 55
			je isNum
		cmp r11b, 56
			je isNum
		cmp r11b, 57
			je isNum

		jmp invalid

		isDone:
		;r11 is intDigit
		movzx r15, r11b
		mov r13, r15
		;running sum = running sum * 13
		mov r14, 13
		mul r14
		;running sum = running sum + intDig
		add rax, r13

		skip:
		inc r10
		mov r11b, byte[rdi+r10]
		jmp convertLoop


jmp endFunc
;********CNV JUMPS***********
invalid:
		mov rax, 0	;false
		jmp failedCnvt	
isUpper:
		sub r11b, 65
		add r11b, 10
		jmp isDone

isLower:
		sub r11b, 97
		add r11b, 10
		jmp isDone	

isNum:
		sub r11b, 48
		jmp isDone
;****************************

endFunc:
mov dword[rsi], eax		;store running sum into address
mov rax, 0				;RESET
mov rax, 1				;TRUE, able to convert

failedCnvt:
pop r15
pop r14
pop r13
pop r12
pop rbx
ret

; ******************************************************************
;  Generic function to display a string to the screen.
;  String must be NULL terminated.
;  Algorithm:
;	Count characters in string (excluding NULL)
;	Use syscall to output characters

;  Arguments:
;	- address, string
;  Returns:
;	nothing

global	printString
printString:

; -----
; Count characters to write.

	mov	rdx, 0
strCountLoop:
	cmp	byte [rdi+rdx], NULL
	je	strCountLoopDone
	inc	rdx
	jmp	strCountLoop
strCountLoopDone:
	cmp	rdx, 0
	je	printStringDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of characters to write
	mov	rdi, STDOUT			; file descriptor for standard in
						; rdx=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

printStringDone:
	ret

; ******************************************************************
;  Thread function, findHappyNumbers()
;	Find happy numbers.

; -----
;  Global variables accessed.

common	numberLimit	1:8
common	happyCount	1:8
common	sadCount	1:8

; -----
;  Arguments:
;	N/A (global variable accessed)
;  Returns:
;	N/A (global variable accessed)

global findHappyNumbers
findHappyNumbers:
push rbx
push r12
push r13
push r14
push r15			

mov rdi, msgThread1
call printString	
mov rbx, 10				;for math in calculation

newIndex:
;obtain a new set of numbers to look at per thread
call spinLock	
	mov r12, qword[idxCounter]			;store prev counter
	add qword[idxCounter], COUNT_SET
	mov r13, qword[idxCounter]			;store curr counter
call spinUnlock

;if setN > numberLimit, EXIT
cmp r12, qword[numberLimit]
ja end

;while(true)... while still in setN or between r12 and r13
nLoop:									;overall number increment loop for index
	cmp r12, qword[numberLimit]			;check curr > limit
	ja end

	cmp r12, r13						;ensure old counter is less than new
	jae newIndex	

	mov r10, r12	;for dec/inc
	runAgain:
		mov r15, 0	;is sum
		mov r8, 0

	;calculate the sum of squares until either 1 or 4
	sumSQLoop:			;while num > 0...loop for just the number we are calculating
		cmp r10, 0		
		jbe emoteHS

		mov rdx, 0		;clear for rdx:rax 
		mov rax, r10	;set to the number
		div rbx			;num % 10
		mov r10, rax	;quotient
		mov r9, rdx		;store remainder
		mov rax, r9		
		mul r9			;rem ^ 2
		add r15, rax	;sum = sum + (rem * rem)
		jmp sumSQLoop


;*******JUMPS*********
;increment happy count and loop again
happyNum:
	lock inc qword[happyCount]
	inc r12						;next number
	jmp nLoop

;increment sound count and loop again
sadNum:
	lock inc qword[sadCount]
	inc r12						;next number
	jmp nLoop	

emoteHS:
	cmp r15, 1
	je happyNum
	cmp r15, 4
	je sadNum
	mov r10, r15	;if none of above flagged, do another sum of squares
	jmp runAgain	;loop again with new number until either 1 or 4
;**********************
end:
pop r15
pop r14
pop r13
pop r12
pop rbx
ret


; ******************************************************************
;  Mutex lock
;	checks lock (shared gloabl variable)
;		if unlocked, sets lock
;		if locked, lops to recheck until lock is free

global	spinLock
spinLock:
	mov	rax, 1			; Set the REAX register to 1.

lock	xchg	rax, qword [myLock]	; Atomically swap the RAX register with
					;  the lock variable.
					; This will always store 1 to the lock, leaving
					;  the previous value in the RAX register.

	test	rax, rax	        ; Test RAX with itself. Among other things, this will
					;  set the processor's Zero Flag if RAX is 0.
					; If RAX is 0, then the lock was unlocked and
					;  we just locked it.
					; Otherwise, RAX is 1 and we didn't acquire the lock.

	jnz	spinLock		; Jump back to the MOV instruction if the Zero Flag is
					;  not set; the lock was previously locked, and so
					; we need to spin until it becomes unlocked.
	ret

; ******************************************************************
;  Mutex unlock
;	unlock the lock (shared global variable)

global	spinUnlock
spinUnlock:
	mov	rax, 0			; Set the RAX register to 0.

	xchg	rax, qword [myLock]	; Atomically swap the RAX register with
					;  the lock variable.
	ret

; ******************************************************************

