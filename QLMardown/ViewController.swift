//
//  ViewController.swift
//  QLMardown
//
//  Created by sbarex on 09/12/20.
//

import Cocoa
import WebKit
class ViewController: NSViewController {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("libcmark version \(String(cString: cmark_version_string())) (\(cmark_version()))")
        
        let markdown_string = """
~*Hello World*~

```php
phpinfo();
$a = "ciao";
```

---
__Advertisement :)__

- __[pica](https://nodeca.github.io/pica/demo/)__ - high quality and fast image
  resize in browser.
- __[babelfish](https://github.com/nodeca/babelfish/)__ - developer friendly
  i18n with plurals support and easy syntax.

You will like those projects!

---

# h1 Heading 8-)
## h2 Heading
### h3 Heading
#### h4 Heading
##### h5 Heading
###### h6 Heading


## Horizontal Rules

___

---

***


## Typographic replacements

Enable typographer option to see result.

(c) (C) (r) (R) (tm) (TM) (p) (P) +-

test.. test... test..... test?..... test!....

!!!!!! ???? ,,  -- ---

"Smartypants, double quotes" and 'single quotes'


## Emphasis

**This is bold text**

__This is bold text__

*This is italic text*

_This is italic text_

~~Strikethrough~~


## Blockquotes


> Blockquotes can also be nested...
>> ...by using additional greater-than signs right next to each other...
> > > ...or with spaces between arrows.


## Lists

Unordered

+ Create a list by starting a line with `+`, `-`, or `*`
+ Sub-lists are made by indenting 2 spaces:
  - Marker character change forces new list start:
    * Ac tristique libero volutpat at
    + Facilisis in pretium nisl aliquet
    - Nulla volutpat aliquam velit
+ Very easy!

Ordered

1. Lorem ipsum dolor sit amet
2. Consectetur adipiscing elit
3. Integer molestie lorem at massa


1. You can use sequential numbers...
1. ...or keep all the numbers as `1.`

Start numbering with offset:

57. foo
1. bar


## Code

Inline `code`

Indented code

    // Some comments
    line 1 of code
    line 2 of code
    line 3 of code


Block code "fences"

```
Sample text here...
```

Syntax highlighting

``` js
var foo = function (bar) {
  return bar++;
};

console.log(foo(5));
```

## Tables

| Option | Description |
| ------ | ----------- |
| data   | path to data files to supply the data that will be passed into templates. |
| engine | engine to be used for processing templates. Handlebars is the default. |
| ext    | extension to be used for dest files. |

Right aligned columns

| Option | Description |
| ------:| -----------:|
| data   | path to data files to supply the data that will be passed into templates. |
| engine | engine to be used for processing templates. Handlebars is the default. |
| ext    | extension to be used for dest files. |


## Links

[link text](http://dev.nodeca.com)

[link with title](http://nodeca.github.io/pica/demo/ "title text!")

Autoconverted link https://github.com/nodeca/pica (enable linkify to see)


## Images

![Minion](https://octodex.github.com/images/minion.png)
![Stormtroopocat](https://octodex.github.com/images/stormtroopocat.jpg "The Stormtroopocat")

Like links, Images also have a footnote style syntax

![Alt text][id]

With a reference later in the document defining the URL location:

[id]: https://octodex.github.com/images/dojocat.jpg  "The Dojocat"


## Plugins

The killer feature of `markdown-it` is very effective support of
[syntax plugins](https://www.npmjs.org/browse/keyword/markdown-it-plugin).


### [Emojies](https://github.com/markdown-it/markdown-it-emoji)

> Classic markup: :wink: :crush: :cry: :tear: :laughing: :yum:
>
> Shortcuts (emoticons): :-) :-( 8-) ;)

see [how to change output](https://github.com/markdown-it/markdown-it-emoji#change-output) with twemoji.


### [Subscript](https://github.com/markdown-it/markdown-it-sub) / [Superscript](https://github.com/markdown-it/markdown-it-sup)

- 19^th^
- H~2~O


### [\\<ins>](https://github.com/markdown-it/markdown-it-ins)

++Inserted text++


### [\\<mark>](https://github.com/markdown-it/markdown-it-mark)

==Marked text==


### [Footnotes](https://github.com/markdown-it/markdown-it-footnote)

Footnote 1 link[^first].

Footnote 2 link[^second].

Inline footnote^[Text of inline footnote] definition.

Duplicated footnote reference[^second].

[^first]: Footnote **can have markup**

    and multiple paragraphs.

[^second]: Footnote text.


### [Definition lists](https://github.com/markdown-it/markdown-it-deflist)

Term 1

:   Definition 1
with lazy continuation.

Term 2 with *inline markup*

:   Definition 2

        { some code, part of Definition 2 }

    Third paragraph of definition 2.

_Compact style:_

Term 1
  ~ Definition 1

Term 2
  ~ Definition 2a
  ~ Definition 2b


### [Abbreviations](https://github.com/markdown-it/markdown-it-abbr)

This is HTML abbreviation example.

It converts "HTML", but keep intact partial entries like "xxxHTMLyyy" and so on.

*[HTML]: Hyper Text Markup Language

### [Custom containers](https://github.com/markdown-it/markdown-it-container)

::: warning
*here be dragons*
:::

"""
        
        
        cmark_gfm_core_extensions_ensure_registered()
        
        let options = CMARK_OPT_DEFAULT
        
        // Modified version of cmark_parse_document in blocks.c
        guard let parser = cmark_parser_new(options) else {
            return
        }
        defer {
            cmark_parser_free(parser)
        }
        if let ext = cmark_find_syntax_extension("table") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if let ext = cmark_find_syntax_extension("autolink") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if let ext = cmark_find_syntax_extension("tagfilter") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if let ext = cmark_find_syntax_extension("tasklist") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if let ext = cmark_find_syntax_extension("strikethrough") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        
        if let ext = cmark_find_syntax_extension("mention") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if let ext = cmark_find_syntax_extension("checkbox") {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        
        cmark_parser_feed(parser, markdown_string, strlen(markdown_string))
        guard let doc = cmark_parser_finish(parser) else {
            return
        }
        defer {
            cmark_node_free(doc)
        }
        // Render
        let html2 = cmark_render_html(doc, options, nil)
        defer {
            free(html2)
        }
        
        
        
        let html = String(cString: html2!)
        let css1: String
        if let p = Bundle.main.path(forResource: "markdown", ofType: "css"), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            css1 = s
        } else {
            css1 = ""
        }
        let css2: String
        if let p = Bundle.main.path(forResource: "syntax", ofType: "css"), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            css2 = s
        } else {
            css2 = ""
        }
            
        webView.loadHTMLString(
"""
<!doctype html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0'>
    <style type='text/css'>\(css1)\(css2)</style>
</head>
<body class="markdown-body">\(html)</body>
</html>
""", baseURL: nil)
        // Do any additional setup after loading the view.
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

