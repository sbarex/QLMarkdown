# Admonition Test

This file tests admonition rendering (the `admonition` extension): a `!!! type [title]`
line immediately followed by its indented content is rendered as a callout box.

## Types

!!! note
    Useful information that users should know, even when skimming.

!!! tip
    A helpful suggestion for doing things better or more easily.

!!! warning
    Something the reader should be careful about.

!!! caution
    Negative consequences of an action.

## Custom title

!!! tip "Pro tip"
    A quoted title replaces the default. The body supports *emphasis*, `code`, and [links](https://example.com).

## Type synonyms

!!! danger
    Unknown and synonym types map onto the five styles — `danger` uses the caution style.

## Inside a blockquote

> !!! warning
>     Admonitions also work inside blockquotes.

## Not an admonition

!!!note
    Without a space after `!!!` this is not an admonition, so it stays a normal paragraph.

## Regular Markdown Content

Regular content renders normally alongside admonitions:

- Item 1
- Item 2
- Item 3
