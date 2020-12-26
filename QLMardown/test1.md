#  Extensions

## Autolink extension

If the extension `autolink` is enabled the url https://www.github.com is rendered as a link.

## Emoji extension

Using the emoji extension you can replace the `:smile:` to :smile:. 

You can choose to use the standard emoji font or the Github images.
Multibyte emoji are also supported, so `:it:` equivalent to the code `\u1f1ee\u1f1f9` must be rendered as the Italian flag :it:.

## GitHub mentions extension

With the mentions extension @sbarex is rendered as a link to the GitHub account.

## Inline image extension

The extension embed the local image inside the html output. Is required for the quicklook preview.


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
You can choose to recognize the single tile on ~test~ or only the double tile on ~~another test~~.

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

You can choose the theme and override the background.

## Task list extension
* [x] step 1
* [ ] step 2 
* [ ] step 3


# Options

The `smart quote` option convert format the quote as "curly" [^footnote1].

---
[^footnote1]: If the option `footnotes` is enabled this text is rendered as a foot note. 

