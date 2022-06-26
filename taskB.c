#include "syscall.h"
#include "stdbool.h"
#include "colors.h"

#define SHARED_MEMORY_SIZE 32
#define PAGE_SIZE 4096
#define KEY_SIZE 5

#define LEFT_MARGIN 0
#define TOP_MARGIN 15


void task(void) {
  while (true) {
    __asm volatile("nop");
  }
}
