global _main

section .data
	stack dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	stack_pos dq 0

section .text
default rel
_main:
	push 0x21
	call pushstack
	push 0x22
	call pushstack
	mov rcx, [stack]
	push rcx
	call putchar
	mov rcx, [stack+8]
	push rcx
	call putchar

	push 0xA
	call putchar

	
	mov rax, 0x2000001 ; exit
	mov rdi, 0
	syscall

; TODO global variable that is large array that can be used for the stack and a separate stack "pointer" that is the index in the array (or allocate space on stack for this virtual stack by adding to the stack pointer)

pushstack:
	pop rdx
	pop rcx
	push rdx
	mov rax, [stack_pos]
	mov rbx, stack
	mov [rbx + 8*rax], rcx
	add rax, 1
	mov [stack_pos], rax
	ret	

putchar: ; clears rdx and rcx
	pop rdx ; pop return address
	pop rcx ; pop argument
	push rdx ; push return address
	push rax
	push rdi
	push rdx
	push rsi
	mov rax, 0x2000004 ; write
	mov rdi, 1 ; stdout
	push byte rcx
	mov rsi, rsp
	mov rdx, 1
	syscall
	pop byte rcx
	pop rsi
	pop rdx
	pop rdi
	pop rax
	ret
