# Ape Escape 3 — lanzador nativo para PC

Un `.exe` propio que arranca **Ape Escape 3** (PS2, versión PAL) recompilado para
Windows x86-64. Doble clic y a jugar: sin emulador, sin menús de configuración de
gráficos, sin BIOS.

El juego no se emula: se traduce el código de la PS2 a código de PC y se ejecuta
directamente sobre la tarjeta gráfica (Direct3D 12 o Vulkan, a través de
wgpu-native). De ahí los 50 fps estables del original PAL.

## Qué necesitas

- Windows 10 u 11 de 64 bits y una tarjeta gráfica con Direct3D 12 (probado en una
  RTX 3080 con los drivers de 2026).
- **Tu propia imagen del disco** de Ape Escape 3 PAL en formato `.iso`.
- El runtime ya compilado (carpeta `runtime`) y los datos del juego (carpeta `game`).

Este repositorio **no incluye** ni el juego, ni la imagen del disco, ni el runtime
compilado. El ejecutable que genera `build.cmd` es solo el lanzador: comprueba que
todo esté en su sitio y arranca el runtime. No se versiona (no hay binarios en
git).

## Instalar en un paso

Doble clic en **`Instalar.cmd`**: te pide tu imagen `.iso` y la carpeta donde
quieres el juego, y hace el resto. Tarda entre 30 y 45 minutos la primera vez y
necesita conexión a internet. Las herramientas quedan en
`%LOCALAPPDATA%\ApeEscape3\cache` y puedes borrarlas cuando quieras.

Los pasos, los parámetros (`-Iso`, `-Destino`, `-Cache`, `-Forzar`) y los
problemas típicos están en [`docs/instalador.md`](docs/instalador.md).

## Jugar

Doble clic en **`Jugar a Ape Escape 3`** (el acceso directo que deja el instalador)
o en `ApeEscape3.exe`. No hay nada más que configurar: el instalador ya escribió el
`config.ini` con la ruta de la imagen que elegiste en el diálogo.

Si falta algo, el lanzador lo dice con un cuadro de diálogo en español y no se
cierra en silencio: te dice exactamente qué ruta no encuentra.

## Hacerlo a mano (solo sin instalador)

Para quien ya tiene `runtime\` y `game\` de antes:

1. Deja `ApeEscape3.exe` en una carpeta, con `runtime\` y `game\` al lado.
2. Copia `config.ini.example` como `config.ini` y pon en `iso=` la ruta de tu imagen:

   ```ini
   iso=D:\games\Ape Escape 3 (Europe) (En,Fr,De,Es,It).iso
   ```

3. Doble clic en `ApeEscape3.exe`.

## El `config.ini`

| Clave        | Por defecto               | Para qué                                        |
| ------------ | ------------------------- | ----------------------------------------------- |
| `iso`        | *(la escribe el instalador)* | Ruta de la imagen del disco                  |
| `runtime`    | `runtime`                 | Carpeta del runtime, relativa al `.exe`         |
| `game`       | `game`                    | Carpeta con los datos del juego                 |
| `elf`        | `disc/SCES_536.42`        | Ejecutable del juego, dentro de `game`          |
| `title`      | `Ape Escape 3`            | Título de la ventana                            |
| `widescreen` | `0`                       | `1` para 16:9, `0` para el 4:3 original          |
| `pal`        | `1`                       | `1` para PAL (50 Hz), `0` para NTSC (60 Hz)      |

Acepta comentarios con `;` o `#` al principio de la línea, claves separadas con `=`
o `:`, y no distingue mayúsculas. Los valores no se cortan por `;`, así que una
ruta con ese carácter funciona. Guarda el archivo en UTF-8 (es lo que hace el
Bloc de notas por defecto): las rutas se leen como UTF-8.

`iso` puede ser una ruta completa o relativa a la carpeta del `.exe`.

`config.ini.example` es la plantilla.

**No hace falta editar este archivo a mano** si instalas con `Instalar.cmd`: lo
escribe él, con la ruta que elegiste en el diálogo. Solo lo tocas si luego mueves el
ISO de sitio, o si quieres cambiar `widescreen` y `pal`.

## Controles

| Tecla                    | Acción                       |
| ------------------------ | ---------------------------- |
| WASD                     | Stick izquierdo              |
| I, J, K, L               | Stick derecho                |
| Espacio / Intro          | Cruz                         |
| E (o botón central)      | Círculo                      |
| Clic izquierdo           | Cuadrado                     |
| Clic derecho             | Triángulo                    |
| Shift                    | L1                           |
| F                        | R1                           |
| Q / R                    | L2 / R2                      |
| X / C                    | L3 / R3                      |
| Esc                      | Start                        |
| Tab                      | Select                       |
| Ctrl (o botón lateral)   | Roll                         |
| V                        | Rage                         |
| F1                       | Menú del runtime             |
| F5 / F8                  | Guardado rápido / cargado rápido |
| F11                      | Pantalla completa            |

Los nombres de estas teclas salen de `game\keys.ini`, que el runtime reescribe
cuando cambias los controles desde su menú.

## Compilar el lanzador

Hace falta un compilador de C++20 para Windows. El proyecto está probado con
[llvm-mingw](https://github.com/mstorsjo/llvm-mingw):

```bat
set LLVM_MINGW=C:\ruta\a\llvm-mingw
build.cmd
```

`build.cmd` compila `ApeEscape3.exe`. `build.cmd test` compila y ejecuta los tests
del parser del `config.ini`, del entrecomillado de argumentos y de las
comprobaciones de rutas.

El icono se genera con `tools\make-icon-net.ps1` (PowerShell + `System.Drawing`,
sin dependencias). Es una red de captura dibujada por código, con paleta propia.

## Estructura

```
src/            lanzador (config, argumentos, validación, arranque)
tests/          tests sin framework, con CHECK propio
resources/      icono y recursos de Windows
tools/          generadores del icono
docs/           diseño y plan de implementación
```

## Aviso legal

Ape Escape es una marca de Sony Interactive Entertainment. Este proyecto no
incluye ni distribuye el juego, sus datos, su imagen de disco ni el runtime
recompilado, y no está afiliado a Sony. Necesitas tu propia copia legal del
juego para usarlo.
