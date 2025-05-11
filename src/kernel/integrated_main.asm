org 0x1000
bits 16

; Constants
BUFFER_SIZE     equ 64        ; Maximum input buffer size

; Kernel entry point
start:
    ; Set up data segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    
    ; Set up stack
    mov ss, ax
    mov sp, 0xFFFF         ; Set stack to top of segment
    
    ; Clear screen
    call clear_screen
    
    ; Display welcome message
    mov si, msg_kernel_start
    call puts
    
    ; Display divider
    mov si, msg_divider
    call puts
    
    ; Display instructions
    mov si, msg_instructions
    call puts
    
    ; Main kernel loop
    main_loop:
        ; Display prompt
        mov si, msg_prompt
        call puts
        
        ; Read command
        mov di, cmd_buffer
        call read_line
        
        ; Process command
        mov si, cmd_buffer
        
        ; Check if empty command
        cmp byte [si], 0
        je main_loop
        
        ; Check for "help" command
        mov di, cmd_help
        call strcmp
        jc .help_cmd
        
        ; Check for "version" command
        mov si, cmd_buffer  ; Reset SI to start of buffer
        mov di, cmd_version
        call strcmp
        jc .version_cmd
        
        ; Check for "clear" command
        mov si, cmd_buffer
        mov di, cmd_clear
        call strcmp
        jc .clear_cmd
        
        ; Check for "reboot" command
        mov si, cmd_buffer
        mov di, cmd_reboot
        call strcmp
        jc .reboot_cmd
        
        ; Check for "shutdown" command
        mov si, cmd_buffer
        mov di, cmd_shutdown
        call strcmp
        jc .shutdown_cmd
        
        ; Unknown command
        mov si, msg_unknown_prefix
        call puts
        mov si, cmd_buffer
        call puts
        mov si, msg_newline
        call puts
        jmp main_loop
        
    .help_cmd:
        mov si, msg_help
        call puts
        jmp main_loop
        
    .version_cmd:
        mov si, msg_version
        call puts
        jmp main_loop
        
    .clear_cmd:
        call clear_screen
        jmp main_loop
        
    .reboot_cmd:
        mov si, msg_rebooting
        call puts
        
        ; Issue reboot via keyboard controller
        mov al, 0xFE
        out 0x64, al
        
        ; If that didn't work, hang
        jmp $
        
    .shutdown_cmd:
        mov si, msg_shutdown
        call puts
        hlt               ; Halt the CPU
        jmp $             ; In case the CPU resumes

; Function to read a line of input into DI
read_line:
    push ax
    push cx
    push di
    
    mov cx, BUFFER_SIZE - 1  ; Maximum characters to read
    
.read_char_loop:
    mov ah, 0               ; BIOS keyboard function
    int 0x16                ; Call BIOS
    
    ; Check for backspace
    cmp al, 8               ; Backspace ASCII
    je .handle_backspace
    
    ; Check for enter/return
    cmp al, 13              ; Carriage return
    je .end_line
    
    ; Check if printable character and buffer not full
    cmp al, 32              ; Space (first printable)
    jb .read_char_loop      ; Below 32, ignore
    cmp al, 126             ; Last printable ASCII
    ja .read_char_loop      ; Above 126, ignore
    
    ; Check buffer size
    cmp cx, 0
    je .read_char_loop      ; Buffer full, ignore
    
    ; Echo character
    mov ah, 0x0E            ; BIOS teletype
    int 0x10
    
    ; Store character
    stosb                   ; Store AL at ES:DI and increment DI
    dec cx                  ; Decrement counter
    jmp .read_char_loop
    
.handle_backspace:
    ; Check if at beginning of line
    cmp di, [esp]           ; Compare with original DI
    je .read_char_loop      ; At beginning, nothing to delete
    
    ; Handle backspace (move cursor back, clear char, move back again)
    mov ah, 0x0E            ; BIOS teletype
    int 0x10                ; Print backspace (moves cursor left)
    
    mov al, ' '             ; Space to clear character
    int 0x10                ; Print space
    
    mov al, 8               ; Backspace again
    int 0x10                ; Print backspace
    
    ; Update buffer
    dec di                  ; Move buffer pointer back
    inc cx                  ; Increase remaining space
    jmp .read_char_loop
    
.end_line:
    ; Terminate string with null
    mov byte [di], 0
    
    ; Print newline
    mov ah, 0x0E
    mov al, 13              ; Carriage return
    int 0x10
    mov al, 10              ; Line feed
    int 0x10
    
    pop di                  ; Restore original DI value
    pop cx
    pop ax
    ret

; String comparison (SI and DI)
; Sets carry flag if strings match
strcmp:
    push ax
    push si
    push di
    
.loop:
    mov al, [si]            ; Get character from first string
    mov ah, [di]            ; Get character from second string
    
    ; Check if end of strings
    cmp al, 0
    je .check_end
    
    ; Compare characters
    cmp al, ah
    jne .not_equal
    
    ; Next characters
    inc si
    inc di
    jmp .loop
    
.check_end:
    ; Check if second string also ended
    cmp ah, 0
    je .equal
    
.not_equal:
    clc                     ; Clear carry flag (not equal)
    jmp .done
    
.equal:
    stc                     ; Set carry flag (equal)
    
.done:
    pop di
    pop si
    pop ax
    ret

; Function to print null-terminated string from SI
puts:
    push ax
    push si
.loop:
    lodsb                   ; Load byte from SI into AL
    or al, al               ; Check if AL is 0 (end of string)
    jz .done
    mov ah, 0x0E            ; BIOS teletype function
    int 0x10                ; Call BIOS
    jmp .loop
.done:
    pop si
    pop ax
    ret

; Function to clear the screen
clear_screen:
    push ax
    
    ; Set video mode (clears screen)
    mov ah, 0x00            ; Set video mode function
    mov al, 0x03            ; Mode 3 (80x25 text)
    int 0x10
    
    pop ax
    ret

; Data section
msg_kernel_start db "ArmaanOS Assembly Kernel v0.1", 0x0D, 0x0A, 0
msg_divider db "---------------------------", 0x0D, 0x0A, 0
msg_instructions db "Type 'help' for available commands", 0x0D, 0x0A, 0
msg_prompt db "> ", 0
msg_newline db 0x0D, 0x0A, 0
msg_unknown_prefix db "Unknown command: ", 0

msg_help db "Available commands:", 0x0D, 0x0A
         db "  help     - Show this help", 0x0D, 0x0A
         db "  version  - Show OS version info", 0x0D, 0x0A
         db "  clear    - Clear the screen", 0x0D, 0x0A
         db "  reboot   - Restart computer", 0x0D, 0x0A
         db "  shutdown - Halt the system", 0x0D, 0x0A, 0
         
msg_version db "ArmaanOS v0.1", 0x0D, 0x0A
           db "Developed by Armaan", 0x0D, 0x0A
           db "Assembly Kernel Build", 0x0D, 0x0A, 0
           
msg_rebooting db "Rebooting system...", 0x0D, 0x0A, 0
msg_shutdown db "System halted. It is now safe to turn off your computer.", 0x0D, 0x0A, 0

; Command strings
cmd_help db "help", 0
cmd_version db "version", 0
cmd_clear db "clear", 0
cmd_reboot db "reboot", 0
cmd_shutdown db "shutdown", 0

; Buffer for input
cmd_buffer: times BUFFER_SIZE db 0

; Pad to ensure kernel is large enough to be detected properly
times 512*5 db 0           ; Pad to 5 sectors (adjust as needed)