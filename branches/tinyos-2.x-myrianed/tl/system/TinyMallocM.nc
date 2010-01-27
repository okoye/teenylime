

module TinyMallocM {
  provides interface TinyMalloc;
  provides interface Init;
}

implementation {
  enum {
    MALLOC_FAIL = 0, PERFECT_FIT, LOOSE_FIT
  };

  struct freeBlock_str {
    char *next;
    uint16_t size;
  } PACKED;
  typedef struct freeBlock_str freeBlock_t;

  char dataStart[TINYMALLOC_SIZE];
  freeBlock_t *firstFreeBlock = (freeBlock_t *) dataStart;
  // Debugging variables:
  uint16_t allocated = 0;
  uint16_t initialFree = TINYMALLOC_SIZE;


  command error_t Init.init() {
    firstFreeBlock->next = NULL;
    firstFreeBlock->size = TINYMALLOC_SIZE;
    dbg("TinyMallocC","TinyMalloc dataStart @ %hu\n",dataStart);
    return SUCCESS;
  }


  // Debugging function
  void checkFreeSpace(int diff) {
    #if defined(pc) || defined(sim)
      uint16_t freeBytes = 0;
      freeBlock_t *f = firstFreeBlock;

      // Check number of allocated bytes
      allocated += diff;

      while (f != NULL) {
        freeBytes += f->size;
        f = (freeBlock_t *) f->next;
      }
      dbg("TinyMallocC","Free byte count: %hu, allocated: %hu\n",freeBytes, allocated);
      dbg("TinyMallocC","First free block is now: %hu (%hu bytes)\n",firstFreeBlock,firstFreeBlock->size);

      if (freeBytes + allocated != initialFree) {
        err("ERROR! sum of free and allocated bytes is unequal to %hu\n",initialFree);
      }
      dbg("TinyMallocC","\n\n");
    #endif
  }


  uint16_t adjustBytes(uint16_t bytes) {
    // We can't allocate blocks that are too small.
    // This would cause a problem when the block is freed.
    // When the block is freed, it will be put in the linked list of free blocks, and
    // some space is needed for a pointer and the size of the free block.
    if (bytes < sizeof(freeBlock_t)) {
      bytes = sizeof(freeBlock_t);
      dbg("TinyMallocC", "too small, adjusting to %hu bytes...\n",bytes);
    }

    // Align everything on 2 byte boundaries.
    // This reduces fragmentation, and delay.
    // In addition, we avoid trouble with word aligned cpu's.
    bytes += 1;
    bytes &= 0xFFFE;
    return bytes;
  }

  command char *TinyMalloc.malloc(uint16_t bytes) {
    int i = 0,j = 0;
    freeBlock_t *newBlock;
    freeBlock_t *previousBlock, *nextBlock;
    uint8_t result = MALLOC_FAIL;

    dbg("TinyMallocC","Malloc %hu bytes...",bytes);
    bytes = adjustBytes(bytes);

    newBlock = firstFreeBlock;
    previousBlock = firstFreeBlock;

    // Search procedure:
    // First try to find a block with a perfect fit.
    // Only if such block doesn't exist, we will try larger blocks.
    // This strategy reduces fragmentation of free blocks.
    // To make things faster, the following can be done: do not allow fragments to get smaller
    // than the smallest block you allocate, eg, the smallest tuple.
    // In addition, use block alignment. For example, align on 4 byte boundaries.
    // This can be set easily in adjustBytes().
    while(newBlock != NULL) {
      i++;
      if (newBlock->size == bytes) {
        result = PERFECT_FIT;
        break;
      }
      previousBlock = newBlock;
      newBlock = (freeBlock_t*) newBlock->next;
    }
    if (result == MALLOC_FAIL) {
      newBlock = firstFreeBlock;
      previousBlock = firstFreeBlock;
      // Search again, this time the block may be bigger than necessary.
      while(newBlock != NULL) {
        j++;
        if (newBlock->size > sizeof(freeBlock_t) - 1 + bytes) {
          result = LOOSE_FIT;
          break;
        }
        previousBlock = newBlock;
        newBlock = (freeBlock_t*)newBlock->next;
      }
    }
//    dbg3("went through %d + %d free blocks\n",i,j);
//    dbg("TinyMallocC","went through %u + %u free blocks\n",i);
    dbg("TinyMallocC","newblock found @ %hu\n",newBlock);
    if (result == LOOSE_FIT) {
      // Block found, with free space after the block
      dbg("TinyMallocC","Block found, with free space after the block: loose fit\n");
      if (newBlock != firstFreeBlock) {
        dbg("TinyMallocC","New block != firstFreeBlock\n");
        nextBlock = (freeBlock_t*) &(((char*)newBlock)[bytes]);
        dbg("TinyMallocC", "Next block moved to %hu\n",nextBlock);
        nextBlock->size = newBlock->size - bytes;
        nextBlock->next = newBlock->next;
        previousBlock->next = (char*) nextBlock;
      } else {
        dbg("TinyMallocC","New block == firstFreeBlock\n");
        firstFreeBlock = (freeBlock_t*) &(((char*)firstFreeBlock)[bytes]);
        firstFreeBlock->size = newBlock->size - bytes;
        firstFreeBlock->next = newBlock->next;
        dbg("TinyMallocC", "allocating part of first free block, firstFreeBlock is now @ %hu, size %hu\n", firstFreeBlock, firstFreeBlock->size);
      }
    } else if (result == PERFECT_FIT) {
      // Perfect match, the new block has exactly the required size.
      dbg("TinyMallocC","Perfect match, the free block found has exactly the required size: perfect fit.\n");
      if (newBlock != firstFreeBlock) {
        dbg("TinyMallocC","newBlock != firstFreeBlock\n");
        previousBlock->next = newBlock->next;
      } else {
        dbg("TinyMallocC","newBlock == firstFreeBlock\n");
        firstFreeBlock = (freeBlock_t *) newBlock->next;
      }
    } else {
      dbg("ERROR","malloc failed: no new block found\n");
      return NULL;
    }
    checkFreeSpace(bytes);
    return (char *)newBlock;
  }


  command void TinyMalloc.free(void *ptr, uint16_t bytes) {
    freeBlock_t *p = ptr;
    freeBlock_t *f = firstFreeBlock;
    freeBlock_t *previous = firstFreeBlock;

    bytes = adjustBytes(bytes);

    dbg("TinyMallocC","free %hu, %hu bytes\n", ptr, bytes);
    while (f != NULL && f < p) {
      previous = f;
      f = (freeBlock_t*) f->next;
    }

    if ((ptr_arithm_t)previous + previous->size == (ptr_arithm_t)p) {
      // Freed block is right after free block 'previous'
      dbg("TinyMallocC","Freed block is right after free block 'previous'\n");
      if ((ptr_arithm_t)p + bytes == (ptr_arithm_t)previous->next) {
        // Freed block is enclosed by free blocks
        dbg("TinyMallocC","Freed block is enclosed by free blocks\n");
        previous->size += bytes + f->size;
        previous->next = f->next;
      } else {
        // Freed block is right after free block 'previous', but not enclosed between free blocks
        dbg("TinyMallocC","Freed block is right after free block 'previous', but not enclosed between free blocks\n");
        previous->size += bytes;
      }
    } else if (previous < p) {
      // Freed block is somewhere after free block 'previous', but not adjacent to it.
      dbg("TinyMallocC","Freed block is somewhere after free block 'previous', but not adjacent to it.\n");
      if ((ptr_arithm_t)p + bytes == (ptr_arithm_t)previous->next) {
        // There is a free block right after the freed block
        dbg("TinyMallocC","There is a free block right after the freed block\n");
        p->size = bytes + f->size;
        p->next = f->next;
        previous->next = (void*) p;
      } else {
        // Freed block is somewhere between two free blocks, but not adjacent to them
        dbg("TinyMallocC","Freed block is somewhere between two free blocks, but not adjacent to them\n");
        p->next = previous->next;
        p->size = bytes;
        previous->next = (void*)p;
      }
    } else {
      // 'previous' is bigger than p, therefore it has to be the first free block
      dbg("TinyMallocC","'previous' (%hu) is bigger than p, therefore it has to be the first free block (%hu) \n",previous, firstFreeBlock);

      if (previous != firstFreeBlock) {
        err("Something wrong in TinyMallocC.free()\n");
        err("First free block: %hu, block to free: %hu, previous in list: %hu\n",firstFreeBlock, p, previous);
      }
//      dbg("TinyMallocC","p = %hu\n",p);
//      dbg("TinyMallocC","p + bytes = %hu\n",(uint16_t)p+bytes);
      if ((ptr_arithm_t)p + bytes == (ptr_arithm_t)firstFreeBlock) {
        // First free block is right after the freed block
        dbg("TinyMallocC","First free block is right after the freed block\n");
        p->size = bytes + firstFreeBlock->size;
        p->next = firstFreeBlock->next;
        firstFreeBlock = p;
      } else {
        dbg("TinyMallocC","First free block is somewhere after the freed block, but not adjacent\n");
        p->size = bytes;
        p->next = (void*)firstFreeBlock;
        firstFreeBlock = p;
      }
    }
    checkFreeSpace(-1 * bytes);
  }

}
