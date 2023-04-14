MIMEtype
========

Public domain MIME-type detector using file extensions and file signatures

**How it Works**

Detection by extension will take a file name and first check if the file name
is a registered MIME-type (LICENSE -> text/plain for example)
Then it will recursively check the largest extension (.tar.bz2 vs. just .bz2)
The extension list is in all lower case and sorted in alphabetical order so
a binary search can be done (n searches for 2^n entries)

_Note: MIMEtype includes its own version of strcasecmp for speed, (for inlining_
_and removes superfluous tolower() on internal strings)_

The file signatures are sorted by magic in ascii order @ offset X for memcmp.
This allows a binary search on file signatures starting at common offsets,
(the majority of file types use 0, 4 or 8 byte offsets).  All other
offsets are handled last using a linear search.

**TODO**

- add more types (ongoing - submit an issue here if one is broken/missing)
- add MIMEverify() to ensure extension matches magic
- win32 version of the magic detection (FILE* instead of fd)
- config menu to enable/disable types (for servers that only want some)
  - just delete lines from header files for now
- basic charset detection @ offset 0
  - utf-8 "xEF\xBB\xBF"
  - utf-16be "\xFE\xFF"
  - utf-16le "\xFF\xFE"
  - utf-32be "\x00\x00\xFE\xFF"
  - utf-32le "\xFF\xFE\x00\x00"
