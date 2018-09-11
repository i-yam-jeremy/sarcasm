global _main

global start


section .text
_main:
label:
	mov rcx, 0x21
	call putchar
	
	mov rax, 0x2000001 ; exit
	mov rdi, 0
	syscall
	

putchar:
	mov rax, 0x2000004 ; write
	mov rdi, 1 ; stdout
	push byte rcx
	mov rsi, rsp
	mov rdx, 1
	syscall
	pop byte rcx
	ret
