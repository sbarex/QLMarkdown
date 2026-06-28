# Definition List Test

This file tests definition-list rendering (the `definitionlist` extension): a term
line immediately followed by one or more `: description` lines.

## Basic

Apple
: Pomaceous fruit of plants of the genus *Malus*.

Orange
: A citrus fruit, usually orange in colour.

## Multiple descriptions

Markdown
: A lightweight markup language with plain-text formatting syntax.
: Created by John Gruber in 2004.

## Inline markup

**HTML**
: The standard markup language for web pages — it can contain `code`, *emphasis*, and [links](https://example.com).

## Inside a blockquote

> Quoted term
> : Definition lists also work inside blockquotes.

## Not a definition list

A normal sentence that ends with a colon:
this following line is ordinary text, so the block stays a paragraph.

## Regular Markdown Content

Regular content renders normally alongside definition lists:

- Item 1
- Item 2
- Item 3
