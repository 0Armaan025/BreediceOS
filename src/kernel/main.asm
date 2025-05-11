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
    
    ; Display welcome message
    mov si, msg_kernel_start
    call puts
    
    ; Main kernel loop
    main_loop:
        ; Display prompt
        mov si, msg_prompt
        call puts
        
        ; Read command
        call read_command
        
        ; Process command
        call process_command
        
        ; Loop back
        jmp main_loop

; Function to read a command into command_buffer
read_command:
    mov di, command_buffer  ; Destination for input
    mov cx, 0               ; Character counter
    
    ; Clear command buffer first
    push di
    push cx
    mov cx, BUFFER_SIZE
    xor al, al
    rep stosb              ; Fill buffer with zeros
    pop cx
    pop di

.read_char:
    ; Wait for keypress
    mov ah, 0              ; BIOS keyboard input function
    int 0x16               ; Call BIOS
    
    ; Check for backspace
    cmp al, 8              ; Backspace ASCII
    je .handle_backspace
    
    ; Check for Enter key (CR)
    cmp al, 0x0D
    je .finish_input
    
    ; Check if printable character
    cmp al, 32             ; Space (first printable ASCII)
    jb .read_char          ; Below 32, ignore
    cmp al, 126            ; Last printable ASCII
    ja .read_char          ; Above 126, ignore
    
    ; Check buffer limits (leave room for null terminator)
    cmp cx, BUFFER_SIZE-1
    jae .read_char         ; Buffer full, ignore additional input
    
    ; Echo character
    mov ah, 0x0E           ; BIOS teletype function
    int 0x10               ; Call BIOS
    
    ; Store character in buffer
    stosb                  ; Store AL at ES:DI and increment DI
    inc cx                 ; Increment counter
    
    jmp .read_char

.handle_backspace:
    ; Only handle backspace if we have characters
    cmp cx, 0
    je .read_char          ; No characters to delete
    
    ; Move cursor back, print space, move cursor back again
    mov ah, 0x0E
    mov al, 8              ; Backspace
    int 0x10
    mov al, ' '            ; Space (to clear the character)
    int 0x10
    mov al, 8              ; Backspace again
    int 0x10
    
    ; Update buffer pointer and counter
    dec di                 ; Move buffer pointer back
    dec cx                 ; Decrement counter
    mov byte [di], 0       ; Zero out the removed character
    
    jmp .read_char

.finish_input:
    ; Add null terminator
    mov byte [di], 0
    
    ; Print newline
    mov si, msg_newline
    call puts
    
    ret

; Function to process the command in command_buffer
process_command:
    ; Point SI to our command
    mov si, command_buffer
    
    ; Check if empty command
    cmp byte [si], 0
    je .done
    
    ; Check for "help" command
    mov di, cmd_help
    call strcmp
    jc .help_command
    
    ; Check for "clear" command
    mov si, command_buffer  ; Reset SI to start of buffer
    mov di, cmd_clear
    call strcmp
    jc .clear_command
    
    ; Check for "version" command
    mov si, command_buffer
    mov di, cmd_version
    call strcmp
    jc .version_command
    
    ; Check for "reboot" command
    mov si, command_buffer
    mov di, cmd_reboot
    call strcmp
    jc .reboot_command
    
    ; Check for "shutdown" command
    mov si, command_buffer
    mov di, cmd_shutdown
    call strcmp
    jc .shutdown_command
    
    ; Unknown command
    mov si, msg_unknown_cmd
    call puts
    mov si, command_buffer
    call puts
    mov si, msg_newline
    call puts
    
    jmp .done
    
.help_command:
    mov si, msg_help
    call puts
    jmp .done
    
.clear_command:
    call clear_screen
    jmp .done
    
.version_command:
    mov si, msg_version
    call puts
    jmp .done
    
.reboot_command:
    mov si, msg_rebooting
    call puts
    
    ; Wait a moment
    mov cx, 0xFFFF
.reboot_delay:
    loop .reboot_delay
    
    ; Reboot via keyboard controller
    mov al, 0xFE
    out 0x64, al
    
    ; If that doesn't work, hang
    jmp $
    
.shutdown_command:
    mov si, msg_shutdown
    call puts
    cli                     ; Clear interrupts
    hlt                     ; Halt the CPU
    jmp $                   ; Just in case execution continues

.done:
    ret

; Function to clear the screen
clear_screen:
    push ax
    
    ; Use BIOS to set video mode (clears screen)
    mov ah, 0               ; BIOS set video mode function
    mov al, 3               ; Mode 3 = 80x25 text mode
    int 0x10
    
    pop ax
    ret

; String comparison (SI and DI)
; Sets carry flag if strings match
strcmp:
    push ax
    push si
    push di
    
.compare_loop:
    mov al, [si]            ; Get character from first string
    mov ah, [di]            ; Get character from second string
    
    ; If we reached the end of both strings, they match
    cmp al, 0
    jne .check_match
    cmp ah, 0
    je .match               ; Both ended, match
    jmp .no_match           ; First ended, second didn't
    
.check_match:
    cmp ah, 0               ; Check if second string ended
    je .no_match            ; Second ended, first didn't
    
    ; Compare characters
    cmp al, ah
    jne .no_match           ; Characters don't match
    
    ; Move to next character
    inc si
    inc di
    jmp .compare_loop
    
.match:
    stc                     ; Set carry flag (strings match)
    jmp .done
    
.no_match:
    clc                     ; Clear carry flag (strings don't match)
    
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
msg_kernel_start db "ArmaanOS: Successfully loaded and running!", 0x0D, 0x0A
                 db "Type 'help' to see available commands", 0x0D, 0x0A, 0
msg_prompt db "> ", 0
msg_newline db 0x0D, 0x0A, 0
msg_unknown_cmd db "Unknown command: ", 0

msg_help db "Available commands:", 0x0D, 0x0A
         db "  help     - Display this help message", 0x0D, 0x0A
         db "  clear    - Clear the screen", 0x0D, 0x0A
         db "  version  - Display OS version information", 0x0D, 0x0A
         db "  reboot   - Restart the computer", 0x0D, 0x0A
         db "  shutdown - Halt the system", 0x0D, 0x0A, 0

msg_version db "ArmaanOS v0.1", 0x0D, 0x0A
           db "Developed by Armaan", 0x0D, 0x0A, 0

msg_rebooting db "Rebooting system...", 0x0D, 0x0A, 0
msg_shutdown db "System halted. It is now safe to turn off your computer.", 0x0D, 0x0A, 0

; Command strings for comparison
cmd_help db "help", 0
cmd_clear db "clear", 0
cmd_version db "version", 0
cmd_reboot db "reboot", 0
cmd_shutdown db "shutdown", 0

; Command buffer for storing user input
command_buffer: times BUFFER_SIZE db 0

; Pad to ensure kernel is large enough to be detected properly
times 512*5 db 0           ; Pad to 5 sectors (adjust as needed)

; command to run this: sudo qemu-system-i386 -drive file=build/main_floppy.img,format=raw,if=floppy -display sdl