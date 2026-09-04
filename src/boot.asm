[BITS 16]         ; Set the code to 16-bit mode
[ORG 0x7c00]      ; Set the origin (starting address) to 0x7c00

start:
    cli           ; Clear interrupts, disabling all maskable interrupts
    mov ax, 0x00  ; Load immediate value 0x00 into register AX
    mov ds, ax    
    mov es, ax    
    mov ss, ax    
    mov sp, 0x7c00
    mov si, msg   
    sti           

print:
    lodsb         
    cmp al, 0     
    je done       
    mov ah, 0x0E 
    int 0x10      
    jmp print     

done:
    cli           ; Clear interrupts, disabling all maskable interrupts
    hlt      

msg: db 'Hello World!', 0 

times 510 - ($ - $$) db 0 ; Fill the rest of the boot sector with zeros up to 510 bytes

dw 0xAA55        