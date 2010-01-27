#ifndef MSG_H
#define MSG_H

enum {
  TYPE_QUERY, TYPE_REPLY, TYPE_INTEREST, DATA_HUMIDITY, DATA_TEMPERATURE
};

typedef struct {
  uint8_t type;
  uint8_t dataType;
  uint16_t sender;

} BenchmarkMsg;

#endif
