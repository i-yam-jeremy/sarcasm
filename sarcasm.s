global _main

;; Size of the virtual stack (in elements, not bytes)
%define STACK_SIZE 100

;; syscall code for exit
%define SYSCALL_EXIT 0x2000001
;; syscall code for read
%define SYSCALL_READ 0x2000003

section .bss
	;; The virtual stack
	stack: resq STACK_SIZE 

section .data
	;; The current position in the virtual stack
	stack_pos: dq 0

	;;
	unread_char: dq -1

	;; printf format string for printing long
	number_format_string: db "%ld", 0xA, 0

	;; Message for when stack overflow occurs
	stack_overflow_message: db "Stack overflow", 0xA, 0

	;; Message for when stack underflow occurs
	stack_underflow_message: db "Stack underflow", 0xA, 0
	
	;; Message for when an unknown character occurs
	unknown_character_message: db "Unknown character: %c", 0xA, 0

section .text
default rel

extern _printf

_main:
parserloop:
	call readchar
	
	cmp cl, '0'
	jb notnumber
	cmp cl, '9'
	ja notnumber

	call unread
	call read_number
	mov rcx, rax
	call pushstack

	jmp parserloop

notnumber:
	cmp cl, ' '
	je whitespace
	cmp cl, 0x09 ; '\t'
	je whitespace
	cmp cl, 0x0A ; '\n'
	je whitespace
	cmp cl, 0x0D ; '\r'
	je whitespace


	cmp cl, '+'
	je op_add
	cmp cl, '-'
	je op_sub
	cmp cl, '*'
	je op_mul
	cmp cl, '/'
	je op_div
	cmp cl, '%'
	je op_mod
	cmp cl, '@'
	je op_dup


	jmp unknown_character	

;; unknown character has occurred
unknown_character:
	mov rsi, rcx ;; the character that occurred
	mov rdi, unknown_character_message
	add rdi, -54 ;; fixes offset
	add rsp, -8 ;; align stack
	call _printf
	push qword 1
	call exit

;; add the top two elements on the stack
op_add:
	call popstack
	mov rax, rcx
	call popstack
	add rcx, rax
	call pushstack

	jmp parserloop

;; subtract the top two elements on the stack
;; 10 2 - is equivalent to 10 - 2
op_sub:
	call popstack
	mov rax, rcx
	call popstack
	sub rcx, rax
	call pushstack

	jmp parserloop

;; multiply the top two elements on the stack
op_mul:
	call popstack
	mov rax, rcx
	call popstack
	imul rcx
	mov rcx, rax
	call pushstack

	jmp parserloop

;; divide the top two elements on the stack
;; 10 2 / is equivalent to 10 / 2
op_div:
	call popstack
	mov rbx, rcx
	call popstack
	mov rax, rcx
	mov rdx, 0
	div rbx
	mov rcx, rax
	call pushstack

	jmp parserloop

;; mod the top two elements on the stack
;; 10 2 % is equivalent to 10 % 2
op_mod:
	call popstack
	mov rbx, rcx
	call popstack
	mov rax, rcx
	mov rdx, 0
	div rbx
	mov rcx, rdx
	call pushstack

	jmp parserloop

;; duplicate the top element on the stack
op_dup:
	call popstack
	call pushstack
	call pushstack

	jmp parserloop

;; handle whitespace
whitespace:
	jmp parserloop ; ignore and keep looping

;; reads a number literal from stdin and returns the result in rax
read_number:
	mov rax, 0

;; loops over each character in stdin until a non-digit occurs
_read_number_loop:
	call readchar 	
	cmp cl, '0'
	jb _read_number_end
	cmp cl, '9'
	ja _read_number_end

	imul rax, 10

	and rcx, 0xFF	
	add rcx, -0x30 ; subtract '0' to convert ASCII character value to integer value
	add rax, rcx

	jmp _read_number_loop

;; encountered a non-digit
_read_number_end:
	call unread
	ret

;; pushes the value of rcx to the virtual stack
pushstack:
	push rax
	push rbx
	mov rax, [stack_pos]
	cmp al, STACK_SIZE
	jge stackoverflow
	mov rbx, stack
	mov [rbx + 8*rax], rcx
	add rax, 1
	mov [stack_pos], rax
	pop rbx
	pop rax
	ret

;; when the stack has exceeded the maximum size
stackoverflow:
	mov rdi, stack_overflow_message
	add rdi, -21 ;; fixes offset
	call _printf

	jmp error

;; pops a value from the virtual stack and returns the result in rcx
popstack:
	push rax
	push rbx

	mov rax, [stack_pos]
	add rax, -1
	cmp rax, 0
	jl stackunderflow
	mov rbx, stack
	mov rcx, [rbx + 8*rax]
	mov [stack_pos], rax

	pop rbx
	pop rax
	ret

;; when the stack is popped with zero elements in the stack
stackunderflow:
	mov rdi, stack_underflow_message
	add rdi, -37 ;; fixes offset
	call _printf
	jmp error

;; unreads a single character given in rcx (cannot be called multiple times without reading)
unread:
	mov [unread_char], rcx
	ret

;; reads a character from stdin (or the unread character) and returns the result in rcx
readchar:
	push rax
	push rdx

	cmp qword [unread_char], -1
	jne _readchar_unread_char
	; perform normal read because no unread char
	mov rax, SYSCALL_READ
	mov rdi, 0
	push rcx ; value is ignored, just location on stack is necessary
	mov rsi, rsp
	mov rdx, 1
	syscall
	cmp rax, 0
	je end_of_file

	pop rcx

	pop rdx
	pop rax
	ret

;; there was an unread character, so return that instead of reading from stdin
_readchar_unread_char:
	mov rcx, [unread_char]
	mov qword [unread_char], -1

	pop rdx
	pop rax
	ret

putchar: ; takes argument in rcx
	push rax
	push rdx
	mov rax, 0x2000004 ; write
	mov rdi, 1 ; stdout
	push rcx
	mov rsi, rsp
	mov rdx, 1
	syscall
	pop rcx
	pop rdx
	pop rax
	ret

;; reached the end of stdin
end_of_file:
	call popstack
	mov rsi, rcx
	mov rdi, number_format_string
	add rdi, -16
	;;mov rbx, 0xFFFF
	;;shl rbx, 48
	push rcx ;; to offset stack
	call _printf
	
	push qword 0
	call exit

;; exits the program with the status given by the top qword on the stack (real stack not virtual stack)
exit:
	pop rdi
	mov rax, SYSCALL_EXIT
	syscall

error:	
	mov rax, 0x2000001 ; exit
	mov rdi, 17
	syscall
