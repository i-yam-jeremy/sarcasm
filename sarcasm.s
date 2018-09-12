global _main

section .data
	virtual_stack dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

section .text
default rel
_main:
	mov dword [virtual_stack], 0x22
	mov rcx, [virtual_stack]
	push byte rcx
	call putchar

	add rbx, 1
	add rax, -1

	push byte 0xA
	call putchar

	
	mov rax, 0x2000001 ; exit
	mov rdi, 0
	syscall

; TODO global variable that is large array that can be used for the stack and a separate stack "pointer" that is the index in the array (or allocate space on stack for this virtual stack by adding to the stack pointer)
	

putchar: ; clears rdx and rcx
	pop word rdx ; pop return address
	pop byte rcx ; pop argument
	push word rdx ; push return address
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
