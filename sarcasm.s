global _main

global start


section .text
_main:
	mov rax, 25
label:
	push byte 0x21
	call putchar

	add rax, -1

	cmp rax, 0
	jne label
	
	mov rax, 0x2000001 ; exit
	mov rdi, 0
	syscall
	

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
