 /**
 *	Some forward definitions to make tl compile under tinyos-2.x
 *  Most of these will be removed somewhere in the future.
 *
 *   @author Laurens Bronwasser
 *         <a href="mailto:bronwasser@gmail.com">bronwasser@gmail.com</a>
 *
 */



#ifndef TOS2DEFS_H
#define TOS2DEFS_H

//#include "message.h"

#define result_t error_t
//#define TOS_LOCAL_ADDRESS TOS_NODE_ID
#define TOS_LOCAL_ADDRESS call AMPacket.address()

#define TOS_MsgPtr message_t*
#define TOS_Msg message_t

// for the moment include uart debugging output for myrianed
#ifndef myrianed
#define uart_puts (void)
#define uart_puthex2 (void)
#define uart_puthex4 (void)
#define uart_putchr (void)
#define uart_puthex (void)
#endif
#define dbg3(m...) dbg(DBG_USR3, ## m)

#ifdef myrianed
#include "uart.h"
#define on3 PORTE |= _BV(PINE3);
#define off3 PORTE &= ~_BV(PINE3);
#define on4 PORTE |= _BV(PINE4);
#define off4 PORTE &= ~_BV(PINE4);
#define on5 PORTE |= _BV(PINE5);
#define off5 PORTE &= ~_BV(PINE5);

//#define mydbg(m, f, s...) uart_puts(f)
#endif
#define _asm asm

#endif // TOS2DEFS_H

