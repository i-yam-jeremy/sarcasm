global _main

%define STACK_SIZE 10000
%define CALL_STACK_SIZE 10000
; SOURCE_BUFFER_SIZE - max file size
%define SOURCE_BUFFER_SIZE 1000000

%define MAX_LABEL_COUNT 1000

section .bss
	stack: resq STACK_SIZE
	call_stack: resq  CALL_STACK_SIZE
	source: resb SOURCE_BUFFER_SIZE
	labels: resq MAX_LABEL_COUNT

section .data
	stack_pos: dq 0
	call_stack_pos: dq 0
	source_pos: dq 0

	stack_overflow_message: db "Stack overflow", 0xA
	.len: equ $ - stack_overflow_message

	stack_underflow_message: db "Stack underflow", 0xA
	.len: equ $ - stack_underflow_message
	
	source_overflow_message: db "Source overflow: stdin too long", 0xA
	.len: equ $ - source_overflow_message
	
section .text
default rel
_main:
	mov rax, 0 ; source pos
	mov rbx, source
read_source_loop:
	call readchar
	mov byte [rbx+rax], cl
	add rax, 1
	cmp rax, SOURCE_BUFFER_SIZE
	jge source_overflow
	jmp read_source_loop

source_overflow:
	mov rax, 0x2000004 ; write
	mov rdi, 1 ; stdout
	mov rsi, source_overflow_message
	add rsi, -55 ;; fixes offset
	mov rdx, source_overflow_message.len
	syscall

	jmp error


preprocess:
	mov rax, 0 ; source pos
	mov rdx, 0 ; label index
preprocess_loop:
	mov rbx, source
	mov rcx, [rbx + rax]
	add rax, 1
	cmp rcx, ':'
	je add_label_marker
	cmp rcx, 0 ; if reached end of source
	je execute

	jmp preprocess_loop

add_label_marker:
	mov rbx, labels
	mov [rbx + 8*rdx], rax ; move source pos into label data
	add rdx, 1 ; increment label index
	jmp preprocess_loop

read_source_at_pos: ; read source at pos specified by rcx
	mov rax, source
	mov cl, [rax + rcx]
	ret

execute:
	mov qword [source_pos], 0

execloop:
	mov rcx, [source_pos]
	call read_source_at_pos
	add qword [source_pos], 1

	cmp cl, '0'
	jb notnumber
	cmp cl, '9'
	ja notnumber

	call read_number
	mov rcx, rax
	call pushstack

	jmp execloop

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
	cmp cl, '#'
	je op_addr
	cmp cl, '='
	je op_eq
	cmp cl, '<'
	je op_lt
	cmp cl, '>'
	je op_gt
	cmp cl, '.'
	je op_call
	cmp cl, '~'
	je op_ret
	cmp cl, ':'
	je op_label

	
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

	jmp execloop

op_sub:
	call popstack
	mov rax, rcx
	call popstack
	sub rcx, rax
	call pushstack

	jmp execloop

op_mul:
	call popstack
	mov rax, rcx
	call popstack
	imul rcx
	mov rcx, rax
	call pushstack

	jmp execloop

op_div: ;; TODO FIXME div
	call popstack
	mov rax, rcx
	call popstack
	mov rdx, 0
	div rcx
	mov rcx, rax
	call pushstack

	jmp execloop

op_mod: ;; TODO FIXME div
	call popstack
	mov rax, rcx
	call popstack
	mov rdx, 0
	div rcx
	mov rcx, rdx
	call pushstack

	jmp execloop

op_dup:
	call popstack
	call pushstack
	call pushstack

	jmp execloop

op_addr:
	mov rax, [source_pos]
	mov rbx, 0 ; label index

op_addr_label_loop:
	mov rdi, labels
	mov rdi, [rdi + 8*rbx]
	call bang
	call op_addr_equals_label
	add rbx, 1
	mov [source_pos], rax ; restore source pos
	jmp op_addr_label_loop

bang:
	mov rcx, 0x21
	call putchar
	ret

op_addr_equals_label: ; label source pos in rdi	
	mov rcx, [source_pos]
	call read_source_at_pos
	mov dl, cl
	add qword [source_pos], 1

	cmp cl, 'a'
	jl op_addr_potential_match
	cmp cl, 'z'
	jl op_addr_potential_match

	mov rcx, rdi
	call read_source_at_pos
	add rdi, 1
	cmp dl, cl
	je op_addr_equals_label
	ret
	
op_addr_potential_match:
	mov rcx, rdi
	call read_source_at_pos
		
	cmp cl, 'a'
	jl op_addr_found_label
	cmp cl, 'z'
	jl op_addr_found_label

	ret

op_addr_found_label:
	mov rdi, labels
	mov rcx, [rdi + 8*rbx]
	mov qword [source_pos], rcx
	jmp execloop	

op_eq:
	call popstack ; jump source position
	mov rax, rcx
	call popstack ; a
	mov rbx, rcx
	call popstack ; b
	cmp rbx, rcx ; if a == b
	je op_branch_true
	jmp execloop

op_gt:
	call popstack ; jump source position
	mov rax, rcx
	call popstack ; a
	mov rbx, rcx
	call popstack ; b
	cmp rbx, rcx ; if a > b
	jg op_branch_true
	jmp execloop

op_lt:
	call popstack ; jump source position
	mov rax, rcx
	call popstack ; a
	mov rbx, rcx
	call popstack ; b
	cmp rbx, rcx ; if a == b
	jl op_branch_true
	jmp execloop

op_branch_true: ; virtual branch (change source pos) to the value specified by rax
	mov [source_pos], rax
	jmp execloop

op_call:
	mov rcx, [source_pos]
	call pushcallstack
	call popstack
	mov [source_pos], rcx
	jmp execloop

op_ret:
	call popcallstack
	mov [source_pos], rcx
	jmp execloop

op_label:
	mov rcx, [source_pos]
	call read_source_at_pos
	add qword [source_pos], 1
	cmp cl, 'a'
	jl execloop
	cmp cl, 'z'
	jl execloop
	
	jmp op_label ; loop while character is letter (skips the label name)

whitespace:
	jmp execloop ; ignore and keep looping

read_number: ; parse a number literal and return result in rax
	mov rax, 0
	add qword [source_pos], -1 ; rewind source_pos so it doesn't skip initial digit that was used to check if it was a number

_read_number_loop:
	call read_source_at_pos
	add qword [source_pos], 1
	cmp cl, '0'
	jb _read_number_end
	cmp cl, '9'
	ja _read_number_end

	imul rax, 10
	
	add rcx, -0x30 ; subtract '0' to convert ASCII character value to integer value
	add rax, rcx

	jmp _read_number_loop

_read_number_end:
	add qword [source_pos], -1 ; rewind source_pos so it doesn't skip next non-digit character
	ret

pushstack: ; takes argument in rcx
	push rax
	push rbx
	mov rax, [stack_pos]
	cmp ax, STACK_SIZE
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
	add rsi, -16 ;; fixes offset
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
	add rsi, -32 ;; fixes offset
	mov rdx, stack_underflow_message.len
	add rdx, 1 ; increment by 1 to include '\n' ;; TODO FIXME understand why I need to add 1 here and not for others, maybe because -32 offset is wrong
	syscall

	jmp error

pushcallstack: ; takes argument in rcx
	push rax
	push rbx
	mov rax, [call_stack_pos]
	cmp ax, CALL_STACK_SIZE
	jge stackoverflow
	mov rbx, call_stack
	mov [rbx + 8*rax], rcx
	add rax, 1
	mov [call_stack_pos], rax
	pop rbx
	pop rax
	ret

popcallstack: ; returns result in rcx
	push rax
	push rbx

	mov rax, [call_stack_pos]
	add rax, -1
	cmp rax, 0
	jl stackunderflow
	mov rbx, call_stack
	mov rcx, [rbx + 8*rax]
	mov [call_stack_pos], rax

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
	je preprocess ; if reached end of STDIN

	pop rcx

	pop rdx
	pop rax
	ret

putchar: ; takes argument in rcx
	push rax
	push rdx
	push rdi
	mov rax, 0x2000004 ; write
	mov rdi, 1 ; stdout
	push rcx
	mov rsi, rsp
	mov rdx, 1
	syscall
	pop rcx
	pop rdi
	pop rdx
	pop rax
	ret

error:	
	mov rax, 0x2000001 ; exit
	mov rdi, 17
	syscall
