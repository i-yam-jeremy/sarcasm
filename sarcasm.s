global _main

section .data
	stack dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	stack_pos dq 0

section .text
default rel
_main:
	mov rax, 0
parserloop:
	call readchar
	cmp cl, 0x30 ; '0'
	jb notnumber
	cmp cl, 0x39 ; '9'
	ja notnumber

	imul rax, 10
	add rcx, -0x30
	add rax, rcx

	jmp parserloop

notnumber:
	mov rcx, 0x21
	call putchar
	mov rdi, rax
	mov rax, 0x2000001 ; exit
	;mov rdi, 0 
	syscall

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

readchar: ; returns result in rcx
	push rax
	push rdx

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
