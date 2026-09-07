[org 0x7c00]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov [boot_drive], dl

    mov si, msg
.print:
    lodsb
    cmp al, 0
    je load_stage2
    mov ah, 0x0e
    int 0x10
    jmp .print

load_stage2:
    mov ah, 0x02
    mov al, 6
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, 0x8000
    int 0x13
    jc disk_error

    jmp 0x0000:0x8000

disk_error:
    mov si, err_msg
.print_err:
    lodsb
    cmp al, 0
    je .halt
    mov ah, 0x0e
    int 0x10
    jmp .print_err
.halt:
    jmp $

boot_drive db 0
msg db 'Bienvenido al Reloj/Cronometro con Alarma', 0
err_msg db 'Error leyendo disco', 0

times 510-($-$$) db 0
dw 0xAA55