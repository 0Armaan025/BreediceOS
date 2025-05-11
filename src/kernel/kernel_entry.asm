[bits 16]
[extern kernel_main]  ; Declare external kernel_main C++ function

global _start
_start:
    ; Set up segment registers
    mov ax, 0
    mov ds, ax
    mov es, ax
    
    ; Set up stack
    mov ss, ax
    mov sp, 0xFFFF
    
    ; Display ASM message
    mov si, msg_asm_loaded
    call puts
    
    ; Call our C++ kernel
    call kernel_main
    
    ; If kernel_main returns, halt the system
    jmp $

; Function to print null-terminated string from SI
puts:
    push ax
    push si
.loop:
    lodsb                  ; Load byte from SI into AL
    or al, al              ; Check if AL is 0 (end of string)
    jz .done
    mov ah, 0x0E           ; BIOS teletype function
    int 0x10               ; Call BIOS
    jmp .loop
.done:
    pop si
    pop ax
    ret

; Data section
msg_asm_loaded db "ASM: Loading C++ kernel...", 0x0D, 0x0A, 0