<p align="center">
  <img src="assets/img/icon.png" width="150" alt="logo" />
</p>

# QLMarkdown

QLMarkdown is a macOS Quick Look extension to preview Markdown files. It can also preview textbundle packages and rmarkdown (`.rmd`) files (_without_ evaluating `r` code).  

> **Please note that this software is provided "as is", without any warranty of any kind.**

You can download the last compiled release (as universal binary) from [this link](https://github.com/sbarex/QLMarkdown/releases). The application also has the automatic update function.

  - [Screenshots](#screenshots)
    - [Quick Look Markdown preview](#quick-look-markdown-preview)
  - [Installation](#installation)
  - [Markdown processing](#markdown-processing)
  - [Difference with the GitHub Markdown engine](#difference-with-the-github-markdown-engine)
  - [Settings](#settings)
    - [Options](#options)
    - [Extensions](#extensions)
      - [Autolink](#autolink)
      - [Emoji](#emoji)
      - [GitHub mentions](#github-mentions)
      - [Heads anchors](#heads-anchors)
      - [Inline local images](#inline-local-images)
      - [Syntax Highlighting](#syntax-highlighting)
      - [Strikethrough](#strikethrough)
      - [Table](#table)
      - [Tag filter](#tag-filter)
      - [Task list](#task-list)
      - [YAML header](#yaml-header)
    - [Themes](#themes)
  - [Command line interface](#command-line-interface)
  - [Build from source](#build-from-source)
    - [Dependency](#dependency)
  - [Note about security](#note-about-security)
  - [Note about the developer](#note-about-the-developer)


## Screenshots

### Quick Look Markdown preview

![main interface](./assets/img/preview-screenshot.png)

## Installation

You can download the last compiled release (as universal binary) from [this link](https://github.com/sbarex/QLMarkdown/releases) or you can install the Application with [Homebrew](https://brew.sh/):   

```shell
brew install --cask sbarex-qlmarkdown
```

The application has the automatic update function.

To use the Quick Look preview you must launch the application at least once. In this way the Quick Look extension will be discovered by the system. 
After the first execution, the Quick Look extension will be available (and enabled) among those present in the System preferences/Extensions.

If you have problems, try moving the application to the trash and then back in the Applications folder. 
If the `QLMarkdown Preview Extension` is present (and checked) in the list of Quick Look Extensions in the System preferences but the `.md` files are not displayed it is probably due to other applications that have registered support for that type of file. You can change the order of priority of the Quick Look Extensions indide the System preferences.

Finally, the problems may depend on how the `.md` files were registered on the system by other applications.

In the terminal try the following command:

```
mdls -name kMDItemContentType PATH_OF_AN_EXISTS_MD_FILE
```

The output is the UTI associated with the `.md` file.

This application handle these UTIs:
- net.daringfireball.markdown
- com.unknown.md
- net.ia.markdown
- org.textbundle.package
- dyn.ah62d4rv4ge8043a (dynamic UTI for unassociated .md files)
- dyn.ah62d4rv4ge81e5pe (dynamic UTI for unassociated .rmd files)
- com.rstudio.rmarkdown

Please inform me of any other UTI associated to `.md` files.


## Markdown processing

For maximum compatibility with the Markdown format, the [`cmark-gfm`](https://github.com/github/cmark-gfm) library is used. The library is a GitHub fork of the standard cmark tool to [process the Markdown files](https://github.github.com/gfm/). 

Compared to the `cmark-gfm`, these extensions have been added:
- `Emoji`: translate the emoji placeholders like `:smile:`.
- `Heads anchors`: create anchors for the heads.
- `Inline local images`: embed the image files inside the formatted output (required for the Quick Look preview).
- `Syntax highlighting`: highlight the code inside fenced block.

## Difference with the GitHub Markdown engine

Although GitHub has customized the [`cmark-gfm`](https://github.com/github/cmark-gfm) library, it does not use it directly in the rendering process of Markdown files (see [this repository](https://github.com/github/markup)).
GitHub uses a number of libraries in Ruby for parsing and formatting source code that cannot easily be converted into a compiled library.

The accurate engine for the language detection (used however only when the language is not specified) is a library derived from the [`Linguistic`](https://github.com/github/linguist#syntax-highlighting) framework used by GitHub.

So, the main difference between this application and GitHub is in the choice of the theme and in the formatting of the source code.

The syntax highlighting is based to a different library, so the formatting, colors scheme, and token recognition of the language is potentially different.

## Settings

Launching the application, you can configure the options, enable the desired extensions and set the theme for formatting the Quick Look preview of Markdown files.

![main interface](./assets/img/main_interface.png)

Some lesser-used options are available in the advanced panel.

![main interface](./assets/img/main_interface_advanced.png)

Also, the theme popup menu has some extra commands available pressing the `alt` key.

### Options

The options follow those offered by the `cmark-gfm`:
- `Hard break` _(available on advanced options panel)_: Render `softbreak` elements as hard line breaks.
- `No soft break` _(available on advanced options panel)_: Render `softbreak` elements as spaces.
- `Inline HTML (unsafe)` _(available on advanced options panel)_: Render raw HTML and unsafe links (`javascript:`, `vbscript:`,  `file:`, and `data:`, except for `image/png`, `image/gif`,  `image/jpeg`, or `image/webp` mime types) present in the Markdown file.  By default, HTML tags are stripped and unsafe links are replaced by empty strings. _So this option is required for preview SVG images_.
- `Validate UTF` _(available on advanced options panel)_: Validate UTF-8 in the input before parsing, replacing illegal sequences with the standard replacement character (U+FFFD &#xFFFD;).
- `Smart quotes`: Convert straight quotes to curly, ```---``` to em dashes and ```--``` to en dashes.
- `Footnotes`: Parse the footnotes.

In the advanced options, you can also choose if open external link inside the Quick Look preview window or in the default browser.

### Extensions

#### Autolink

_Available on advanced options panel._ Automatically translate URL to link and parse email addresses.

#### Emoji

Parse the emoji placeholder defined by [GitHub](https://api.github.com/emojis). You can render the emoji with an emoticons glyph or using the image provided by GitHub (internet connection required). 

Multibyte emoji are supported, so `:it:` equivalent to the code `\u1f1ee\u1f1f9` must be rendered as the Italian flag :it:. 

Some emoji do not have an equivalent glyph on the standard font and will be replaced always with the relative image.

A list of GitHub emoji placeholder is available [here](https://github.com/ikatyang/emoji-cheat-sheet/blob/master/README.md#people--body).

#### GitHub mentions

_Available on advanced options panel._ Translate mentions to link to the GitHub account.

#### Heads anchors

_Available on advanced options panel._ Create anchors for the heads to use as cross internal reference. Each anchor is named with the lowercased caption, stripped of any punctuation marks (except the dash) and spaces replaced with dash (`-`). UTF8 character encoding is supported.
 
#### Inline local images 

_Available on advanced options panel._ Inject in the HTML code the local images as base64 data. The Quick Look extension, for security limitations, cannot access to the local images defined inside the Markdown code, so embedding the data it's a way around the limitation. 

For security reasons are handled only URLs without schema (e.g., `./image.jpg`, `image.jpg` or `assets/image.jpg`), or with the `file` schema (e.g.,  `file:///Users/username/Documents/image.jpg`) referring to existing files with an image mime type. 
With the `file://` schema you *must always set the full path*. For images inside the same folder of the Markdown file do not use the  `file://` schema and also `./` is optional.

The extension process both images defined in the Markdown syntax and also with HTML `<image>` tag if the raw HTML code options is enabled.

#### Syntax Highlighting

This extension highlights the source code inside a fenced box.

The rendering engine is based on the [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php). No external program is called, the engine is embedded in a library.

In the advanced options panel you can customize the settings:

- Colors scheme (for light and dark appearance).
- Line numbers visibility.
- Word wrap options.
- Use spaces instead of tabs for indentation.
- Font.
- Guess undefined language.

Some colors scheme (especially those for light appearance) uses a white background that is the same of the Markdown document, making the code block not immediately recognizable. For this reason, it is possible to override the background color in order to use a personal one or the one defined by the Markdown theme. 

Setting a custom font also change the font used in the code blocks enclosed by back-ticks (\`).

When the code block does not specify the language, it is possible to activate a guessing function. Two engines are available:

- Fast guess: it is based on the `magic` library;
- Accurate guess: it is based on the [`Enry`](https://github.com/go-enry/go-enry) library, that is a Golang porting of the Ruby [`linguist`](https://github.com/github/linguist/) library used by GitHub.

If no language is defined and the guessing fail (or is not enabled), the code is rendered as normal text.

#### Strikethrough

Strikethrough text inside tildes. You can choose to detect single or double tilde delimiters.

#### Table

Parse table as defined by the GitHub extension to the standard Markdown language.

#### Tag filter

_Available on advanced options panel._ Strip potentially dangerous HTML tags (`<title>`,   `<textarea>`, `<style>`,  `<xmp>`, `<iframe>`, `<noembed>`, `<noframes>`, `<script>`, `<plaintext>`). It only takes effect if the option to include HTML code is enabled.

#### Task list

_Available on advanced options panel._ Parse task list as defined by the GitHub extension to the standard Markdown language.

#### YAML header
_Available on advanced options panel._ Allow to handle a `yaml` header at the beginning of a file. You can choose to enable the extensions to all `.md` files or only for `.rmd` files.

The header is recognized only if the file start with `---`.

When the `table` extension is enabled, the header is rendered as a table, otherwise as a block of code. Nested tables are supported.

### Themes

You can choose a CSS theme to render the Markdown file. The application is provided with a predefined theme ( GitHub theme ) valid both for light and dark appearance. 

Also, it is possible to use a style to extend the standard theme or to complete override. 
User customized style sheet must have the settings for both light and dark appearance using the CSS media query:

```css
@media (prefers-color-scheme: dark) { 
    /* … */ 
}
``` 

The custom style is appended after the CSS used for the source code. In this way you can customize also the style of the syntax highlight. 

Syntax highlighting extension allow to customize the appearance of the code blocks.


## Command line interface

A `qlmarkdown_cli` command line interface (CLI) is available to perform batch conversion of markdown files.

The tool is located inside the `QLMarkdown.app/Contents/Resources` folder (and should not be moved outside). 

```
Usage: qlmarkdown_cli [-o <file|dir>] <file> [..]

Arguments:
 -h    Show this help and exit.
 -o    <file|dir> Destination output. If you pass a directory, a new file is 
       created with the name of the processed source with html extension. 
       The destination file is always overwritten. 
       If this argument is not provided, the output will be printed to the 
       stdout.
 -v    Verbose mode. Valid only with the -o option.

Options:
 --debug [on|off]
 --footnotes [on|off]
 --hard-break [on|off]
 --no-soft-break [on|off]
 --raw-html [on|off]
 --smart-quotes [on|off]
 --validate-utf8 [on|off]

Extensions:
 --autolink [on|off]
 --emoji [no|image|font]
 --github-mentions [on|off]
 --heads-anchor [on|off]
 --inline-images [on|off]
 --table [on|off]
 --tag-filter [on|off]
 --tasklist [on|off]
 --strikethrough [no|single|double]
 --syntax-highlight [on|off]
 --yaml [no|rmd|all]

Unspecified rendering options will use the settings defined in the main application.

To handle multiple files at time you need to pass the -o arguments with a destination folder.
```

The CLI interface uses the same settings as the Quick Look extension, but you can override it if you wish. 

Any relative paths inside raw HTML fragments are not updated according to the destination folder. 


## Build from source

When you clone this repository, remember to fetch also the submodule with `git submodule update --init`.

### Dependency

The app uses an extra library `highlight wrapper`. This is a custom C++ shared library that expose the `highlight` functionality and the guess detection engines. All the code required by this library is included in the Xcode project, and is compiled as a universal library. 

The wrapper has statically linked the following libraries:
- [`highlight`](http://www.andre-simon.de/doku/highlight/en/highlight.php) for syntax highlighting.
- [`lua`](https://www.lua.org/) required by `highlight`.
- [`magic`](https://www.darwinsys.com/file/), used to guess the source code language when the guess mode is set to _fast_.
- [`Enry`](https://github.com/go-enry/go-enry), used to guess the source code language when the guess mode is set to _accurate_.

Because `Enry` is developed in `go`, to build the wrapper library you must have the `go` compiler installed (you can use `brew install go`). 

## Note about security

To allow the Quick Look view of local images the application and the extension has an entitlement exception to allow *only read access* to the entire system. 

On Big Sur there is a bug in the Quick Look engine and WebKit that cause the immediate crash of any WebView inside a Quick Look preview. To temporary fix this problem this Quick Look extension uses a `com.apple.security.temporary-exception.mach-lookup.global-name` entitlement. 

## Note about the developer

I am not primarily an application developer. There may be possible bugs in the code, be patient.
Also, I am not a native English speaker :sweat_smile:. 

Thanks to [hazarek](https://github.com/hazarek) for the app icon and the CSS style.

**This application was developed for pleasure :heart:.**
