/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones del manejador de memoria
*/

#include "mmu.h"
#include "i386.h"

#include "kassert.h"

static pd_entry_t* kpd = (pd_entry_t*)KERNEL_PAGE_DIR;
static pt_entry_t* kpt = (pt_entry_t*)KERNEL_PAGE_TABLE_0;

static const uint32_t identity_mapping_end = 0x003FFFFF;
static const uint32_t user_memory_pool_end = 0x02FFFFFF;

static paddr_t next_free_kernel_page = 0x100000;
static paddr_t next_free_user_page = 0x400000;

/**
 * kmemset asigna el valor c a un rango de memoria interpretado 
 * como un rango de bytes de largo n que comienza en s 
 * @param s es el puntero al comienzo del rango de memoria
 * @param c es el valor a asignar en cada byte de s[0..n-1]
 * @param n es el tamaño en bytes a asignar
 * @return devuelve el puntero al rango modificado (alias de s)
*/
static inline void* kmemset(void* s, int c, size_t n) {
  uint8_t* dst = (uint8_t*)s;
  for (size_t i = 0; i < n; i++) {
    dst[i] = c;
  }
  return dst;
}

/**
 * zero_page limpia el contenido de una página que comienza en addr
 * @param addr es la dirección del comienzo de la página a limpiar
*/
static inline void zero_page(paddr_t addr) {
  kmemset((void*)addr, 0x00, PAGE_SIZE);
}


void mmu_init(void) {}


/**
 * mmu_next_free_kernel_page devuelve la dirección de la próxima página de kernel disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de kernel
 */
paddr_t mmu_next_free_kernel_page(void) {
  paddr_t next = next_free_kernel_page;
  next_free_kernel_page += PAGE_SIZE;
  return next;

}

/**
 * mmu_next_free_user_page devuelve la dirección de la próxima página de usuarix disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de usuarix
 */
paddr_t mmu_next_free_user_page(void) {

  paddr_t next = next_free_user_page;
  next_free_user_page += PAGE_SIZE;
  return next;
}

/**
 * mmu_init_kernel_dir inicializa las estructuras de paginación vinculadas al kernel y
 * realiza el identity mapping
 * @return devuelve la dirección de memoria de la página donde se encuentra el directorio 
 * de páginas usado por el kernel
 */
paddr_t mmu_init_kernel_dir(void) {


 
  //necesito dos paginas vacias para kpd y kpt
  zero_page((paddr_t)kpt);
  zero_page((paddr_t)kpd);
  
  //la entrada 0 de kpd deberia apuntar a kpt
  kpd[0].pt = ((paddr_t)kpt) >> 12;
  kpd[0].attrs = 3;
  
  for(uint32_t i=0; i<1024; i++){
    kpt[i].page = i;
    kpt[i].attrs = 3; //11: 1 de present y 1 de r/w
  }
  

 return (paddr_t)kpd;



  

}

/**
 * mmu_map_page agrega las entradas necesarias a las estructuras de paginación de modo de que
 * la dirección virtual virt se traduzca en la dirección física phy con los atributos definidos en attrs
 * @param cr3 el contenido que se ha de cargar en un registro CR3 al realizar la traducción
 * @param virt la dirección virtual que se ha de traducir en phy
 * @param phy la dirección física que debe ser accedida (dirección de destino)
 * @param attrs los atributos a asignar en la entrada de la tabla de páginas
 */
void mmu_map_page(uint32_t cr3, vaddr_t virt, paddr_t phy, uint32_t attrs) {

  pd_entry_t* kpd_tarea = CR3_TO_PAGE_DIR(cr3);
 
  uint32_t entrada_kpd_tarea = VIRT_PAGE_DIR(virt);
  uint32_t entrada_kpt_tarea = VIRT_PAGE_TABLE(virt);

  //nos fijamos si la tabla esta presente
  if(!(kpd_tarea[entrada_kpd_tarea].attrs << 31)){
    pd_entry_t entrada;
    entrada.pt = mmu_next_free_kernel_page()>>12;
    //agregar bit de usuario
    entrada.attrs = 7;
    kpd_tarea[entrada_kpd_tarea] = entrada;
  }

  // 0 -> 0x00000000
  // 1 -> 0x00001000
  // 15 (f) -> 0x0000F000
  // abc -> 0x00ABC000
  // 1 << 3*4

  pt_entry_t* page_table = (pt_entry_t*)((kpd_tarea[entrada_kpd_tarea]).pt << 12);
  page_table[entrada_kpt_tarea].page = phy >> 12;
  page_table[entrada_kpt_tarea].attrs = attrs;


  tlbflush(); 
  
}

/**
 * mmu_unmap_page elimina la entrada vinculada a la dirección virt en la tabla de páginas correspondiente
 * @param virt la dirección virtual que se ha de desvincular
 * @return la dirección física de la página desvinculada
 */
paddr_t mmu_unmap_page(uint32_t cr3, vaddr_t virt) {
   pd_entry_t* kpd_tarea = CR3_TO_PAGE_DIR(cr3);
 
  //agregar if por las dudas
  uint32_t dir_virt = VIRT_PAGE_DIR(virt);
  paddr_t* kpt_tarea = kpd_tarea[dir_virt].pt << 12;

  kpd_tarea[dir_virt].attrs &= ~0x1; 

  tlbflush();

  return kpt_tarea[VIRT_PAGE_TABLE(virt)]; 


}

#define DST_VIRT_PAGE 0xA00000
#define SRC_VIRT_PAGE 0xB00000

/**
 * copy_page copia el contenido de la página física localizada en la dirección src_addr a la página física ubicada en dst_addr
 * @param dst_addr la dirección a cuya página queremos copiar el contenido
 * @param src_addr la dirección de la página cuyo contenido queremos copiar
 * 
 * Esta función mapea ambas páginas a las direcciones SRC_VIRT_PAGE y DST_VIRT_PAGE, respectivamente, realiza
 * la copia y luego desmapea las páginas. Usar la función rcr3 definida en i386.h para obtener el cr3 actual
 */
void copy_page(paddr_t dst_addr, paddr_t src_addr) {
  pd_entry_t* kpd_tarea = CR3_TO_PAGE_DIR(rcr3());
  uint32_t dir_virt = VIRT_PAGE_DIR(src_addr);

  paddr_t * dir_phy = kpd_tarea[dir_virt].pt << 12;

  mmu_map_page(rcr3(), SRC_VIRT_PAGE, src_addr, kpd_tarea[dir_virt].attrs);
  mmu_map_page(rcr3(), DST_VIRT_PAGE, dst_addr, kpd_tarea[dir_virt].attrs);

  int* src_dir = (int*) SRC_VIRT_PAGE;
  int* dst_dir = (int*) DST_VIRT_PAGE;
  for(int i=0; i<1024; i++){
    dst_dir[i] = src_dir[i];
  }

  mmu_unmap_page(rcr3(), src_dir);
  mmu_unmap_page(rcr3(), dst_dir);

}

 /**
 * mmu_init_task_dir inicializa las estructuras de paginación vinculadas a una tarea cuyo código se encuentra en la dirección phy_start
 * @pararm phy_start es la dirección donde comienzan las dos páginas de código de la tarea asociada a esta llamada
 * @return el contenido que se ha de cargar en un registro CR3 para la tarea asociada a esta llamada
 */
paddr_t mmu_init_task_dir(paddr_t phy_start) {


  pd_entry_t* kpd_tarea = mmu_next_free_kernel_page();
  zero_page((paddr_t)kpd_tarea);
  
  

  mmu_map_page(kpd_tarea, 0X08000000, phy_start, 7);
  mmu_map_page(kpd_tarea, 0X08000000 + PAGE_SIZE, phy_start + PAGE_SIZE, 7); //+4000 para la proxima pagina


  pt_entry_t* stack = (pt_entry_t*) mmu_next_free_user_page();
  mmu_map_page(kpd_tarea, 0X08002000, stack, 7);

  //mappeo por identidad, pero aprovechando map_page
  for(int i = 0; i < 1024; i++){
    mmu_map_page(kpd_tarea, i*PAGE_SIZE,i*PAGE_SIZE, 3);
  }

  return kpd_tarea;

  

}


