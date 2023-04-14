//
//  c_log.h
//  QLMarkdown
//
//  Created by Sbarex on 21/03/22.
//

#ifndef c_log_h
#define c_log_h

#include <os/log.h>

os_log_t getLogCategory(void);
os_log_t getLogForImageExt(void);
os_log_t getLogForHeadsExt(void);
os_log_t getLogForEmojiExt(void);

#endif /* c_log_h */
