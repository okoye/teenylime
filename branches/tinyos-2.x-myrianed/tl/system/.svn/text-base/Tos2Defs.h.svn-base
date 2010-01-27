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

#define result_t error_t

#define TOS_LOCAL_ADDRESS call AMPacket.address()

#define TOS_MsgPtr message_t*
#define TOS_Msg message_t

// for the moment include uart debugging output for myrianed
#ifndef myrianode
#define uart_puts (void)
#define uart_puthex2 (void)
#define uart_puthex4 (void)
#define uart_putchr (void)
#define uart_puthex (void)
#endif


#define dbg3(m...) dbg(DBG_USR3, ## m)

#define _asm asm
#define DBG_USR1 "paolo"
#define DBG_USR2 "luca"
#define DBG_USR3 "laurens"
#define DBG_ERROR "error"

#endif // TOS2DEFS_H

