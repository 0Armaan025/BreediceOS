#include "kernel.h"

// Maximum command buffer size
#define CMD_BUFFER_SIZE 64

// Function to write a string to the screen
void KernelConsole::print(const char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        // BIOS teletype output
        asm volatile (
            "mov $0x0E, %%ah\n"
            "mov %0, %%al\n"
            "int $0x10" 
            : 
            : "r" (str[i]) 
            : "ax"
        );
    }
}

// Function to print a new line
void KernelConsole::println(const char* str) {
    print(str);
    print("\r\n");
}

// Function to read a character from keyboard
char KernelConsole::readChar() {
    char c;
    asm volatile (
        "mov $0x00, %%ah\n"
        "int $0x16\n"
        "mov %%al, %0"
        : "=r" (c)
        :
        : "ax"
    );
    return c;
}

// Function to echo a character to screen
void KernelConsole::putChar(char c) {
    asm volatile (
        "mov $0x0E, %%ah\n"
        "mov %0, %%al\n"
        "int $0x10" 
        : 
        : "r" (c) 
        : "ax"
    );
}

// Function to read a line of input
void KernelConsole::readLine(char* buffer, int max_size) {
    int i = 0;
    char c;
    
    while (i < max_size - 1) {
        c = readChar();
        
        // Handle backspace
        if (c == 8 && i > 0) {  // Backspace character
            putChar(8);         // Move cursor back
            putChar(' ');       // Clear character
            putChar(8);         // Move cursor back again
            i--;
            continue;
        }
        
        // Handle enter key
        if (c == '\r') {
            buffer[i] = '\0';
            putChar('\r');
            putChar('\n');
            break;
        }
        
        // Only accept printable characters
        if (c >= 32 && c <= 126) {
            putChar(c);
            buffer[i++] = c;
        }
    }
    
    // Ensure null termination
    buffer[i] = '\0';
}

// Function to compare strings
bool KernelConsole::strcmp(const char* str1, const char* str2) {
    int i = 0;
    while (str1[i] != '\0' && str2[i] != '\0') {
        if (str1[i] != str2[i]) {
            return false;
        }
        i++;
    }
    return (str1[i] == '\0' && str2[i] == '\0');
}

// Clear the screen 
void KernelConsole::clearScreen() {
    // Use BIOS to set video mode (clears screen)
    asm volatile (
        "mov $0x00, %%ah\n"
        "mov $0x03, %%al\n"  // 80x25 text mode
        "int $0x10"
        :
        :
        : "ax"
    );
}

// Our C++ kernel entry point
extern "C" void kernel_main() {
    KernelConsole console;
    char command[CMD_BUFFER_SIZE];
    
    console.clearScreen();
    console.println("ArmaanOS C++ Kernel v0.1");
    console.println("---------------------------");
    console.println("Type 'help' for available commands");
    
    // Simple command prompt loop
    while (true) {
        console.print("\r> ");
        console.readLine(command, CMD_BUFFER_SIZE);
        
        // Process commands
        if (console.strcmp(command, "help")) {
            console.println("Available commands:");
            console.println("  help     - Show this help");
            console.println("  version  - Show OS version info");
            console.println("  clear    - Clear the screen");
            console.println("  reboot   - Restart computer");
            console.println("  shutdown - Halt the system");
        }
        else if (console.strcmp(command, "version")) {
            console.println("ArmaanOS v0.1");
            console.println("Developed by Armaan");
            console.println("C++ Kernel Build");
        }
        else if (console.strcmp(command, "clear")) {
            console.clearScreen();
        }
        else if (console.strcmp(command, "reboot")) {
            console.println("Rebooting system...");
            // Issue reset via keyboard controller
            asm volatile (
                "mov $0xFE, %al\n"
                "out %al, $0x64\n"
            );
        }
        else if (console.strcmp(command, "shutdown")) {
            console.println("System halted. It is now safe to turn off your computer.");
            // Halt the CPU
            asm volatile("hlt");
        }
        else if (command[0] != '\0') {  // Only show error for non-empty commands
            console.print("Unknown command: ");
            console.println(command);
        }
    }
}