#  Quicklook extension for markdown files

This app provide a quicklook extension to handle markdown files from macOS 10.15 onwards.

For maximum compatibility with the format, the [`cmark-gfm`](https://github.com/github/cmark-gfm) library is used[^footnote]. 

Since `cmark-gfm` is developed in C, part of the functionality of the app is offered through libraries written in golang to take advantage of a higher level language.

Compared to the standard `cmark-gfm` equipment, these extensions have been added:
- `emoji`: translate all emoji placeholder like ```:smile:``` defined by Github (see [this list](https://api.github.com/emojis)).
- `syntax highlight`: colorize the code inside fanced block using [Chroma](https://github.com/alecthomas/chroma) engine.
- `inline local images`: to embed linked image inside the formatted output.

From the Preferences window you can configure the options, enable the desidered extensions and set the output style.

## Options
The options follow those offered by the `cmark-gfm`:
- `hard break`: Render `softbreak` elements as hard line breaks.
- `no soft break`: Render `softbreak` elements as spaces.
- `unsafe raw HTML`: Render raw HTML and unsafe links (`javascript:`, `vbscript:`,  `file:`, and `data:`, except for `image/png`, `image/gif`,  `image/jpeg`, or `image/webp` mime types).  By default, raw HTML is replaced by a placeholder HTML comment. Unsafe links are replaced by empty strings.
- `validate UTF`: Validate UTF-8 in the input before parsing, replacing illegal sequences with the replacement character U+FFFD.
- `smart quotes`: Convert straight quotes to curly, ```---``` to em dashes, ```--``` to en dashes.
- `footnotes`: Parse footnotes.

## Extensions
- `table`: parse table as defined by the Github extension to the standard markdown language.
- `autolink`: automatically tranlate url to link.
- `tag filter`: strip potentially dangerous html tags (`<title>`,   `<textarea>`, `<style>`,  `<xmp>`, `<iframe>`,
`<noembed>`, `<noframes>`, `<script>`, `<plaintext>`).
- `task list`: parse task list as defined by the Github extension to the standard markdown language.
- `Github mentions`: tranlate mentions to link to the github account.
- `Strikethrough`: strikethrough text inside tildes. You can choose to detect single or doble tilde delimiters.
- `Emoji`: parse the emoji placeholder defined by [Github](https://api.github.com/emojis). You can render the emoji with an emoticons glyph or using the image provided by Github. It is possible that some placeholders (especially if they require a sequence of several unicode codes) are not supported by the system font.
- `inline local images`: inject in the html code the local images as base64 data[^footnote_inlineimages]. For security reasons are handled only urls without schema (e.g. `./image.jpg` or `image.jpg`), or with the `file` schema (e.g.  `file:///Users/username/Documents/image.jpg`)[^footnote_file_scheme] referring to existing files with an image type mime. This extension is required to render local images inside the quicklook preview.
- `Syntax Highlight`: colorize the source code inside a fenced box. The rendering engine is based on the [Chroma](https://github.com/alecthomas/chroma) library which is a golang project based on [Pygments](https://pygments.org/).

## Style
You can choose a css theme to render the markdown file. The app is provided with a predefined theme valid both for light and dark theme. You can also use a customized style sheet.

In the `Syntax Highlight extension` is enabled you can choose the theme for formatting the source code. There as some predefined themes but you can provide a customizes style. 
You can also choose to use the background defined by the langhuage theme or the background color defined for the source box inside the markdown style or a customized colour. This setting allows you to overwrite the background color in cases where it is the same as the background color of the document which would make the box with the source code difficult to recognize.


# Build from source
To build the app from source you must have the `go` compiler installed (you can use `brew install go`).
The build process compile the `Chroma` library as a universal binary (tested with go 1.15.5 on macOS Big Sur).
Also the empji extension uses some tools compiled from go code.


# Note about security
To allow the quicklook view of local images the extension has an exception to allow *only read access* to the entire system. 


---

[^footnote]: The library is a Github fork of the standard cmark tool to process the markdown files.
[^footnote_inlineimages]: The quick llok extension do not access to the local images defined inside the markdown code. 
[^footnote_file_scheme]: With the `file` scheme you always set the fullpath. For relative path (`./` or `../`) do not use the prefix  `file://`, also `./` is optional.
