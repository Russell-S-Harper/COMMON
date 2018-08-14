#ifndef __ROM_H
#define __ROM_H

; ROM addresses
CMN_CD	= $F800
CMN_DT	= $FF00

; macros
#define CMN	JSR CMN_CD

#endif /* __ROM_H */
