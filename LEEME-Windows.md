# QLMarkdown: Guía de Compilación e Instalación para Windows

La aplicación gráfica, la extensión Quick Look de macOS y la extensión de Shortcuts están diseñadas exclusivamente para macOS mediante AppKit, Cocoa y frameworks específicos de Apple.

Sin embargo, **todo el motor central de análisis, renderizado y extensiones Markdown** está programado en bibliotecas portables de C y C++ (`cmark-gfm`, extensiones personalizadas `cmark-extra` e `highlight`).

Para dar soporte completo a los usuarios de Windows, hemos portado la CLI original escrita en Swift a una herramienta de línea de comandos nativa y multiplataforma en C++ (**`qlmarkdown_cli`**). Esta herramienta replica exactamente las mismas opciones, comportamiento y generación de HTML adaptado que la CLI original.

---

## ⚠️ PASO CRÍTICO OBLIGATORIO: Inicializar Submódulos
Si has clonado este repositorio sin submódulos, la carpeta `cmark-gfm` estará completamente vacía y la compilación fallará.

Antes de configurar o compilar el proyecto, abre tu terminal (Git Bash, Símbolo del Sistema o PowerShell) en la carpeta raíz del proyecto y ejecuta:

```cmd
git submodule update --init --recursive
```

---

## Prerrequisitos

Para compilar y ejecutar el programa en Windows necesitas:

### 1. Git y CMake
Puedes instalarlos fácilmente usando **winget** (integrado por defecto en Windows 10 y 11) ejecutando esto en el Símbolo del Sistema / PowerShell:
```cmd
winget install Kitware.CMake
winget install Git.Git
```
*O descargándolos manualmente:*
- [Descargar CMake](https://cmake.org/download/)
- [Descargar Git](https://git-scm.com/download/win)

### 2. Un compilador compatible con C++17
La manera más rápida y recomendada es instalar **Visual Studio 2022 Community** (que es totalmente gratuito):
- [Descargar Visual Studio 2022 Community](https://visualstudio.microsoft.com/es/downloads/)
- Durante la instalación, asegúrate de marcar la casilla **"Desarrollo para el escritorio con C++"** (Desktop development with C++). Esto instalará el compilador MSVC, el SDK de Windows y MSBuild.

---

## Instrucciones de Compilación paso a paso

### Opción A: Compilación desde la línea de comandos (Recomendado)

1. Abre **Developer PowerShell for VS 2022** o **Developer Command Prompt for VS 2022** desde el menú Inicio de Windows. Esto asegura que todas las rutas del compilador estén cargadas en tu entorno.
2. Navega hasta la carpeta del repositorio clonado, inicializa los submódulos y compila:

```cmd
# 1. Inicializar submódulos (PASO CRÍTICO)
git submodule update --init --recursive

# 2. Crear y entrar a la carpeta de compilación
mkdir build
cd build

# 3. Configurar el proyecto con CMake
cmake ..

# 4. Compilar el ejecutable en modo Release (optimizado)
cmake --build . --config Release
```

Una vez finalizada la compilación, encontrarás el archivo ejecutable **`qlmarkdown_cli.exe`** dentro del directorio `build\Release`.

---

### Opción B: Compilación mediante la interfaz gráfica de Visual Studio

1. Abre tu terminal de Windows en la carpeta raíz del repositorio y ejecuta: `git submodule update --init --recursive`
2. Abre **Visual Studio 2022**.
3. Selecciona **"Abrir una carpeta local"** (Open a local folder) y elige la carpeta raíz de este repositorio (donde está ubicado `CMakeLists.txt`).
4. Visual Studio detectará automáticamente el archivo `CMakeLists.txt` y configurará el proyecto de manera automática.
5. En la barra de menús superior, cambia el desplegable de configuración de compilación de **`x64-Debug`** a **`x64-Release`** (o `x86-Release` / `ARM64-Release` según tu sistema).
6. Ve al menú superior y selecciona **Compilar > Compilar todo** (Build > Build All).
7. Al terminar, el ejecutable compilado `qlmarkdown_cli.exe` estará ubicado en la carpeta `out/build/x64-Release` (o similar).

---

## Guía de Uso

Puedes ejecutar la CLI directamente en tu terminal de Windows.

### Renderizar un archivo Markdown y mostrar el HTML en la consola:
```cmd
qlmarkdown_cli.exe archivo.md
```

### Guardar el HTML resultante en un archivo de salida:
```cmd
qlmarkdown_cli.exe -o resultado.html archivo.md
```

### Renderizar forzando el modo oscuro o modo claro:
```cmd
qlmarkdown_cli.exe --appearance dark -o documento.html archivo.md
```

---

## Opciones y Extensiones Soportadas

Hemos portado todas las banderas y configuraciones de renderizado de la versión macOS:

| Opción / Extensión | Parámetro | Descripción |
|---|---|---|
| `-o <ruta>` | Ruta | Ruta del archivo HTML o carpeta de destino |
| `-v, --verbose` | Ninguno | Muestra logs informativos durante el proceso |
| `--appearance` | `auto`, `light`, `dark` | Apariencia visual del documento HTML |
| `--base-font-size` | `número` | Tamaño base de la fuente en puntos |
| `--footnotes` | `on`/`off` | Soporte para notas al pie de página |
| `--hard-break` | `on`/`off` | Convierte saltos de línea suaves en saltos de línea físicos |
| `--no-soft-break` | `on`/`off` | Elimina saltos de línea suaves |
| `--raw-html` | `on`/`off` | Permite HTML crudo insertado en el Markdown |
| `--smart-quotes` | `on`/`off` | Convierte comillas simples/dobles rectas en tipográficas |
| `--table` | `on`/`off` | Soporte para tablas estilo GitHub |
| `--tasklist` | `on`/`off` | Listas de tareas interactivos |
| `--strikethrough` | `single`/`double`/`off` | Estilo de tachado (`~` o `~~`) |
| `--autolink` | `on`/`off` | Detección automática de enlaces y correos |
| `--emoji` | `font`/`images`/`off` | Renderiza emojis mediante fuentes del sistema o imágenes web |
| `--inline-images` | `on`/`off` | Codifica imágenes locales en Base64 directamente en el HTML |
