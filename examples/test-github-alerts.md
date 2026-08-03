# GitHub alerts

With the `alert` extension a blockquote whose first line is one of `[!NOTE]`,
`[!TIP]`, `[!IMPORTANT]`, `[!WARNING]` or `[!CAUTION]` is rendered as a colored
callout, like on GitHub.

## The five types

> [!NOTE]
> Useful information that users should know, even when skimming content.

> [!TIP]
> Helpful advice for doing things better or more easily.

> [!IMPORTANT]
> Key information users need to know to achieve their goal.

> [!WARNING]
> Urgent info that needs immediate user attention to avoid problems.

> [!CAUTION]
> Advises about risks or negative outcomes of certain actions.

## The marker is case-insensitive

> [!tip]
> `[!tip]`, `[!Tip]` and `[!TIP]` all produce the same callout.

## Rich content is preserved

> [!IMPORTANT]
> Alerts can span multiple paragraphs and contain inline markup such as
> **bold**, _italic_ and `code`.
>
> - they can hold lists,
> - [links](https://github.com),
> - and other block content.

## Ordinary blockquotes are left untouched

A blockquote without a marker, or whose marker is not alone on the first line,
renders as a normal blockquote:

> Just a regular quote, not an alert.

> [!NOTE] text on the same line as the marker is not an alert either.
