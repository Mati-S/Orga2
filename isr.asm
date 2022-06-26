; ** por compatibilidad se omiten tildes **
; ==============================================================================
; System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================
;
; Definicion de rutinas de atencion de interrupciones

%include "print.mac"



%define DS_RING_0_SEL     (3 << 3)
%define CS_RING_0_SEL     (1 << 3)
%define GDT_TASK_IDLE_SEL (12 << 3)
%define TICKS_TASK_SWITCH 200
BITS 32

sched_task_offset:     dd 0xFFFFFFFF
sched_task_selector:   dw 0xFFFF


;; PIC
extern pic_finish1
extern kernel_exception
extern sched_next_task
extern sched_current_task
extern tick_count
extern task_tick
extern kernel_exception
extern user_exception
extern disable_task
extern page_fault_handler

extern process_scancode

;; Definición de MACROS
;; -------------------------------------------------------------------------- ;;

%macro ISRc 1
    push DWORD %1
    ; Stack State:
    ; [ INTERRUPT #] esp
    ; [ ERROR CODE ] esp + 0x04
    ; [ EIP        ] esp + 0x08
    ; [ CS         ] esp + 0x0c
    ; [ EFLAGS     ] esp + 0x10
    ; [ ESP        ] esp + 0x14 (if DPL(cs) == 3)
    ; [ SS         ] esp + 0x18 (if DPL(cs) == 3)

    ; GREGS
    pushad
    ; Check for privilege change before anything else.
    mov edx, [esp + (8*4 + 3*4)]

    ; SREGS
    xor eax, eax
    mov ax, ss
    push eax
    mov ax, gs
    push eax
    mov ax, fs
    push eax
    mov ax, es
    push eax
    mov ax, ds
    push eax
    push eax ; cs

    ; CREGS
    mov eax, cr4
    push eax
    mov eax, cr3
    push eax
    mov eax, cr2
    push eax
    mov eax, cr0
    push eax

    cmp edx, CS_RING_0_SEL
    je .ring0_exception

    ;call ring3_exception
    jmp $


.ring0_exception:
    call kernel_exception
    add esp, 10*4
    popad

    
    jmp $

%endmacro

; ISR that pushes an exception code.
%macro ISRE 1
global _isr%1

_isr%1:
  ISRc %1
%endmacro

; ISR That doesn't push an exception code.
%macro ISRNE 1
global _isr%1

_isr%1:
  push DWORD 0x0
  ISRc %1
%endmacro

;; Rutina de atención de las EXCEPCIONES
;; -------------------------------------------------------------------------- ;;
ISRNE 0
ISRNE 1
ISRNE 2
ISRNE 3
ISRNE 4
ISRNE 5
ISRNE 6
ISRNE 7
ISRE 8
ISRNE 9
ISRE 10
ISRE 11
ISRE 12
ISRE 13
ISRE 14
ISRNE 15
ISRNE 16
ISRE 17
ISRNE 18
ISRNE 19
ISRNE 20

;; Rutina de atención del RELOJ
;; -------------------------------------------------------------------------- ;;
global _isr32
; COMPLETAR: Implementar la rutina

_isr32:
    pushad
    call pic_finish1
    call next_clock
    jmp .run_sched

.run_sched:
    call task_tick

    mov ecx, [tick_count]
    cmp ecx, TICKS_TASK_SWITCH
    jne .fin

    mov dword [tick_count], 0
    call sched_next_task
    cmp ax, 0
    je .fin

    str bx
    cmp ax, bx
    je .fin

    xchg bx, bx
    mov word [sched_task_selector], ax
    jmp far [sched_task_offset]

    .fin:
    popad
    iret

global _isr33
; COMPLETAR: Implementar la rutina
_isr33:
    ;prologo
    pushad ;pushea todos los registros de proposito general.

    
    in al, 60h
    push eax
    call process_scancode
    pop eax
    call pic_finish1

    popad
    iret ;iret porque se debe volver a la rutina de atencion de la interrupcion


;; Rutinas de atención de las SYSCALLS
;; -------------------------------------------------------------------------- ;;

global _isr88
; COMPLETAR: Implementar la rutina
_isr88:
    ;prologo
    pushad ;pushea todos los registros de proposito general.

    xor eax, eax 
    mov eax, 0x58

    ;no llamamos pic finish por ser interrupcion de sistema
    popad
    iret

global _isr98
; COMPLETAR: Implementar la rutina
_isr98:
;prologo
    pushad ;pushea todos los registros de proposito general.

    xor eax, eax 
    mov eax, 0x62

    ;no llamamos pic finish por ser interrupcion de sistema
    popad
    iret

; PushAD Order
%define offset_EAX 28
%define offset_ECX 24
%define offset_EDX 20
%define offset_EBX 16
%define offset_ESP 12
%define offset_EBP 8
%define offset_ESI 4
%define offset_EDI 0


;; Funciones Auxiliares
;; -------------------------------------------------------------------------- ;;
isrNumber:           dd 0x00000000
isrClock:            db '|/-\'
next_clock:
        pushad
        inc DWORD [isrNumber]
        mov ebx, [isrNumber]
        cmp ebx, 0x4
        jl .ok
        mov DWORD [isrNumber], 0x0
        mov ebx, 0
    .ok:
        add ebx, isrClock
        print_text_pm ebx, 1, 0x0f, 49, 79
        popad
        ret
