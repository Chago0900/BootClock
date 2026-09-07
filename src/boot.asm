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

    mov [boot_drive], dl   ; el BIOS deja el drive de arranque en DL, lo guardamos

    mov si, msg
.print:
    lodsb
    cmp al, 0
    je load_stage2
    mov ah, 0x0e
    int 0x10
    jmp .print

load_stage2:
    mov ah, 0x02        ; función: leer sectores
    mov al, 4           ; leer 4 sectores (ajustalo según crezca tu stage2)
    mov ch, 0           ; cilindro 0
    mov cl, 2           ; empezar en sector 2 (el 1 es el bootloader)
    mov dh, 0           ; cabeza 0
    mov dl, [boot_drive]
    mov bx, 0x8000      ; ES ya es 0, entonces destino = 0x0000:0x8000
    int 0x13
    jc disk_error       ; si CF=1, hubo error

    jmp 0x0000:0x8000   ; saltar al stage 2

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


get_time:
    mov ah, 0x02
    int 0x1a
    ; CH = horas (BCD), CL = minutos (BCD), DH = segundos (BCD)
    ret


bcd_to_ascii:
    mov bl, al      ; copia de AL en BL (antes de tocar nada)

    shr bl, 4       ; BL = nibble alto (decenas), en binario 0-9
    add bl, '0'     ; BL = carácter ASCII de las decenas

    and al, 0x0F    ; AL = nibble bajo (unidades), en binario 0-9
    add al, '0'     ; AL = carácter ASCII de las unidades

    mov ah, bl      ; mover decenas a AH (donde te lo pedí)
    ret

boot_drive db 0
msg db 'Bienvenido al Reloj/Cronometro con Alarma', 0
err_msg db 'Error leyendo disco', 0

times 510-($-$$) db 0
dw 0xAA55


