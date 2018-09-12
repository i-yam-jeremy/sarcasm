global _main

section .data
	stack dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	stack_pos dq 0

section .text
default rel
_main:
	mov rcx, 0x21
	call pushstack
	mov rcx, 0x22
	call pushstack

	xor rcx, rcx ; clear rcx
	
	call popstack
	call putchar
	call popstack
	call putchar

	mov rcx, 0xA
	call putchar

	
	mov rax, 0x2000001 ; exit
	mov rdi, 0
	syscall

pushstack: ; takes argument in rcx
	mov rax, [stack_pos]
	mov rbx, stack
	mov [rbx + 8*rax], rcx
	add rax, 1
	mov [stack_pos], rax
	ret

popstack: ; returns result in rcx
	mov rax, [stack_pos]
	add rax, -1
	mov rbx, stack
	mov rcx, [rbx + 8*rax]
	mov [stack_pos], rax
	ret

putchar: ; takes argument in rcx
	mov rax, 0x2000004 ; write
	mov rdi, 1 ; stdout
	push rcx
	mov rsi, rsp
	mov rdx, 1
	syscall
	pop rcx
	ret
