#if 0
static const struct { //must do linear search on these
const unsigned char *magic;
MIMEtype type;
unsigned short len;
unsigned short offset;
} extra_mimes[]={
{"Microsoft Word 6.0 Document",(MIMEtype){"application","msword"},27,2080},
{"Documento Microsoft Word 6",(MIMEtype){"application","msword"},26,2080},
{"Microsoft Excel 5.0 Worksheet",(MIMEtype){"application","vnd.ms-excel"},29,2080},
{"Foglio di lavoro Microsoft Exce",(MIMEtype){"application","vnd.ms-excel"},31,2080},
{"MSWordDoc",(MIMEtype){"application","msword"},9,2112},
{"CD001",(MIMEtype){"application","x-iso9660-image"},5,32769},
};
MIMEtype *mime_search(const MIMEMagic *mimes,int count,int offset,const char *buf){
int i=count>>1,bot=0,top=count,cmp;
for (; bot<=top; i=(bot+top)>>1){
cmp=memcmp(buf+offset,mimes[i].magic,mimes[i].len);
if (! cmp) return (MIMEtype *)&mimes[i].type; //match found
else if (cmp>0) bot=i+1;
else top=i-1;
}
return (MIMEtype *)NULL;
}
MIMEtype *mime_find(const char *buf,int offset, int len){
//TODO
int i;
for(i=0;i<(sizeof(extra_mimes)/sizeof(extra_mimes[0]));i++){
if (offset > extra_mimes[i].offset) continue;
if (offset+len < extra_mimes[i].offset) return (MIMEtype *)NULL;
if (!memcmp(buf+(extra_mimes[i].offset-offset),extra_mimes[i].magic,extra_mimes[i].len))
return (MIMEtype *)&extra_mimes[i].type;
}
return (MIMEtype *)NULL;
}

#endif
