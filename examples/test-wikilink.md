# Wikilinks

With the `wikilink` extension a `[[Page Name]]` or `[[Target|Display]]` is rendered as a
styled link (`<a class="wikilink" href="…">…</a>`), matching the syntax used by Obsidian
and similar tools. It is off by default; `default.css` styles the `.wikilink` class.

## Basic

- A simple link: [[Page Name]]
- An aliased link: [[Target|Display]]
- Surrounding spaces are trimmed: [[  Spaced Out  ]]
- Paths keep their slashes: [[Folder/Sub/Note]]
- Two on one line: [[First]] and [[Second]].
- No boundary needed: pre[[Inline]]post.
- Special characters are escaped: [[Café & Bar]]

## In other blocks

Wikilinks work anywhere text does — in headings, lists, tables, and quotes.

### A heading with a [[Linked Page]]

| Column | Wikilink |
|--------|----------|
| row    | [[Cell Link]] |

> A quote linking to [[Some Note]].

## Edge cases

| Input | Expected |
|-------|----------|
| `[[]]` | left literal (empty) |
| `[[   ]]` | left literal (whitespace only) |
| `[[A\|]]` | link to `A`, shown as `A` (empty display falls back) |
| `[[\|D]]` | left literal (empty target) |
| `[[A\|B\|C]]` | link to `A`, shown as `B\|C` (split on first `\|`) |
| `[[A]` | left literal (no closing) |
| `[[a]b]]` | left literal (stray bracket inside) |

Rendered: [[]] · [[   ]] · [[A|]] · [[|D]] · [[A|B|C]] · [[A] · [[a]b]]

## Not converted

Inside a code span it stays literal: `[[Not A Link]]`.

Markdown inside the brackets prevents recognition: [[**Bold**]].

Existing Markdown links are left alone: [a real link](https://example.com).
