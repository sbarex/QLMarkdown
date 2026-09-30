# Hashtags

With the `hashtag` extension a `#tag` or a nested `#area/topic` is rendered as a styled tag
(`<span class="hashtag">#tag</span>`), matching the tag syntax of Obsidian and similar tools.
It is off by default; `default.css` styles the `.hashtag` class.

## Tags

- A simple tag: #todo
- A nested tag: #reading/books
- Underscores and hyphens: #reading_list #follow-up
- Other scripts: #café #日本語
- Two on one line: #one and #two.
- At the start of a line:

#standalone tag at the start of a paragraph.

## In other blocks

### A heading with a #tag

| Column | Tag |
|--------|-----|
| row    | #cell |

> A quote with a #quoted tag.

## Not tags

- Issue numbers: #123 and #2026
- Inside a word: C# and a#b
- A URL fragment: https://example.com/page#section
- Inline code: `#not-a-tag`
- A lone hash: # and #!
