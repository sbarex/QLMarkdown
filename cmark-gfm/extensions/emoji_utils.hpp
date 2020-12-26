//
//  emoji_utils.hpp
//  QLMardown
//
//  Created by Sbarex on 23/12/20.
//

#ifndef emoji_utils_hpp
#define emoji_utils_hpp

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Check if the text contains some emoji placeholders.
 * @param txt Source string.
 * @return 0 if no emoji whas found.
 */
int containsEmoji2(const char *txt);
/**
 * Replace all emoji placeholders.
 * @param txt Source string.
 * @param use_characters 1 for replacing the placeholders with emoticons, 0 to replace with an image tag.
 * @return Return the formatted text. **User must release the memory**. If no placeholder is replaced return NULL.
 */
char *replaceEmoji2(const char *txt, int use_characters);

#ifdef __cplusplus
}
#endif
#endif /* emoji_utils_hpp */
