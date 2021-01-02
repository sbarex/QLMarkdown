//
//  emoji_utils.hpp
//  QLMarkdown
//
//  Created by Sbarex on 23/12/20.
//

#ifndef emoji_utils_hpp
#define emoji_utils_hpp

#ifdef __cplusplus
extern "C" {
#endif

/**
  * Get the image url for a emoji placeholder.
  * @param placeholder Placeholder to replace
  * @return The image url or NULL if the placeholder is invalid. **User must release the memory.**
 */
char *get_emoji_url(const char *placeholder);

/**
  * Get the emoji for a placeholder.
  * @param placeholder Placeholder to replace
  * @return The emoji string or NULL if the placeholder is invalid. **User must release the memory.**
 */
char *get_emoji(const char *placeholder);

#ifdef __cplusplus
}
#endif
#endif /* emoji_utils_hpp */
