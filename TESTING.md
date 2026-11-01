# Testing local Markdown navigation

Modified on 2026-11-01: the Quick Look extension uses a view-based controller with WKWebView to render linked local documents inside the preview. Back and Forward navigate document history. Relative paths resolve from each displayed document; queries are excluded from file reads, and fragments scroll to heading IDs or named anchors.

## Automated checks

Run in a logged-in macOS desktop session with full Xcode installed:

```sh
tests/run-preview-tests.sh
```

The tests compile the production controller with macOS 12 deployment and extension API restrictions. A temporary native window hosts real WebKit. A small test-only Settings substitute returns HTML fixtures, isolating navigation from the C renderer and external dependencies. The tests cover nested and parent paths, encoded spaces, uppercase extensions, queries, heading fragments, target-blank links, Back/Forward, history branching, missing files, blocked targets, and a narrow host size.

These checks do not validate production cmark rendering or signed Finder extension registration. Perform the Finder checks below as well.

## Build

Initialize submodules and install the prerequisites listed in README. To check compilation without changing signing configuration:

```sh
git submodule update --init --recursive
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project QLMarkdown.xcodeproj -scheme QLMarkdown -configuration Debug \
  -derivedDataPath /tmp/qlmarkdown-build CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES build
```

For Finder testing, build and run the app in Xcode with signing configured for your own team. Keep team, app/extension bundle identifiers, app-group entitlements, and the shared Settings group consistent in your local development configuration. Machine-specific signing changes are not part of this feature.

## Finder checks

1. Run the signed app once. Enable its extension in System Settings → General → Login Items & Extensions → Quick Look. Disable competing Markdown preview extensions during the test.
2. In the settings app, enable Heads anchors or Table of contents and Inline local images, then save settings.
3. Select `examples/navigation/README.md` in Finder and press Space. Confirm Back and Forward initially are disabled.
4. Follow the sibling, subfolder, nested, parent-directory, spaces, and uppercase-extension links. Confirm documents render inside the same panel and the filename beside the controls updates.
5. Use Back and Forward. Go Back and follow a different link; confirm the abandoned Forward history is cleared.
6. Follow the same-page heading and both guide heading links, including the query-string version. Confirm the target heading is brought into view.
7. Click Missing document. Confirm an error appears and the current document and history remain available. Follow a valid link; confirm the error clears.
8. Click the text file and custom-scheme links; confirm no other app opens. Click the external website; confirm it opens in the browser.
9. Check local images, TextBundle content, tables, math, Mermaid, and TOC rendering. Check light/dark appearance, narrow windows, and keyboard activation of the controls.
10. Close the panel and preview a different file; confirm history starts fresh. Finder's title and Open With action refer to the originally selected file; the filename inside the preview identifies the displayed document.

If Finder displays an older build, close the panel, quit the old app, run `qlmanage -r`, and reopen the panel.

## Limits

Local targets require a Markdown extension: `md`, `markdown`, `mdown`, `mkd`, `mkdn`, `mdx`, `mdc`, `rmd`, `qmd`, or `apib`. Extensionless wiki targets, directory indexes, remote Markdown, and other TextBundle packages are not resolved automatically. TextBundle content can link to ordinary Markdown files. Fragments require matching rendered anchors. History re-renders documents without restoring exact scroll offsets.

The feature retains the renderer's Content Security Policy and existing read-only entitlements. Files remain subject to macOS sandbox and privacy permissions. HTTP, HTTPS, and mailto links use the system handler; other external schemes and local non-Markdown targets are ignored.
