#include "syscall.h"
#include "stdbool.h"
#include "colors.h"
#include "i386.h"

#define KEY_SIZE 5
#define LEFT_MARGIN 0
#define TOP_MARGIN 15


void task(void) {

  while (true) {
	  __asm volatile("nop");
  }
}
