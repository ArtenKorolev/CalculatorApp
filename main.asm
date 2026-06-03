global _start

SYS_WRITE: equ 1
SYS_READ: equ 0

FD_STDOUT: equ 1
FD_STDIN: equ 0

BUFSIZ: equ 16
PRINTBUFSIZ: equ 10

%macro printString 2
	mov rsi, %1
	mov rdx, %2 
    call _printString
%endmacro

_printString:
	mov rax, SYS_WRITE
	mov rdi, FD_STDOUT
	syscall
    ret

_inputBuffer:
	mov rax, SYS_READ
	mov rdi, FD_STDIN
	mov rsi, buffer
	mov rdx, BUFSIZ
	syscall
	dec rax
    ret

_inputOperationChar:
    mov rax, SYS_READ
    mov rdi, FD_STDIN
    mov rsi, operationChar
    mov rdx, 1
    syscall
    ret

_inputDummy:
    mov rax, SYS_READ
    mov rdi, FD_STDIN
    mov rsi, dummy
    mov rdx, 1
    syscall
    ret

%macro exit 1
	mov rax, 60
	mov rdi, %1
	syscall
%endmacro

section .data
    invalidNumberInputMsg: db "You entered invalid number!", 0xa
	invalidNumberInputMsgLen: equ $ - invalidNumberInputMsg
    printBuffer: db "0000000000", 0xa 

section .bss
    operationChar: resb 1
    dummy: resb 1
    buffer: resb BUFSIZ

section .text
_start: 
    call _mainLoop
	exit 0

%macro printInt 1
    mov rax, %1
    call _printInteger
%endmacro

_mainLoop:
    call _inputBuffer 
    call _convertBufferToInteger2
    mov r15, rax

    call _inputOperationChar
    call _inputDummy

    call _inputBuffer 
    call _convertBufferToInteger2
    mov r14, rax

    cmp byte [operationChar], '+'
    jne .LL1
    add r15, r14
    printInt r15
    jmp _mainLoop
.LL1:
    cmp byte [operationChar], '-'
    jne .LL2
    sub r15, r14
    printInt r15
    jmp _mainLoop
.LL2:

    call _clearPrintBuffer
    jmp _mainLoop

; _convertBufferToInteger Converts a string view of an integer
; to real integer and leaves it in a register
; Params:
; RAX = Length of the string view of the integer
; buffer = String view of the integer 

; Used registers:
; RCX = To store index in the string view
; R9 = Place counter 
; RDX = To store current char in buffer

; Out registers:
; RAX = Result

_convertBufferToInteger:
	cmp rax, 0
	je _invalidNumberInput
	mov rcx, rax 
	dec rcx  
	mov r9, 1 
    xor rax, rax

.LL1:
	movzx rdx, byte [buffer + rcx] 
	cmp rdx, '0'
	jb _invalidNumberInput
	cmp rdx, '9'
	ja _invalidNumberInput
	sub rdx, '0' 
    imul rdx, r9
    add rax, rdx 
	imul r9, r9, 10
	dec rcx 
	cmp rcx, -1
	jne .LL1 

	ret

_convertBufferToInteger2:
	cmp rax, 0
	je _invalidNumberInput
    mov r10, rax ; Save maximum index
    xor rcx, rcx
    xor rax, rax
    mov r9b, 1 ; Coef to calc negatives (default positive, coef = 1)

    movzx rdx, byte [buffer + rcx]
    cmp rdx, '-'
    jne .LL5
    neg r9b
    inc rcx

.LL5:
    cmp rcx, r10
    jae .LL6

    movzx rdx, byte [buffer + rcx]

	cmp rdx, '0'
	jb _invalidNumberInput
	cmp rdx, '9'
	ja _invalidNumberInput

	sub rdx, '0' 

    imul rax, rax, 10 ; rax *= 10
    add rax, rdx

    inc rcx
    jmp .LL5

.LL6:
    imul rax, r9 ; rax *= r9
    ret

; _printInteger Prints integer in RAX to the screen using printBuffer
; Params:
; RAX = integer

; Used registers:
; R9 = Base for dividing
; RCX = Counter
; RDX for remainder after division

_printInteger:
    mov rcx, PRINTBUFSIZ - 1
    mov r9, 10

.LL2:
    cmp rax, 0
    je .LL3

    xor rdx, rdx
    div r9 
    add dl, '0'

    mov byte [printBuffer + rcx], dl

    dec rcx
    cmp rcx, -1
    jne .LL2
.LL3:
    printString printBuffer, PRINTBUFSIZ + 1
    call _clearPrintBuffer
    ret

_clearPrintBuffer:
    mov rcx, PRINTBUFSIZ - 1
.LL4:
    mov byte [printBuffer + rcx], '0'
    dec rcx
    cmp rcx, -1
    jne .LL4 

    ret

_invalidNumberInput:
	printString invalidNumberInputMsg, invalidNumberInputMsgLen
	exit 1
