section .text

global my_printf   

bin_system          equ 1
oct_system          equ 3
dec_system          equ 10
hex_system          equ 4
size_stack_cell     equ 8
shift_pointer_stack equ 64
size_buffer         equ 200

my_printf:
                pop r10                         ; save addr return

                push r9                         ; 6 arg
                push r8                         ; 5 arg
                push rcx                        ; 4 arg
                push rdx                        ; 3 arg
                push rsi                        ; 2 arg
                push rdi                        ; 1 arg

                push rbp                        ;save registers
                push rbx 
                push r12 
                push r13 
                push r14 
                push r15

                call printf                     ; main func 

                pop r15                         ;recovery registers
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

printf:
                cld                             ; flag DF = 0

                mov r15, Buffer                 ; r15 = addr Buffer for output
                mov r14, rdi                    ; r14 = first arg (format line)
                mov rbp, rsp                    ; rbp = rsp
                add rbp, shift_pointer_stack    ; rbp = addr second arg (int stack)

                call my_strlen                  ; rcx = len format str from [rdi]
                dec rcx                         ; delete '\0'

        .begin:
                mov rdi, r15                    ; rdi = current pointer on Buffer 
                mov rsi, r14                    ; rsi = current pointer on format str

        .copy:
                lodsb                           ; al = ds:[rsi++]
                cmp al, '%'                     ; if (al == '%')
                je .switch                      ;       jmp .switch
                stosb                           ; es:[rdi++] = al
                loop .copy                      ; if (--rcx) jmp .copy
                push rcx                        ; save rcx
                jmp .end_switch                 ; if (rcx == 0) jmp. end_switch

        .switch:
                lodsb                           ; al = ds:[rsi++] - symbol after '%'
                dec rcx                         ; skip symbol after '%'
                push rcx                        ; save rcx

                mov r14, rsi                    ; update current pointer on format str
                mov r15, rdi                    ; update current pointer on Buffer

                cmp al, '%'                     ; if (al == '%')
                je print_percent                ;       jmp .case_percent

                jmp qword [labels + rax * 8 - 8 * 'b']       ; jump on this label     

        .case_default:
                jmp .end_switch
                
        .end_switch:
                pop rcx                         ; if (rcx != 0)
                cmp rcx, 0                      ;       jmp .begin
                jne .begin
                
                mov rdi, Buffer                 ; rdi = addr for Buffer
                call my_strlen                  ; count len str in Buffer

                mov rdx, rcx                    ; rdx = len str for input
                mov rax, 0x01                   ; number func output (write = 01)
                mov rdi, 1                      ; stdout
                mov rsi, Buffer                 ; rsi = addr for buffer
                syscall

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
;       Destr: rax rbx rcx rdx rdi 
;------------------------------------------------

print_dec:      
                mov rax, [rbp]                  ; rax - number argument 
                mov rdi, r15                    ; rdi - current pointer on Buffer 

                cmp eax, 0                      ; if (eax > 0)
                jge .positive_num               ;       jmp .positive_num

                neg eax                         ; processing negative num
                mov byte [rdi], '-'             ; eax = -eax
                inc rdi                         ; putchar ('-') in Buffer

        .positive_num:
                xor rcx, rcx                    ; rcx = 0
                mov ebx, dec_system             ; ebx = radix decimal

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
                add rbp, size_stack_cell        ; shift up rbp in stack

                jmp printf.end_switch        ; return

;------------------------------------------------
;       Parsing line of symbols
;       Entry: rbp - current value on stack
;              r15 - current pointer on Buffer
;       Exit : None
;       Destr: rcx rsi rdi
;------------------------------------------------

print_str:
                mov rdi, [rbp]                  ; rdi = addr input str
                call my_strlen                  ; rcx = len input str
                dec rcx                         ; skip '\0'

                mov rsi, [rbp]                  ; rsi = addr input str
                mov rdi, r15                    ; rdi = current pointer on Buffer 
                rep movsb                       ; [rdi++] = [rsi++]
                add rbp, size_stack_cell        ; shift up rbp in stack
                mov r15, rdi                    ; update current pointer on Buffer

                jmp printf.end_switch        ; return

;------------------------------------------------
;       Print symbol '%'
;       Entry: r15 - current pointer on Buffer
;       Exit : None
;       Destr: rsi rdi
;------------------------------------------------

print_percent:
                mov rdi, '%' 
                mov rsi, r15                    ; rsi = current pointer on Buffer 
                mov [rsi], rdi                  ; [rsi] = ASCII code symbol
                inc r15                         ; update current pointer on Buffer

                jmp printf.end_switch           ; return

;------------------------------------------------
;       Print one char-symbol in Buffer
;       Entry: r15 - current pointer on Buffer
;       Exit : None
;       Destr: rsi rdi
;------------------------------------------------

print_char:
                mov rdi, [rbp]                  ; rdi = symbol for print
                mov rsi, r15                    ; rsi = current pointer on Buffer 
                mov [rsi], rdi                  ; [rsi] = ASCII code symbol
                inc r15                         ; update current pointer on Buffer
                add rbp, size_stack_cell        ; shift up rbp in stack

                jmp printf.end_switch           ; return

;------------------------------------------------
;       Print in different number systems
;       Entry: None
;       Exit : None
;       Destr: rcx
;------------------------------------------------

print_bin:
                mov ecx, bin_system                      
                jmp print_bin_oct_hex           
print_oct:                                      ; in these three functions
                mov ecx, oct_system             ; we pass the values of 
                jmp print_bin_oct_hex           ; different number systems 
print_hex:                                      ; and call the general function
                mov ecx, hex_system
                jmp print_bin_oct_hex

;------------------------------------------------
;       Print address
;       Entry: r15 - current pointer on Buffer
;       Exit : None
;       Destr: rcx rsi
;------------------------------------------------

print_addr:
                mov rsi, r15                    ; rsi = current pointer on Buffer 
                mov byte [rsi], '0'             ; mov "0x" in Buffer
                inc rsi 
                mov byte [rsi], 'x'
                add r15, 2                      ; update current pointer on Buffer
                mov ecx, hex_system             ; hex system

                jmp print_bin_oct_hex           ; print value address

;------------------------------------------------
;       Passing the num of printed smb to arg
;       Entry: r15 - current pointer on Buffer
;              rbp - current value on stack
;       Exit : None
;       Destr: rcx rsi
;------------------------------------------------

print_n:
                mov rcx, r15                    ; rcx = current pointer on Buffer 
                sub rcx, Buffer                 ; rcx = length of the filled buffer
                mov rsi, [rbp]                  ; rsi = addr argument
                mov [rsi], rcx                  ; argument = rcx
                add rbp, size_stack_cell        ; shift up rbp in stack

                jmp printf.end_switch           ; return

;------------------------------------------------
;       Parsing bin/oct/hex number system
;       Entry: rdi - ASCII code symbol
;              r15 - current pointer on Buffer
;              rcx - log_2(number system)
;       Exit : None
;       Destr: None
;------------------------------------------------

print_bin_oct_hex:
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
                add rbp, size_stack_cell        ; shift up rbp in stack

                jmp printf.end_switch           ; return

section .rodata

labels:
                dq print_bin
                dq print_char
                dq print_dec
                times 'n' - 'd' - 1 dq printf.case_default
                dq print_n
                dq print_oct
                dq print_addr
                times 's' - 'p' - 1 dq printf.case_default
                dq print_str
                times 'x' - 's' - 1 dq printf.case_default
                dq print_hex

section .data

Buffer: db size_buffer dup(0)
