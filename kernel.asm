; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"
global start

; COMPLETAR - Agreguen declaraciones extern según vayan necesitando
extern GDT_DESC
extern code_0_sel
extern data_0_sel
extern screen_draw_layout
extern IDT_DESC
extern pic_reset
extern pic_enable
extern idt_init
extern mmu_init_kernel_dir
extern tss_init
extern mmu_init_task_dir
extern GDT_IDX_TASK_INITIAL 
extern copy_page
extern sched_init
extern task_init
extern mmu_next_free_user_page
%define GDT_IDX_TASK_IDLE 12<<3
; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL 0x08
; ¿¿¿¿¿¿¿¿¿???????????????
%define DS_RING_0_SEL 0x18


BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:

    ; COMPLETAR - Deshabilitar interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 fontCS_RING_0_SEL

    
    print_text_rm start_rm_msg, start_rm_len, 0x07, 0, 0  


    call A20_enable

    ; COMPLETAR - Cargar la GDT
    lgdt [GDT_DESC]


    

    ; COMPLETAR - Setear el bit PE del registro CR0
    xor ecx, ecx
    inc ecx
    xor eax, eax
    mov eax, cr0
    or eax, ecx
    mov cr0, eax




    ; COMPLETAR - Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp 0x08:modo_protegido

BITS 32
modo_protegido:
    ; COMPLETAR - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    mov ax, DS_RING_0_SEL
    mov DS, ax
    mov ES, ax
    mov GS, ax
    mov FS, ax
    mov SS, ax
    ;xchg bx, bx 
    
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo

    ; COMPLETAR - Establecer el tope y la base de la pila

    mov ebp, 0x25000
    mov esp, 0x25000

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg, start_pm_len, 0x0007, 0, 0 
    
    ; COMPLETAR - Inicializar pantalla
    
    ; call screen_draw_layout

    call mmu_init_kernel_dir
    mov cr3, eax
  
    mov eax, cr0
    or eax, 1<<31 
    mov cr0, eax
  
    call idt_init
    lidt [IDT_DESC]

    call pic_reset
    call pic_enable
  
;-----------------------------------------------------------------

   
  
    ; push 0x25000
    ; push 0x28000
    ; call copy_page
    ; add esp, 8

    
    ;call mmu_init_task_dir ;no se estaba creando el directorio de tareas

    call tss_init
  
    mov ax, 11<<3
    ltr ax
    call sched_init
    
    call task_init


    sti 
    jmp GDT_IDX_TASK_IDLE:0


 

  
  

    
    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $
;; -------------------------------------------------------------------------- ;;


   

%include "a20.asm"
