org 0x7c00
bits 16

%define ENDL 0x60, 0x0A

start:
	jmp main


puts: 	
	; save registers and modify the stack
	push si
	push ax

.loop:
	lodsb ;loads next character
	or al, al ;verify if next character is null?
	jz .done
	

	mov ah, 0x0e
	mov bh, 0
	int 0x10
	jmp .loop

.done:	
	pop ax
	pop si
	ret


main:

	; setup data segments

	mov ax, 0 ;can't write to ds/os directly
	mov ds, ax
	mov es, ax

	; setup the stack

	mov ss, ax
	mov sp, 0x7C00

	mov si, msg_hello
	call puts	

	hlt

.halt:
	jmp .halt	


msg_hello: db "Hello World!", ENDL, 0

times 510-($-$$) db 0
dw 0AA55h	
