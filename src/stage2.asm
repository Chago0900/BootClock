[org 0x8000]
[bits 16]

stage2_start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ah, 0x02
    mov bh, 0
    mov dh, 5
    mov dl, 0
    int 0x10
    mov si, confirm_prompt
.confirm_print:
    lodsb
    cmp al, 0
    je .wait_confirm
    mov ah, 0x0e
    int 0x10
    jmp .confirm_print

.wait_confirm:
    mov ah, 0x00
    int 0x16            ; espera bloqueante por una tecla
    or al, 0x20
    cmp al, 's'
    jne .wait_confirm   ; cualquier tecla que no sea 's' se ignora

    ; limpiar pantalla antes de entrar al modo interactivo (int 0x10, ah=0x00 = set video mode, reinicia y limpia)
    mov ax, 0x0003
    int 0x10

main_loop:
    mov ah, 0x02
    int 0x1a                ; CH=horas, CL=minutos, DH=segundos (BCD)

    mov [hora], ch
    mov [minutos], cl

    cmp dh, [last_second]
    je .no_new_second

    mov [last_second], dh
    mov [segundos], dh
    mov byte [new_second], 1

    cmp byte [stopwatch_running], 0
    je .skip_increment
    inc word [stopwatch_seconds]
.skip_increment:

    cmp byte [alarm_active], 0
    je .no_alarm_check
    mov al, [hora]
    cmp al, [alarm_hour]
    jne .no_alarm_check
    mov al, [minutos]
    cmp al, [alarm_minute]
    jne .no_alarm_check
    call trigger_alarm
.no_alarm_check:

.no_new_second:
    cmp byte [new_second], 1
    jne .check_key

    mov byte [new_second], 0

    cmp byte [mode], 0
    je draw_clock
    jmp draw_stopwatch

.check_key:
    mov ah, 0x01
    int 0x16
    jz .no_hay_tecla

    mov ah, 0x00
    int 0x16
    or al, 0x20

    cmp al, 'm'
    je cambiar_modo
    cmp al, ' '
    je toggle_cronometro
    cmp al, 'r'
    je reiniciar_cronometro
    cmp al, 'c'
    je config_alarma
    cmp al, 'z'
    je cancelar_alarma
    cmp al, 'x'
    je salir

.no_hay_tecla:
    jmp main_loop

; Modo Reloj 
draw_clock:
    mov ah, 0x02
    mov bh, 0
    mov dh, 10
    mov dl, 30
    int 0x10

    mov al, [hora]
    call print_two_digits_bcd
    mov al, ':'
    mov ah, 0x0e
    int 0x10
    mov al, [minutos]
    call print_two_digits_bcd
    mov al, ':'
    mov ah, 0x0e
    int 0x10
    mov al, [segundos]
    call print_two_digits_bcd
    jmp main_loop.check_key

; Modo Cronometro 
draw_stopwatch:
    mov ax, [stopwatch_seconds]
    xor dx, dx
    mov bx, 3600
    div bx                  ; AX = horas, DX = resto
    mov [sw_hours], al

    mov ax, dx
    xor dx, dx
    mov bx, 60
    div bx                  ; AX = minutos, DX = segundos
    mov [sw_minutes], al
    mov [sw_seconds], dl

    mov ah, 0x02
    mov bh, 0
    mov dh, 12
    mov dl, 30
    int 0x10

    mov al, [sw_hours]
    call print_two_digits_bin
    mov al, ':'
    mov ah, 0x0e
    int 0x10
    mov al, [sw_minutes]
    call print_two_digits_bin
    mov al, ':'
    mov ah, 0x0e
    int 0x10
    mov al, [sw_seconds]
    call print_two_digits_bin
    jmp main_loop.check_key

; Dispatcher de teclas 
cambiar_modo:
    ; limpiar la fila del modo que se va (antes de cambiar [mode])
    cmp byte [mode], 0
    je .clear_clock_row
    mov dh, 12
    jmp .do_clear
.clear_clock_row:
    mov dh, 10
.do_clear:
    mov ah, 0x02
    mov bh, 0
    mov dl, 30
    int 0x10
    mov si, blank_line
.clear_print:
    lodsb
    cmp al, 0
    je .clear_done
    mov ah, 0x0e
    int 0x10
    jmp .clear_print
.clear_done:

    xor byte [mode], 1
    mov byte [new_second], 1
    jmp main_loop

toggle_cronometro:
    xor byte [stopwatch_running], 1
    jmp main_loop

reiniciar_cronometro:
    mov word [stopwatch_seconds], 0
    mov byte [new_second], 1
    jmp main_loop

config_alarma:
    mov ah, 0x02
    mov bh, 0
    mov dh, 14
    mov dl, 0
    int 0x10
    mov si, alarm_prompt
.prompt_print:
    lodsb
    cmp al, 0
    je .read_h1
    mov ah, 0x0e
    int 0x10
    jmp .prompt_print

.read_h1:
    call read_digit_echo    ; AL = digito binario 0-9
    mov bl, al
    shl bl, 4
    call read_digit_echo
    or bl, al
    mov [alarm_hour], bl    ; hora en BCD (comparable directo contra [hora])

    mov al, ':'
    mov ah, 0x0e
    int 0x10

    call read_digit_echo
    mov bl, al
    shl bl, 4
    call read_digit_echo
    or bl, al
    mov [alarm_minute], bl

    mov byte [alarm_active], 1
    jmp main_loop

; lee un digito ASCII bloqueante, lo hace eco en pantalla, devuelve valor binario en AL
read_digit_echo:
    mov ah, 0x00
    int 0x16
    push ax
    mov ah, 0x0e
    int 0x10
    pop ax
    sub al, '0'
    ret

; suena el altavoz y muestra el mensaje de alarma (se llama cuando coincide la hora)
trigger_alarm:
    mov al, 0xB6
    out 0x43, al
    mov ax, 1193
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 3
    out 0x61, al

    mov ah, 0x02
    mov bh, 0
    mov dh, 16
    mov dl, 20
    int 0x10
    mov si, alarm_msg
.am_print:
    lodsb
    cmp al, 0
    je .am_done
    mov ah, 0x0e
    int 0x10
    jmp .am_print
.am_done:
    ret

cancelar_alarma:
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    mov byte [alarm_active], 0

    mov ah, 0x02
    mov bh, 0
    mov dh, 16
    mov dl, 20
    int 0x10
    mov si, blank_line35
.cl_print:
    lodsb
    cmp al, 0
    je .cl_done
    mov ah, 0x0e
    int 0x10
    jmp .cl_print
.cl_done:
    jmp main_loop

salir:
    cli
    hlt
    jmp $

; Utilidades de impresion 
print_two_digits_bcd:
    call bcd_to_ascii
    mov bh, al
    mov al, ah
    mov ah, 0x0e
    int 0x10
    mov al, bh
    mov ah, 0x0e
    int 0x10
    ret

print_two_digits_bin:
    xor ah, ah
    mov bl, 10
    div bl              ; AL = decenas, AH = unidades
    add al, '0'
    add ah, '0'
    mov bh, ah
    mov ah, 0x0e
    int 0x10
    mov al, bh
    mov ah, 0x0e
    int 0x10
    ret

bcd_to_ascii:
    mov bl, al
    shr bl, 4
    add bl, '0'
    and al, 0x0F
    add al, '0'
    mov ah, bl
    ret

; Variables 
confirm_prompt      db 'Presione S para iniciar...', 0
blank_line          db '        ', 0
blank_line35        db '                                   ', 0
alarm_prompt        db 'Alarma HH:MM: ', 0
alarm_msg           db 'ALARMA! Presione Z para cancelar', 0
last_second         db 0xFF
new_second          db 0
mode                db 0
hora                db 0
minutos             db 0
segundos            db 0

stopwatch_running   db 0
stopwatch_seconds   dw 0
sw_hours            db 0
sw_minutes          db 0
sw_seconds          db 0

alarm_active        db 0
alarm_hour          db 0
alarm_minute        db 0

times 3072-($-$$) db 0