#ifndef KERNEL_H
#define KERNEL_H

// Simple console class for kernel output
class KernelConsole {
public:
    // Output functions
    void print(const char* str);
    void println(const char* str);
    void putChar(char c);
    void clearScreen();
    
    // Input functions
    char readChar();
    void readLine(char* buffer, int max_size);
    
    // Utility functions
    bool strcmp(const char* str1, const char* str2);
};

// C++ kernel entry point (defined in kernel.cpp)
extern "C" void kernel_main();

#endif