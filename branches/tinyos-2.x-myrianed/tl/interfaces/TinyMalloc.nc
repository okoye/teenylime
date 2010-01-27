



interface TinyMalloc {
//  command void setStorageArea(char *storageArea, uint16_t newSize);
  command char *malloc(uint16_t bytes);
  command void free(void *ptr, uint16_t bytes);
}
