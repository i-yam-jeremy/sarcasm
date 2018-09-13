global _main

section .data
	stack dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	stack_pos dq 0

	unread_char dq -1

section .text
default rel
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
	
	mov rcx, 0x21
	call putchar
	mov rdi, [stack_pos]
	mov rax, 0x2000001 ; exit
	;mov rdi, 0 
	syscall

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
	mov rbx, stack
	mov [rbx + 8*rax], rcx
	add rax, 1
	mov [stack_pos], rax
	pop rbx
	pop rax
	ret

popstack: ; returns result in rcx
	push rax
	push rbx

	mov rax, [stack_pos]
	add rax, -1
	mov rbx, stack
	mov rcx, [rbx + 8*rax]
	mov [stack_pos], rax

	pop rbx
	pop rax
	ret
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
	je error

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

error:	
	mov rax, 0x2000001 ; exit
	mov rdi, 17
	syscall
