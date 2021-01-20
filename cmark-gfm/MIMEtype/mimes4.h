/* sort by magic in ascii order @ offset 0 for memcmp. A-Z comes before a-z
 * 1st char in magic (1st) string is the length in hex
 * followed by major and minor typr strings
 * 1st char in mime (2nd) string is the major type in hex
 */

static const char *mimes4[] = {
	"\x0D" "\x0AVersion:Vivo",             VIDEO "vivo",
	// "\x07" "#VRML V",                      MODEL "vrml",
	// "\x1C" "-BEGIN PGP PUBLIC KEY BLOCK-", APPLICATION "pgp-keys",
	// "\x04" "XPR3",                         APPLICATION "x-quark-xpress-3",
	// "\x04" "XPRa",                         APPLICATION "x-quark-xpress-3",
	"\x04" "free",                         VIDEO "quicktime",
	"\x07" "ftyp3g2",                      VIDEO "3gpp2",
	"\x07" "ftyp3ge",                      VIDEO "3gpp",
	"\x07" "ftyp3gg",                      VIDEO "3gpp",
	"\x07" "ftyp3gp",                      VIDEO "3gpp",
	"\x07" "ftyp3gs",                      VIDEO "3gpp",
	"\x07" "ftypM4A",                      AUDIO "mp4",
	"\x07" "ftypM4B",                      VIDEO "quicktime",
	"\x07" "ftypM4P",                      VIDEO "quicktime",
	"\x07" "ftypM4V",                      VIDEO "mp4",
	"\x08" "ftypavc1",                     VIDEO "3gpp",
	"\x08" "ftypiso2",                     VIDEO "mp4",
	"\x08" "ftypisom",                     VIDEO "mp4",
	"\x07" "ftypjp2",                      IMAGE "jp2",
	"\x08" "ftypmmp4",                     VIDEO "mp4",
	"\x08" "ftypmp41",                     VIDEO "mp4",
	"\x08" "ftypmp42",                     VIDEO "mp4",
	"\x08" "ftypmp7b",                     VIDEO "mp4",
	"\x08" "ftypmp7t",                     VIDEO "mp4",
	"\x06" "ftypqt",                       VIDEO "quicktime",
	"\x04" "idat",                         VIDEO "quicktime",
	"\x04" "idsc",                         VIDEO "quicktime",
	"\x02" "jP",                           IMAGE "jp2",
	"\x04" "mdat",                         VIDEO "quicktime",
	// "\x04" "pckg",                         APPLICATION "x-quicktime-player",
	"\x04" "skip",                         VIDEO "quicktime",
	"\x04" "wide",                         VIDEO "quicktime",
};
