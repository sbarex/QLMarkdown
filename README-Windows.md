# QLMarkdown Windows & Cross-Platform Port

The graphical application, macOS Quick Look extension, and macOS Shortcuts extension of QLMarkdown are built specifically for macOS using AppKit, Cocoa, and system-specific frameworks.

However, the **entire core Markdown parsing, rendering, and extension logic** is powered by robust C and C++ libraries (`cmark-gfm`, custom `cmark-extra` extensions, and `highlight`).

To support Windows users, this repository features a native, cross-platform C++ Command Line Interface (**`qlmarkdown_cli`**) that replicates the exact same markdown configuration and HTML rendering capabilities as the original Swift-based macOS CLI.

---

## ⚠️ CRITICAL FIRST STEP: Submodule Initialization
If you cloned this repository without submodules, the `cmark-gfm` directory will be empty and the build will fail.

Before configuring the build, open your terminal (Git Bash, Command Prompt, or PowerShell) and run:

```cmd
git submodule update --init --recursive
```

---

## Prerequisites (Prerrequisitos)

To build and compile the program on Windows, you will need:

### 1. Git & CMake
You can install them using **winget** (built into Windows 10 & 11) by running this in Command Prompt/PowerShell:
```cmd
winget install Kitware.CMake
winget install Git.Git
```
*Or download them manually:*
- [CMake Download](https://cmake.org/download/)
- [Git Download](https://git-scm.com/download/win)

### 2. A C++17 Compliant Compiler
The easiest way is to install **Visual Studio 2022 Community** (which is completely free):
- [Download Visual Studio 2022 Community](https://visualstudio.microsoft.com/downloads/)
- During installation, make sure to check the box for **"Desktop development with C++"** (Desarrollo para el escritorio con C++). This installs the MSVC compiler, Windows SDK, and MSBuild.

---

## Build and Compilation Instructions (Instrucciones de Compilación)

### Option A: Building from the Command Line (Recommended)

1. Open **Developer PowerShell for VS 2022** or **Developer Command Prompt for VS 2022** (search for it in your Windows Start Menu). This ensures all compiler paths are correctly loaded.
2. Navigate to your cloned repository folder, initialize the submodules, and compile:

```cmd
# 1. Initialize submodules (CRITICAL)
git submodule update --init --recursive

# 2. Create and enter build folder
mkdir build
cd build

# 3. Configure the build files
cmake ..

# 4. Compile the Release executable
cmake --build . --config Release
```

Once compilation completes, the executable **`qlmarkdown_cli.exe`** will be generated inside the `build\Release` directory.

---

### Option B: Building via Visual Studio GUI

1. Open your terminal at the repository root and run: `git submodule update --init --recursive`
2. Open **Visual Studio 2022**.
3. Choose **"Open a local folder"** and select the root directory of this repository (where `CMakeLists.txt` is located).
4. Visual Studio will automatically detect the `CMakeLists.txt` file and configure the project.
5. In the top menu bar, change the build configuration dropdown from **`x64-Debug`** to **`x64-Release`** (or `x86-Release` / `ARM64-Release` as preferred).
6. Go to the top menu and select **Build > Build All** (Compilar > Compilar todo).
7. Once finished, the compiled executable `qlmarkdown_cli.exe` will be located under the `out/build/x64-Release` (or similar) folder.

---

## Usage Guide

You can run `qlmarkdown_cli` directly from your terminal.

### Render a file and print HTML to stdout:
```cmd
qlmarkdown_cli.exe my_markdown_file.md
```

### Render a file and save the output as an HTML file:
```cmd
qlmarkdown_cli.exe -o output.html my_markdown_file.md
```

### Render with a specific appearance (light or dark mode):
```cmd
qlmarkdown_cli.exe --appearance dark -o doc.html doc.md
```

---

## Available Options and Extensions

All standard options from the macOS CLI have been ported:

| Option / Extension | Argument | Description |
|---|---|---|
| `-o <path>` | Path | Destination HTML path or folder |
| `-v, --verbose` | None | Verbose log output |
| `--appearance` | `auto`, `light`, `dark` | Preview theme appearance |
| `--base-font-size` | `number` | Custom font size in points |
| `--footnotes` | `on`/`off` | Enable footnotes parsing |
| `--hard-break` | `on`/`off` | Softbreaks become line breaks |
| `--no-soft-break` | `on`/`off` | Softbreaks become spaces |
| `--raw-html` | `on`/`off` | Allow inline raw HTML (unsafe) |
| `--smart-quotes` | `on`/`off` | Convert straight quotes to curly |
| `--table` | `on`/`off` | GFM tables extension |
| `--tasklist` | `on`/`off` | Checklist support |
| `--strikethrough` | `single`/`double`/`off` | Strikethrough parsing style |
| `--autolink` | `on`/`off` | Automatic links detection |
| `--emoji` | `font`/`images`/`off` | Render emojis as glyphs or images |
| `--inline-images` | `on`/`off` | Base64-encode local image assets |
