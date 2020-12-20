//
//  test.h
//  QLMardown
//
//  Created by Sbarex on 10/12/20.
//

#ifndef test_h
#define test_h

#include <stdio.h>
#include "cmark-gfm.h"
#include "cmark-gfm-extension_api.h"

CMARK_GFM_EXPORT
int processMyDoc(cmark_node *root);
#endif /* test_h */
