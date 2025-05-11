org 0x7c00
bits 16

; Jump over the FAT header
jmp short start
nop

; BIOS Parameter Block
bdb_oem:    				db 'MSWIN4.1' ; 8 bytes
bdb_bytes_per_sector: 		dw 512
bdb_sectors_per_cluster: 	db 1
bdb_reserved_sectors: 		dw 1
bdb_fat_count: 				db 2
bdb_dir_entries_count: 		dw 0E0h
bdb_total_sectors:			dw 2880 
bdb_media_descriptor_type:	db 0F0h
bdb_sectors_per_fat: 		dw 9
bdb_sectors_per_track: 		dw 18
bdb_heads: 					dw 2
bdb_hidden_sectors: 		dd 0
bdb_large_sector_count:		dd 0

; Extended boot record
ebr_drive_number: 			db 0
							db 0
ebr_signature:				db 29h
ebr_volume_id:				db 12h, 34h, 56h, 78h
ebr_volume_label:			db 'ARMAAN OS ' ; <- pad to 11 chars
ebr_system_id: 				db 'FAT12   '     ; <- pad to 8 chars

; Constants
KERNEL_OFFSET    equ 0x1000      ; Memory location to load kernel
KERNEL_SECTORS   equ 20          ; Number of sectors to load (increased for C++ kernel)

start:
	; Set up segment registers and stack
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00              ; Set up stack below bootloader

	; Save boot drive number
	mov [ebr_drive_number], dl

	; Show hello message
	mov si, msg_hello
	call puts

	; Load kernel from disk
	mov bx, KERNEL_OFFSET       ; ES:BX = 0x0000:0x1000
	mov dl, [ebr_drive_number]  ; Drive number
	call load_kernel
	
	; Jump to kernel
	mov si, msg_kernel_loaded
	call puts
	
	; Jump to the kernel
	jmp 0:KERNEL_OFFSET

; Function to load kernel from disk
load_kernel:
	mov ah, 0x02                ; BIOS read function
	mov al, KERNEL_SECTORS      ; Number of sectors to read
	mov ch, 0                   ; Cylinder 0
	mov cl, 2                   ; Start from sector 2 (sector 1 is bootloader)
	mov dh, 0                   ; Head 0
	int 0x13                    ; Call BIOS
	jc disk_error               ; If carry flag set, there was an error
	
	; Verify sectors read
	cmp al, KERNEL_SECTORS      ; AL = sectors actually read
	jne disk_error              ; If not all sectors read, error
	ret

disk_error:
	mov si, msg_disk_error
	call puts
	jmp $                       ; Infinite loop

; Function to print null-terminated string from SI
puts:
	push ax
	push si
.next:
	lodsb                       ; Load byte from SI into AL
	or al, al                   ; Check if AL is 0 (end of string)
	jz .done
	mov ah, 0x0E                ; BIOS teletype function
	int 0x10                    ; Call BIOS
	jmp .next
.done:
	pop si
	pop ax
	ret

; Messages
msg_hello db "Bootloader: Loading C++ kernel...", 0x0D, 0x0A, 0
msg_kernel_loaded db "Bootloader: Kernel loaded, transferring control...", 0x0D, 0x0A, 0
msg_disk_error db "Bootloader: ERROR! Failed to load kernel!", 0x0D, 0x0A, 0

; Boot signature
times 510 - ($ - $$) db 0
dw 0xAA55