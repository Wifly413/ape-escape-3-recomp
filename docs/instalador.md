# El instalador

`Instalar.cmd` y `install\instalar.ps1` construyen el juego en tu PC a partir de tu
propia imagen del disco y dejan una carpeta lista para jugar. No hay instalador
gráfico aparte ni nada que registrar en el sistema: todo ocurre dentro de dos
carpetas, la de las herramientas y la del juego.

## Cómo se arranca

- Doble clic en `Instalar.cmd`: pide la imagen y la carpeta con dos diálogos.
- Sin diálogos, desde una consola:

  ```bat
  Instalar.cmd -Iso "D:\juego.iso" -Destino "C:\Juegos\Ape Escape 3"
  ```

  O llamando al script directamente:

  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File install\instalar.ps1 -Iso <iso> -Destino <carpeta> -Cache <carpeta> -Forzar
  ```

| Parámetro  | Para qué                                                                  |
| ---------- | ------------------------------------------------------------------------- |
| `-Iso`     | Imagen del disco (`.iso` o `.bin`). Si falta, se pide en un diálogo |
| `-Destino` | Carpeta donde instalar. Se crea si no existe. Si falta, se pide en un diálogo |
| `-Cache`   | Dónde se guardan las herramientas. Por defecto `%LOCALAPPDATA%\ApeEscape3\cache` |
| `-Forzar`  | Construye el juego otra vez aunque ya esté construido con esa misma imagen |

Hace falta Windows de 64 bits con el PowerShell 5.1 que ya viene de serie, conexión
a internet (las herramientas se descargan) y permisos de administrador **no** (por eso
el destino no puede estar dentro de `C:\Program Files` ni de `C:\Windows`).

## Qué hace, paso a paso

El instalador imprime seis pasos numerados, `1/6` a `6/6`.

1. **La imagen del disco.** Comprueba que el archivo exista, que acabe en `.iso` o
   `.bin`, que se pueda leer y que ronde el tamaño de un disco de PS2 (rechaza lo que
   ocupe menos de 100 MB). Un `.cue` no vale: es solo una lista de pistas, y el
   instalador te pide el `.bin` al que apunta.
2. **Dónde instalarlo.** Comprueba que la ruta no sea un archivo, que no esté dentro
   de una carpeta protegida de Windows, que se pueda escribir en ella y que queden al
   menos 512 MB libres. Después mira si la unidad de la caché tiene los 3072 MB que
   necesitan las herramientas.
3. **Las herramientas de compilación** (solo la primera vez). Descarga el proyecto
   `ps2-native-recomp` y su toolchain portable dentro de la caché. Si ya estaban,
   no se descargan otra vez.
4. **Construir el juego** (30-45 minutos; no cierres la ventana). Traduce el código de
   la PS2 a código de PC a partir de tu imagen, con los scripts del propio proyecto
   (`setup.sh` y `port.sh`) y el `bash` del toolchain. Si el juego ya estaba
   construido con esa misma imagen, se salta este paso.
5. **Copiar el juego a la carpeta destino.** Deja `runtime\` (el `ps2run.exe` con
   `SDL2.dll` y las DLL de DirectX), `game\` (los datos del juego), `ApeEscape3.exe`
   y un `config.ini` escrito a partir de `config.ini.example` con la ruta de tu
   imagen ya puesta.
6. **El acceso directo.** Crea `Jugar a Ape Escape 3.lnk` en la carpeta destino,
   apuntando al `.exe` y con esa misma carpeta como directorio de trabajo. Si Windows
   no le deja crearlo, lo dice y te manda a `ApeEscape3.exe`.

Al terminar resume cuánto ha tardado y cuánto ocupan las herramientas.

## Qué descarga y cuánto ocupa

| Cosa                                        | Cuándo                    | Tamaño                          |
| ------------------------------------------- | ------------------------- | ------------------------------- |
| El proyecto `ps2-native-recomp` (un zip)     | La primera vez            | unos 2 MB                       |
| El toolchain portable de ese proyecto       | La primera vez            | 312 MB de descarga, 975 MB ya descomprimido |
| La compilación del juego                    | Siempre que no esté hecha | unos 260 MB en la caché         |
| Los datos del juego que se copian           | Tras compilar             | unos 6 MB                       |

Todo eso vive en la caché, y el instalador pide **3072 MB libres** en esa unidad
antes de empezar (las cifras de arriba con margen). En la carpeta destino pide
**512 MB**: el runtime ocupa unos 102 MB (`ps2run.exe` son 77 y `dxcompiler.dll` 22) y
los datos del juego unos 6 MB. La instalación entera son unos 110 MB.

Nada de esto viene con el instalador: se descarga o se construye en tu PC.

## La caché

Por defecto está en `%LOCALAPPDATA%\ApeEscape3\cache` (en un Windows normal,
`C:\Users\<tu usuario>\AppData\Local\ApeEscape3\cache`). Se puede cambiar con
`-Cache`. Dentro quedan:

- `ps2-native-recomp\`: el proyecto descargado, con las herramientas en
  `tools\portable\`, el código generado y la compilación.
- `instalar.log`: el registro con hora de lo que ha ido haciendo el instalador. Si
  algo falla, la última línea de la ventana te dice dónde está este archivo.
- La salida de la exploración de la compilación, en
  `ps2-native-recomp\games\ape3\explore.log`.

**Se puede borrar entera cuando quieras**, con el instalador cerrado:

```powershell
Remove-Item -LiteralPath "$env:LOCALAPPDATA\ApeEscape3\cache" -Recurse -Force
```

No rompe nada de lo ya instalado: el juego que copió a tu carpeta destino sigue ahí.
La siguiente vez que ejecutes el instalador se lo vuelve a descargar y a construir.

## Qué NO se distribuye

- **El juego.** Ni la imagen del disco, ni los datos ya construidos. Usas tu propia
  copia de Ape Escape 3 PAL.
- **El runtime compilado.** El `ps2run.exe` se genera en tu PC a partir de tu imagen
  y se queda en tu PC.

Por eso el zip que se publica no lleva binarios del juego: solo el lanzador y el
instalador.

## Qué contiene el zip publicable

```
ApeEscape3.exe        el lanzador (se copia a la carpeta destino)
Instalar.cmd          el instalador, doble clic
install\instalar.ps1  lo que hace el trabajo
config.ini.example    la plantilla del config.ini
```

Los cuatro tienen que ir juntos: si falta `install\instalar.ps1`, `Instalar.cmd` lo
dice y no hace nada; y si faltan `ApeEscape3.exe` o `config.ini.example`, el
instalador se para en el paso 5 pidiendo que descomprimas el zip entero.

## Reinstalar o forzar la reconstrucción

- **Reinstalar** es volver a ejecutar `Instalar.cmd` con la misma imagen: no se
  descarga nada de lo que ya estaba en la caché y, si el juego ya estaba construido
  con esa imagen, tampoco se recompila. Se vuelven a copiar el runtime, los datos, el
  `config.ini` y el acceso directo.
- **Forzar la reconstrucción** es `Instalar.cmd -Forzar ...`: ignora la comprobación
  anterior y repite el paso 4 aunque el `ps2run.exe` ya exista. Es lo que hay que
  hacer si has cambiado opciones de compilación o sospechas que la construcción quedó
  a medias.
- Si cambias de imagen del disco, basta con volver a ejecutar el instalador con la
  nueva ruta: reescribe el `config.ini` y recompila solo si esa imagen es más nueva
  que el `ps2run.exe` que ya hay.

## Problemas típicos

**No hay espacio.** El instalador lo dice antes de empezar y con números: cuántos MB
libres hay y cuántos hacen falta. Si el problema es la caché, muévela a otra unidad
con `-Cache "E:\cache-ape"`; si es el destino, elige otra carpeta.

**El antivirus.** Si bloquea tu imagen, el instalador avisa de que no puede leer ese
archivo (puede estar abierto en otro programa o faltarte permiso) y no sigue. Si pone
en cuarentena algo de la compilación, el paso 5 se para diciendo qué pieza falta y en
qué carpeta; con el antivirus en pausa y volviendo a ejecutar el instalador se
arregla, y lo que ya estaba hecho no se repite.

**La imagen se ha movido después de instalar.** El `config.ini` de la carpeta
destino guarda la ruta completa de la imagen que elegiste. Si la mueves o la renombras,
el lanzador se da cuenta al arrancar y abre el mismo diálogo para que elijas la imagen
otra vez; al elegirla guarda la ruta nueva en el `config.ini` y arranca. No hay que
editar nada ni volver a ejecutar el instalador. Si cancelas el diálogo, verás el aviso
en español con la ruta que falta y podrás reintentarlo con otro doble clic.

**Cancelar sin romper nada.** Cerrar la ventana o pulsar Ctrl+C no deja nada que
estorbe: al volver a ejecutarlo, lo que ya estaba descargado no se descarga otra vez y
el paso 4 se repite entero (`setup.sh` reutiliza lo que ya había; `port.sh` vuelve a
traducir). La carpeta destino se reescribe en el paso 5, y la caché siempre se puede
borrar.

**Instalar dos veces en la misma carpeta** no duplica nada: cada pieza se reemplaza.

## Tests del instalador

`tests\instalar.tests.ps1` comprueba las funciones del instalador sin instalar nada:
hace dot-source de `install\instalar.ps1`, las llama sobre una carpeta temporal y la
borra al terminar.

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File tests\instalar.tests.ps1
```

Termina con una línea `instalar: N checks, 0 failures` y código 0, o con código 1 si
algo falla.
