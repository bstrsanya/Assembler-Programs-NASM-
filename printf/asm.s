section .text

global my_printf   

my_printf:
                pop r10                         ; save addr return

                push r9                         ; 6 arg
                push r8                         ; 5 arg
                push rcx                        ; 4 arg
                push rdx                        ; 3 arg
                push rsi                        ; 2 arg
                push rdi                        ; 1 arg

                push rbp                        ;save regs by convention
                push rbx 
                push r12 
                push r13 
                push r14 
                push r15

                ;mov rdi, [rsp + 8]                  ; rdi = 1 arg

                call my_strlen                  ; rcx = len format str from [rdi]
                dec rcx                         ; delete '\0'

                cld                             ; flag DF = 0

                mov r15, Buffer                 ; r15 = addr Buffer for output
                mov r14, [rsp + 48]                  ; r14 = addr first arg (in stack)
                mov rbp, rsp                    ; rbp = rsp
                add rbp, 56                      ; rbp = addr second arg (int stack)

        begin:
                mov rdi, r15                    ; rdi = current pointer on Buffer 
                mov rsi, r14                    ; rsi = current pointer on format str

        .copy:
                lodsb                           ; al = ds:[rsi++]
                cmp al, '%'                     ; if (al == '%')
                je .switch                      ;       jmp .switch
                stosb                           ; es:[rdi++] = al
                loop .copy                      ; if (--rcx) jmp .copy
                push rcx                        ; save rcx
                jmp end_switch                  ; if (rcx == 0) jmp. end_switch

        .switch:
                lodsb                           ; al = ds:[rsi++] - symbol after '%'
                dec rcx                         ; skip symbol after '%'
                push rcx                        ; save rcx

                mov r14, rsi                    ; update current pointer on format str
                mov r15, rdi                    ; update current pointer on Buffer

                cmp al, '%'                     ; if (al == '%')
                je .case_percent                ;       jmp .case_percent

                sub rax, 'b'                    ; shift rax on value 'b'
                lea rbx, .labels                ; count shift and 
                jmp qword [rbx + rax * 8]       ;       jump on this label
; // rodata
; прыгать сразу на функции, чтобы не было call 
        .labels:                                ; transition table
                dq case_b, case_c, case_d
                times 'o' - 'd' - 1 dq case_default
                dq case_o
                times 's' - 'o' - 1 dq case_default
                dq case_s
                times 'x' - 's' - 1 dq case_default
                dq case_x

        .case_percent:                           
                mov rdi, '%'                    ; rdi = symbol for print
                call print_char                 ; putchar ('%') in Buffer
                jmp end_switch                  ; break

        case_b:
                mov ecx, 1                      ; 2 ^ 1 = 2
                call print_bin_oct_hex          ; print binary number
                jmp end_switch                  ; break
        
        case_c:
                mov rdi, [rbp]                  ; rdi = symbol for print
                call print_char                 ; putchar (rdi) in Buffer
                add rbp, 8                      ; shift up rbp in stack
                jmp end_switch                  ; break
                
        case_d:
                call print_dec                  ; print decimal number
                jmp end_switch                  ; break

        case_o:
                mov ecx, 3                      ; 2 ^ 3 = 8
                call print_bin_oct_hex          ; print octal number
                jmp end_switch                  ; break

        case_s:
                call print_str                  ; print string
                jmp end_switch                  ; break

        case_x:
                mov ecx, 4                      ; 2 ^ 4 = 16
                call print_bin_oct_hex          ; print hexadecimal number
                jmp end_switch                  ; break

        case_default:
                jmp end_switch
                
        end_switch:
                pop rcx                         ; if (rcx != 0)
                cmp rcx, 0                      ;       jmp begin
                jne begin
                
                mov rdi, Buffer                 ; rdi = addr for Buffer
                call my_strlen                  ; count len str in Buffer

                mov rdx, rcx                    ; rdx = len str for input
                mov rax, 0x01                   ; number func output (write = 01)
                mov rdi, 1                      ; stdout
                mov rsi, Buffer                 ; rsi = addr for buffer
                syscall

                pop r15                         ;revive regs
                pop r14
                pop r13
                pop r12
                pop rbx
                pop rbp

                pop rdi                         ; recovery registers
                pop rsi
                pop rdx
                pop rcx
                pop r8
                pop r9

                push r10                        ; recovery addr return                 
                ret

;------------------------------------------------
;       Count length str
;       Entry: rdi - addr str
;       Exit : rcx - len str
;       Destr: rax
;------------------------------------------------

my_strlen:
                xor rax, rax                    ; rax = 0 ('\0')
                xor rcx, rcx                    ; rcx = 0
                dec rcx                         ; rcx = 0xFF...FF
                repne scasb                     ; while (rcx-- && byte [rdi++] != al) 
                neg rcx                         ; rcx = -rcx
                dec rcx                         ; rcx--

                ret

;------------------------------------------------
;       Parsing decimal number system
;       Entry: rbp - current value on stack
;              r15 - current pointer on Buffer
;       Exit : None
;       Destr: rcx rdi 
;------------------------------------------------

print_dec:      
                push rax
                push rbx
                push rdx

                mov rax, [rbp]                  ; rax - number argument 
                mov rdi, r15                    ; rdi - current pointer on Buffer 

                cmp eax, 0                      ; if (eax > 0)
                jge .positive_num               ;       jmp .positive_num

                neg eax                         ; processing negative num
                mov byte [rdi], '-'             ; eax = -eax
                inc rdi                         ; putchar ('-') in Buffer

        .positive_num:
                xor rcx, rcx                    ; rcx = 0
                mov ebx, 10                     ; ebx = radix decimal

        .get_digit:
                xor edx, edx                    ; edx = 0
                div ebx                         ; eax = eax // ebx                        
                push rdx                        ; edx = eax % ebx
                inc rcx                         ; number of digits ++
                cmp eax, 0                      ; if (eax > 0)
                jg .get_digit                   ;       jmp .get_digit

        .put_digit:
                pop rax                         ; get digit
                add al, '0'                     ; digit -> ASCII code digit
                stosb                           ; es:[rdi++] = al
                loop .put_digit                 ; if (--rcx) jmp .put_digit

                mov r15, rdi                    ; update current pointer on Buffer
                add rbp, 8                      ; shift up rbp in stack

                pop rdx
                pop rbx
                pop rax

                ret

;------------------------------------------------
;       Parsing line of symbols
;       Entry: rbp - current value on stack
;              r15 - current pointer on Buffer
;       Exit : None
;       Destr: rcx
;------------------------------------------------

print_str:
                mov rdi, [rbp]                  ; rdi = addr input str
                call my_strlen                  ; rcx = len input str
                dec rcx                         ; skip '\0'

                mov rsi, [rbp]                  ; rsi = addr input str
                mov rdi, r15                    ; rdi = current pointer on Buffer 
                rep movsb                       ; [rdi++] = [rsi++]
                add rbp, 8                      ; shift up rbp in stack
                mov r15, rdi                    ; update current pointer on Buffer

                ret

;------------------------------------------------
;       Print one char-symbol in Buffer
;       Entry: rdi - ASCII code symbol
;              r15 - current pointer on Buffer
;       Exit : None
;       Destr: None
;------------------------------------------------

print_char:
                mov rsi, r15                    ; rsi = current pointer on Buffer 
                mov [rsi], rdi                  ; [rsi] = ASCII code symbol
                inc r15                         ; update current pointer on Buffer
                
                ret

;------------------------------------------------
;       Parsing bin/oct/hex number system
;       Entry: rdi - ASCII code symbol
;              r15 - current pointer on Buffer
;              rcx - log_2(number system)
;       Exit : None
;       Destr: None
;------------------------------------------------

print_bin_oct_hex:
                push rax
                push rbx
                push rdx

                mov rax, [rbp]                  ; rax - number argument 
                mov rdi, r15                    ; rdi - current pointer on Buffer 

                xor rbx, rbx                    ; rbx = 0
                mov r11, 1                      ; r11 = 1
                shl r11, cl                     ; r11 = r11 * (2 ^ cl)
                dec r11                         ; r11--        

        .get_digit:
                mov rdx, rax                    ; rdx = rax
                and rdx, r11                    ; edx = last bits number
                push rdx                        ; save digit
                inc rbx                         ; counter++ (rbx)
                shr rax, cl                     ; eax = eax // (2 ^ cl)
                cmp rax, 0                      ; if (eax > 0)
                jg .get_digit                   ;       jump .get_digit

                mov rcx, rbx                    ; rcx = numbers of digit

        .put_digit:
                pop rax                         ; get digit

                cmp al, 10                      ; if (digit < 10)
                jl .dec                         ;       jump .dec
                jmp .hex                        ; else
                                                ;       jump .hex        
        .dec:        
                add al, '0'                     ; digit_dec -> ASCII code digit
                jmp .end
        .hex:
                add al, 'a' - 10                ; digit_hex -> ASCII code digit
        .end:
                stosb                           ; es:[rdi++] = al
                loop .put_digit                 ; if (--rcx) jmp .put_digit

                mov r15, rdi                    ; update current pointer on Buffer
                add rbp, 8                      ; shift up rbp in stack

                pop rdx
                pop rbx
                pop rax

                ret


section .data

Buffer: db 200 dup(0)
