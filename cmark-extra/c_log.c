//
//  c_log.c
//  QLMarkdown
//
//  Created by Sbarex on 21/03/22.
//

#include "c_log.h"

os_log_t sLog;
os_log_t sLogImageExt;
os_log_t sLogHeadsExt;
os_log_t sLogEmojiExt;

os_log_t getLogCategory(void) {
    if (sLog == NULL) {
        sLog = os_log_create("org.sbarex.QLMarkdown", "Rendering");
    }
    return sLog;
}

os_log_t getLogForImageExt(void) {
    if (sLogImageExt == NULL) {
        sLogImageExt = os_log_create("org.sbarex.QLMarkdown", "Inline Image Extension");
    }
    return sLogImageExt;
}

os_log_t getLogForHeadsExt(void) {
    if (sLogHeadsExt == NULL) {
        sLogHeadsExt = os_log_create("org.sbarex.QLMarkdown", "Heads Extension");
    }
    return sLogHeadsExt;
}

os_log_t getLogForEmojiExt(void) {
    if (sLogEmojiExt == NULL) {
        sLogEmojiExt = os_log_create("org.sbarex.QLMarkdown", "Emoji Extension");
    }
    return sLogEmojiExt;
}

