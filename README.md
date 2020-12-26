#  Quicklook extension for markdown files

This app provide a quicklook extension to handle markdown files from macOS 10.15 onwards.

**The software is provided "as is", without any warranty of any kind.**

You can download the last compiled release (as universal binary) from [this link](https://github.com/sbarex/QLMarkdown/releases). 

To use the quicklook preview you must launch the application at least once. In this way the quicklook extension will be discovered by the system. 
After the first execution, the quicklook extension will be available (and enabled) among those present in the System preferences/Extensions.

For maximum compatibility with the markdown format, the [`cmark-gfm`](https://github.com/github/cmark-gfm) library is used[^footnote]. 

Compared to the standard `cmark-gfm` equipment, these extensions have been added:
- `Emoji`: translate the emoji placeholder like ```:smile:```.
- `Source code highlight`: colorize the code inside fenced block.
- `Inline local images`: embed the image files inside the formatted output.

From the Preferences window you can configure the options, enable the desired extensions and set the style.

## Options
The options follow those offered by the `cmark-gfm`:
- `hard break`: Render `softbreak` elements as hard line breaks.
- `no soft break`: Render `softbreak` elements as spaces.
- `unsafe raw HTML`: Render raw HTML and unsafe links (`javascript:`, `vbscript:`,  `file:`, and `data:`, except for `image/png`, `image/gif`,  `image/jpeg`, or `image/webp` mime types).  By default, raw HTML is replaced by a placeholder HTML comment. Unsafe links are replaced by empty strings.
- `validate UTF`: Validate UTF-8 in the input before parsing, replacing illegal sequences with the replacement character U+FFFD.
- `smart quotes`: Convert straight quotes to curly, ```---``` to em dashes, ```--``` to en dashes.
- `footnotes`: Parse footnotes.

## Extensions
- `Autolink`: automatically translate url to link.
- `Emoji`: parse the emoji placeholder defined by GitHub. You can render the emoji with an emoticons glyph or using the image provided by GitHub. It is possible that some placeholders (especially if they require a sequence of several unicode codes) are not supported by the system font.
- `GitHub mentions`: translate mentions to link to the GitHub account.
- `Inline local images`: inject in the html code the local images as base64 data[^footnote_inlineimages]. For security reasons are handled only urls without schema (e.g. `./image.jpg` or `image.jpg`), or with the `file` schema (e.g.  `file:///Users/username/Documents/image.jpg`)[^footnote_file_scheme] referring to existing files with an image mime type. This extension is required to render local images inside the quicklook preview.
- `Source code highlight`: colorize the source code inside a fenced box. 
- `Strikethrough`: strikethrough text inside tildes. You can choose to detect single or double tilde delimiters.
- `Table`: parse table as defined by the GitHub extension to the standard markdown language.
- `Tag filter`: strip potentially dangerous html tags (`<title>`,   `<textarea>`, `<style>`,  `<xmp>`, `<iframe>`, `<noembed>`, `<noframes>`, `<script>`, `<plaintext>`).
- `Task list`: parse task list as defined by the GitHub extension to the standard markdown language.

### Emoji extension
This extension translate the placeholder defined by [GitHub](https://api.github.com/emojis) into the corresponding emoji. 
It is possible to translate with the system emoji font or using the image provided by GitHub (internet connection required). 

Multibyte emoji are supported, so `:it:` equivalent to the code `\u1f1ee\u1f1f9` must be rendered as the Italian flag :it:. Some multibyte sequence may not be supported by the system font, in this case it is recommended to set the substitution with GitHub images.

### Inline local images extension
This extension is required only to render local images on the quicklook preview.

For security reason the quicklook preview (based on an html view) do not load local files. During the rendering process, the extension then embed the contents of the file on the html code as a base64 encoded data. This process operate only on local images (url without a scheme or with the `file://` scheme[^footnote_file_scheme]).

### Source code highlight extension
This extension highlight the source code inside a fenced box.

The rendering engine is based on the [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php). No external program is called, the engine is embedded in a library.

In the settings you can customize:

- the theme, for both light and dark appearance,
- show/hide the line numbers,
- word wrap options,
- use spaces instead of tabs for indentation,
- choose a font[^footnote_font],
- guess undefined language.

Some themes (especially those for light appearance) uses a white background that is the same of the markdown document, making the code block not immediately recognizable. For this reason it is possible to override the theme background color in order to use a personal one or the one defined by the markdown document. It is also possible to customize the theme used for language highlighting as desired. 

When the code block does not specify the language it is possible to activate a guessing function. Two engines are available:

- fast guess: it is based on the `magic` library
- accurate guess: it is based on the [`Enry`](https://github.com/go-enry/go-enry) library, that is a golang porting of the ruby [`linguist`](https://github.com/github/linguist/) library used by GitHub.

If no language is defined and the gueessing fail, the code is rendered as normal text.

## Style
You can choose a css theme to render the markdown file. The app is provided with a predefined theme valid both for light and dark theme. 

Also it is possible to use a style to extend the standard theme or to complete override. 
User customized style sheet must have the settings for both light and dark appearance using the css media query:

```css
@media (prefers-color-scheme: dark) { 
    /* … */ 
}
``` 
The custom style is appended after the css used for the source code. In this way you can customize also the style of the language code. 


# Source highlight theme editor

TODO

# Build from source

## Dependency

The app uses two extra libraries:

- `highlight wrapper`: a custom c++ shared library that expose the `highlight` functionality and the emoji replacement
- `go utils`: a custom static library developed in go for the accurate guess language type engine.

The two libraries are build as universal binary.

The `highlight wrapper` is provided as precompiled (*TODO: insert the build process on the project*). It has statically linked these libraries:
- [`highlight` v3.60](http://www.andre-simon.de/doku/highlight/en/highlight.php) (for source code highlight)
- [`lua` v5.4.1](https://www.lua.org/) (required by `highlight`)
- [`magic` v5.39](https://www.darwinsys.com/file/)  (used to guess the source code language when the guess mode is set to _fast_).

The `go utils` library is build with the Xcode project. So you must have the `go` compiler installed (you can use `brew install go`). It has linked the [`Enry`](https://github.com/go-enry/go-enry) library used to guess the source code language when the guess mode is set to _accurate_.

# Note about security
To allow the quicklook view of local images the extension has an entitlement exception to allow *only read access* to the entire system. 

On Big Sur there is a bug in the quicklook engine and webkit that cause the immediate crash of any WebView inside a quicklook preview. To temporary fix this problem this quicklook extension uses a `com.apple.security.temporary-exception.mach-lookup.global-name` entitlement. 

---

[^footnote]: The library is a GitHub fork of the standard cmark tool to process the markdown files.
[^footnote_inlineimages]: The quick look extension can not access to the local images defined inside the markdown code, so embedding the data it's a way around the limitation. 
[^footnote_file_scheme]: With the `file://` scheme you *always set the fullpath*. For images inside the same folder of the markdown file do not use the scheme  `file://` and also `./` is optional.
[^footnote_font]: Setting a custom font also change the font used in the code blocks enclosed by back-ticks (\`).
