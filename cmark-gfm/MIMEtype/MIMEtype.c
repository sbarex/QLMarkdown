// Copyright Bradley Conroy 2014.
#define MAGIC_CHECK 0 //0 to avoid (slower) file access - only use ext.

#include "MIMEType.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <libgen.h> //basename TODO replace it with const version
#include <fcntl.h>  //open
#include <ctype.h>

#include <stdint.h>
#include <unistd.h>
#include <errno.h>

#define APPLICATION "\x00"
#define AUDIO "\x01"
#define CHEMICAL "\x02"		
#define IMAGE "\x03"		
#define INODE "\x04"		
#define MESSAGE "\x05"		
#define MODEL "\x06"		
#define MULTIPART "\x07"		
#define TEXT "\08"		
#define VIDEO "\09"

const char *major_types[]={"application","audio","chemical","image","inode","message","model","multipart","text","video"};
#define LEN(x) (sizeof(x)/sizeof(x[0])-2)

#include "mimes0.h"
#include "mimes4.h"
#include "mimes.h"

static const char *mime_from_ext(const char *ext){
	/* "sane" fallback?
		static char guess[128]="application/x-";
		strcat(guess,ext);
	*/
    if (ext==NULL) {
        return NULL;
    }
    //int i, len = LEN(mimes);
	size_t bot=0, len=LEN(mimes), top=len, i=(top>>1)&(~1);
	int cmp;
	for (; bot<=top && i<=len; i=((bot+top)>>1)&(~1)) {
    //for (i = 0; i<=len; i += 2) {
        const char *mime = mimes[i];
        // printf("%s\n", mime);
		cmp = strcmp(ext, mime);
        if (!cmp) {
             return mimes[i+1]; //match found
        } else if (cmp>0) {
            bot=i+2;
        } else {
            top=i-2;
        }
	}
	ext = strchr(ext, '.');
	return (ext) ? mime_from_ext(ext+1) : NULL;
}

static inline void lowercase(char *s){
	while (*s) {
		*s = tolower(*s);
		++s;
	}
}

static const char *mime_search(const char **mimes,size_t len,const char *buf){
	size_t bot=0, top=len, i=((bot+top)>>1) & (~1);
	int cmp;
	for (; bot<=top && i<=len; i=((bot+top)>>1)&(~1)) {
		cmp = memcmp(buf, mimes[i]+1, *mimes[i]);
        if (!cmp) {
            return mimes[i+1]; //match found
        } else if (cmp>0) {
            bot=i+2;
        } else {
            top=i-2;
        }
	}
	return NULL;
}

static const char *mime_from_magic(FILE *fd) {
	#define BUFLEN 256 //must be larger than max offset + max magic length
	char buf[BUFLEN];
	const char *ret;
    return (fread(buf, sizeof(char), BUFLEN, fd) < BUFLEN)? NULL:
		( ret = mime_search(mimes0,LEN(mimes0), buf) ) ? ret :
		mime_search(mimes4, LEN(mimes4), buf+4);
		//TODO mimes8 and mimesX + adjust BUFLEN to accomodate
}

char *get_mime(const char *path, MIME_MAGICK_CHECK check_magic) {
	char temp[strlen(path)+1], *fname, *ext;
	strcpy(temp, path); //todo rewrite own basename to take const char*
	fname = basename(temp);
	ext = strchr(fname, '.');
    if (ext == NULL) {
        ext = fname;
    } else {
        ext++; // skip the dot
    }
	lowercase(ext);
	const char *ret = mime_from_ext(ext);
    
    if (check_magic != MAGIC_NOT_CHECKED) {
        if (ret == NULL || check_magic == MAGIC_CONFRONT) {
            FILE *fd = fopen(path, "rb");
            if (fd) {
                const char *ret2 = mime_from_magic(fd);
                fclose(fd);
                if (ret && ret2 && memcmp(ret, ret2, 1) != 0) {
                    // different mayor type.
                    ret = NULL;
                } else {
                    ret = ret2;
                }
            } else {
                //else return something more useful than NULL?
                fprintf(stderr, "Error to get magic for file %s: #%d, %s\n", path, errno, strerror(errno));
            }
        }
    }
    if (!ret) {
        return NULL;
    }
    
    const char *major_type = major_types[*ret];
    int size1 = (int)strlen(major_type);
    int size2 = (int)strlen(ret);
    
    char *mime = calloc(size1 + size2 + 1, sizeof(char));
    
    strcpy(mime, major_type);
    strcat(mime, "/");
    strcat(mime, &ret[1]);
    
	return mime;
}
