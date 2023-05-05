//
//  extra-extensions.h
//  QLMarkdown
//
//  Created by Sbarex on 14/04/23.
//

#ifndef extra_extensions_h
#define extra_extensions_h

#ifdef __cplusplus
extern "C" {
#endif

#include "cmark-gfm-extension_api.h"
#include "cmark-gfm_export.h"

CMARK_GFM_EXPORT
void cmark_gfm_extra_extensions_ensure_registered(void);

#ifdef __cplusplus
}
#endif

#endif /* extra_extensions_h */
