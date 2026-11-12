# Lanzador de Ape Escape 3 (recomp nativo) — diseño

Fecha: 2026-11-12
Estado: propuesto, pendiente de aprobación

## Intención

*Ape Escape 3* (PAL, `SCES_536.42`) ya corre nativo en este PC sobre
`ps2-native-recomp`, pero se arranca escribiendo una línea de comandos con rutas
y argumentos. El objetivo es que se abra como un juego de PC normal: doble clic en
un ejecutable con su nombre y su icono, y a jugar.

## Objetivos

- `ApeEscape3.exe`: subsistema GUI, sin ventana de consola.
- Lee `config.ini` de su propia carpeta: ruta del ISO, carpeta del runtime,
  carpeta del juego y título de ventana.
- Comprueba lo imprescindible antes de arrancar y, si falta algo, lo explica con
  un cuadro de diálogo claro en español en vez de morir en silencio.
- Arranca el runtime en su carpeta (resolución de DLLs) y termina.
- Icono propio, multi-tamaño, incrustado en el ejecutable.
- La carpeta se puede mover de sitio sin romper nada.

## No-objetivos

- **Instalador de primer arranque** (pedir el ISO y compilar). Eso ya existe como
  `Start.cmd` del proyecto; se envolverá más adelante, si acaso.
- **Packs de texturas HD**: es una funcionalidad nueva del renderer, no del
  lanzador.
- **Tocar el runtime**: cero cambios en `ps2-native-recomp`.

## Restricciones

- Solo Windows x86-64.
- Sin dependencias nuevas: Win32 y la biblioteca estándar. Se compila con el
  llvm-mingw portable que ya está en el proyecto.
- El repositorio público **nunca** contiene el juego: ni ISO, ni `runtime/`, ni
  `game/`, ni el `.exe` compilado con el juego dentro.
- El icono es arte propio. No se usa el logo ni la carátula oficial: son de Sony.

## Enfoques considerados

1. **Acceso directo disfrazado.** Copiar `ps2run.exe`, renombrarlo y poner los
   argumentos en un `.lnk` con icono. Cero código, pero se rompe al mover la
   carpeta y no es un ejecutable de verdad. Descartado.
2. **Cambiar el icono de `ps2run.exe`.** Recurso sustituido con `windres`. Es un
   `.exe` real, pero conserva el nombre y sigue necesitando argumentos. Descartado.
3. **Lanzador propio.** Ejecutable pequeño, con icono y configuración, que arranca
   el runtime. **Elegido**: es el único que se comporta como un juego instalado y
   el único publicable sin llevar el juego dentro.

## Decisiones

- **Configuración en `config.ini`**, no en el registro: se puede editar, copiar y
  versionar un ejemplo.
- **El ISO se referencia por ruta absoluta** (`D:\games\...`); no se copian 3,7 GB
  dentro del proyecto. Los demás caminos son relativos a la carpeta del lanzador.
- **Directorio de trabajo = carpeta del runtime**, para que Windows encuentre
  `SDL2.dll`, `dxcompiler.dll` y `dxil.dll`.
- **Los errores se muestran con `MessageBoxW`**, nunca por consola.
- **Se pasa `PS2_WINDOW_TITLE`** para que la barra de título diga el nombre del
  juego en vez de la ruta del ELF.
- El lanzador no espera al juego: arranca y se cierra, para no dejar un proceso
  zombi ni un icono duplicado en la barra de tareas.

## Estructura en disco

```
ApeEscape3\
  ApeEscape3.exe        lanzador (icono incrustado)
  ApeEscape3.ico
  config.ini
  runtime\              ps2run.exe, SDL2.dll, dxcompiler.dll, dxil.dll
  game\                 contenido de games/ape3 (disc, vu1, keys.ini, ...)
```

Publicable en GitHub: `src/`, `resources/`, `build.cmd`, `config.ini.example`,
`README.md`, `docs/`.

## Lo que queda al criterio del que construye

- El dibujo del icono (se presentan opciones y elige el usuario).
- Los textos exactos de los mensajes de error y del README.
- El nombre de la carpeta del proyecto y si se mueve a `D:\Proyectos Programacion`.
