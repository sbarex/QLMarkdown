//
//

#ifndef C_UNTITLED_URL_H
#define C_UNTITLED_URL_H

#ifdef __cplusplus
extern "C" {
#endif
void parse_url(const char *url, char **protocol, char **host, char **path, char **query);
#ifdef __cplusplus
}
#endif

#endif //C_UNTITLED_URL_H
