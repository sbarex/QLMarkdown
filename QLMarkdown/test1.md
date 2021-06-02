---
Title: My Title
Author: Sbarex
Date: Sunday, May 30, 2021
Abstract: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
output:
  pdf_document: default
  html_notebook: default
---

The previous block placed at the top of the document and contained between the markers `---` is displayed as the file header when the `YAML` extension is enabled. With the `table` extension on, it is displayed as a table otherwise as a block of code.


# TOC

- [Extensions](#extensions)
  - [Autolink extension](#autolink-extension)
  - [Emoji extension](#emoji-extension)
  - [GitHub mentions extension](#github-mentions-extension)
  - [Heads extension](#heads-extension)
  - [Inline images extension](#inline-images-extension)
  - [Table extension](#table-extension)
  - [Strikethrough extension](#strikethrough-extension)
  - [Syntax Highlight extension](#syntax-highlight-extension)
  - [Task list extension](#task-list-extension)
- [Options](#options)

(The links on the TOC works only if the `heads` extension is enabled).

---

#  Extensions

## Autolink extension

If the `autolink` extension is enabled the URL https://www.github.com is displayed as a link.

## Emoji extension

Using the `emoji` extension you can replace the `:smile:` with :smile:. 

You can choose to use the standard emoji font or the GitHub images.
Multibyte emoji are also supported, so `:it:` equivalent to the code `\u1f1ee\u1f1f9` must be rendered as the Italian flag :it:.

## GitHub mentions extension

With the `mentions` extension @sbarex is rendered as a link to the GitHub account.

## Heads extension

With the `heads` extension for each heads is created an anchor named with the title, lowercased, and space replaced with a hypen sign.
The anchors can be used for cross links. 

If enabled the links inside the [TOC](#toc) section works. 

## Inline images extension

The `inline image` extension embed the local image inside the HTML output. **Is required for view local images in the Quick Look preview.**


image url: `example.jpg`

![Colibrì](example.jpg)


Images with a url do not require this extension.

image url: `https://octodex.github.com/images/minion.png`

![Minion](https://octodex.github.com/images/minion.png)


## Table extension
| Option | Description |
| ------:| :-----------|
| data   | path to data files to supply the data that will be passed into templates. |
| engine | engine to be used for processing templates. Handlebars is the default. |
| ext    | extension to be used for dest files. |


## Strikethrough extension
You can choose to recognize the single tilde \~ on ~test~ or only the double tilde \~\~ on ~~another test~~.

## Syntax Highlight extension

This fenced block uses the php syntax highlight:

```php
phpinfo();
$a = [];
$a[] = "hello world";
function test(array $a, string $b, $c = null): boolean {
    return true;
}
```

You can choose the theme.

## Task list extension
* [x] step 1
* [ ] step 2 
* [ ] step 3


# Options

The `smart quote` option format the quote as "curly" [^footnote1].

---
[^footnote1]: If the option `footnotes` is enabled this text is rendered as a foot note. Footnotes is not recognized in the github pages.

