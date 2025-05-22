#  TODO

- [ ] Bugfix: footnote option and super/sub script extension are incompatible.
- [ ] Bugfix: on dark style, there is a flashing white rectangle before show the preview on Monterey.
- [ ] Investigate if export syntax highlighting colors scheme style as CSS var overriding the default style
- [ ] Check inline images on network / mounted disk
- [ ] Localization support
- [x] Check code signature and app group access (bypassed using an XPC process)
- [x] Syntax highlighting color scheme editor
- [x] Optimize the inline image extension for raw html code: process and embed the data only for fragments and not processing all the formatted html code.
- [x] Embed inline image for `<img>` raw tag without using javascript/callbacks.
- [x] Emoji extension: better code that parse the single placeholder and generate nodes inside the AST (this would avoid the CMARK_OPT_UNSAFE option for emojis as images)
- [x] Investigate CMARK_OPT_UNSAFE for inline images
- [x] Application screenshot in the docs
- [x] Extension to generate anchor link for heads
- [x] Sparkle update engine
- [x] Insert the `highlight` library on the build process
- [x] @rpath libwrapper
