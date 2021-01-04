# Changelog
=======

### 1.0b15
New features:
- Option to export the generated preview to an html file in the main application.

Bugfix:
- fix emoji parser.

### 1.0b14
New features:
- Better emoji handler.
- UI improvement. Some less used commands on the theme dropdown popup are available pressing the alt key.

### 1.0b13
New features:
- QL preview handle TextBundle container.
- Inline image extension handle also image inserted with <image> tag on the markdown file.
- Better emoji handler.

Bugfix:
- Fix error on image mime detection.

### 1.0b12
1.0b12
New features:
- New icon (thanks to [hazarek](https://github.com/hazarek)). 
- Wrapper highlight library build inside the Xcode project.
- Wrapper highlight embed goutils with enry guess engine.
- Better about dialog.

Bugfix:
- Shared library and support files no more embedded twice reducing the total file size.
- Fix on exporting default style.
- Css theme fix.

### 1.0b11
Bugfix:
- Fixed open external link to the default browser on Big Sur (via an external XPC service).

### 1.0b10
New features:
- Implemented reset to factory settings.

Bugfix:
- Incomplete saving settings.
- UI fix.

### 1.0.b9
New features:
- Updated the default CSS style (thanks to [hazarek](https://github.com/hazarek)). 
- For Syntax highlighting, option to choose the document style or a specific language style.

### 1.0.b8
Bugfix:
- Fixed standard cmark tasklist extension not inserting class style in html output.

### 1.0.b7
New features:
- `Heads extension` to auto create anchor for the heads.
- Redesigned UI. 
- Auto refresh menu to automatically update the preview when an option is changed (the auto refresh do not apply when you change the example text). 
- The quicklook extension detects the settings changed on the host application. Remember that macOS can store the quicklook preview in a cache, so to see the new settings applied try to open the preview of a different file.
- On the host application you can open a .md file to view in the preview (you can also drag & drop the over the text editor).
- Import CSS inside the support folder.

Bugfix:
- Typo in application name.
- Null pointer bug on inlineimage extension.
- Fix on the image mime detection.

### 1.0.b6
New Features:
- better ui.
Bug fix:
- Fix for bug on colors scheme icon with underline style.
- Fix missing close menu item.
- Fix bug with "base16" syntax highlighting colors scheme.

### 1.0.b5
New features:
- Experimental option to choose to open links inside the quicklook preview window or in the default browser (but on Big Sur do not works).
Bugfix:
- Fix missing sparkle framework.

### 1.0.b4
New features:
- Auto update with Sparkle framework. Auto updated works only when run the main application and not from the quicklook extension. You must have launched the application at least twice for the update checks to begin, or you can use the appropriate item in the application menu.
- Save button enabled only when there are some changed settings. in case of error a warning panel will be shown.
- Debug options.

Bug fix:
- fix missing WKWebView class on Catalina

### 1.0.b3
Bugfix:
- Save menu item fixed.
- libmagic linked statically.

### 1.0.b2
New features:
- Reimplemented in c/c++ previous code developed on the external golang library (emoji, base64 encoding).
- Syntax Highlighting extension now use [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) linked as a library, and with more customizable options.
- GUI updated to use the changed extensions.
- Many others changes.

### 1.0.b1
First release.
