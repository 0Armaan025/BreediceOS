/* Linker script for our kernel */
OUTPUT_FORMAT("binary")
ENTRY(_start)

SECTIONS {
    . = 0x1000;            /* Kernel load address */
    
    .text : {
        *(.text)           /* Include all text sections */
    }
    
    .rodata : {
        *(.rodata)         /* Include all read-only data */
    }
    
    .data : {
        *(.data)           /* Include all initialized data */
    }
    
    .bss : {
        *(.bss)            /* Include all uninitialized data */
    }
}