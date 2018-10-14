global _main

%define STACK_SIZE 100

section .bss
	stack: resq STACK_SIZE 

section .data
	stack_pos: dq 0

	unread_char: dq -1

	number_format_string: db "%ld", 0xA, 0

	stack_overflow_message: db "Stack overflow", 0xA
	.len: equ $ - stack_overflow_message

	stack_underflow_message: db "Stack underflow", 0xA
	.len: equ $ - stack_underflow_message
	
	padding_char_used: dq 0
	
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
testlabel:
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
	cmp cl, '^'
	je op_pow
	cmp cl, '@'
	je op_dup

	
	mov rcx, 0x21
	call putchar
	call popstack
	mov rdi, rcx
	mov rax, 0x2000001 ; exit
	;mov rdi, 0 
	syscall

op_add:
	call popstack
	mov rax, rcx
	call popstack
	add rcx, rax
	call pushstack

	jmp parserloop

op_sub:
	call popstack
	mov rax, rcx
	call popstack
	sub rcx, rax
	call pushstack

	jmp parserloop

op_mul:
	call popstack
	mov rax, rcx
	call popstack
	imul rcx
	mov rcx, rax
	call pushstack

	jmp parserloop

op_div: ;; TODO FIXME div
	call popstack
	mov rax, rcx
	call popstack
	mov rdx, 0
	div rcx
	mov rcx, rax
	call pushstack

	jmp parserloop

op_mod: ;; TODO FIXME div
	call popstack
	mov rax, rcx
	call popstack
	mov rdx, 0
	div rcx
	mov rcx, rdx
	call pushstack

	jmp parserloop

op_pow: ; TODO
	call popstack
	mov rax, rcx
	call popstack
	add rcx, rax
	call pushstack

	jmp parserloop

op_dup:
	call popstack
	call pushstack
	call pushstack

	jmp parserloop

whitespace:
	jmp parserloop ; ignore and keep looping

read_number: ; parse a number literal from stdin and returns result in rax
	mov rax, 0

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

_read_number_end:
	call unread
	ret

pushstack: ; takes argument in rcx
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

stackoverflow:
	mov rax, 0x2000004 ; write
	mov rdi, 1 ; stdout
	mov rsi, stack_overflow_message
	add rsi, -20 ;; fixes offset
	mov rdx, stack_overflow_message.len
	syscall

	jmp error

popstack: ; returns result in rcx
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

stackunderflow:
	mov rax, 0x2000004 ; write
	mov rdi, 1 ; stdout
	mov rsi, stack_underflow_message
	add rsi, -36 ;; fixes offset
	mov rdx, stack_underflow_message.len
	add rdx, 1 ; increment by 1 to include '\n'
	syscall

	jmp error

unread: ; unreads a single character given in rcx (cannot be called multiple times without reading)
	mov [unread_char], rcx
	ret

readchar: ; returns result in rcx
	push rax
	push rdx

	cmp qword [unread_char], -1
	jne _readchar_unread_char
	; perform normal read because no unread char
	mov rax, 0x2000003 ; read
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

end_of_file:
	call popstack
	mov rsi, rcx
	mov rdi, number_format_string
	add rdi, -16
	;;mov rbx, 0xFFFF
	;;shl rbx, 48
	push rcx ;; to offset stack
	call _printf
	
	mov rax, 0x2000001 ; exit
	mov rdi, 0
	syscall

error:	
	mov rax, 0x2000001 ; exit
	mov rdi, 17
	syscall
