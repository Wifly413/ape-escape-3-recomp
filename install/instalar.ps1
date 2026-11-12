# Instalador de Ape Escape 3 para PC: pide la imagen del disco, pregunta donde
# instalar y deja la carpeta lista para jugar, en un solo paso.
#
#   Instalar.cmd                                                  doble clic (dialogos)
#   powershell -File install\instalar.ps1 -Iso <iso> -Destino <carpeta>   sin dialogos
#
# Que hace, en orden:
#   1. Descarga el proyecto ps2-native-recomp (zip de GitHub, sin git) en una cache.
#   2. Descarga el toolchain portable de ese proyecto y compila el runtime a partir de
#      TU imagen del disco, con sus propios scripts (setup.sh + port.sh).
#   3. Copia el lanzador, el runtime y los datos a la carpeta destino, escribe
#      config.ini y crea el acceso directo.
#
# El juego no se distribuye: el runtime se construye en tu PC desde tu imagen y se
# queda en tu PC. La cache se puede borrar cuando quieras.
#
# Parametros:
#   -Iso       imagen .iso/.bin/.cue (si falta, se pide con un dialogo)
#   -Destino   carpeta donde instalar (si falta, se pide con un dialogo)
#   -Cache     donde se guardan las herramientas (por defecto %LOCALAPPDATA%\ApeEscape3\cache)
#   -Forzar    construye el juego otra vez aunque ya este construido con esa imagen

param(
    [string]$Iso,
    [string]$Destino,
    [string]$Cache = (Join-Path $env:LOCALAPPDATA 'ApeEscape3\cache'),
    [switch]$Forzar
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$ProgressPreference = 'SilentlyContinue'

$Repositorio = 'https://codeload.github.com/exoteric33/ps2-native-recomp/zip/refs/heads/main'
$Juego = 'ape3'
$EspacioCacheMb = 3072      # toolchain 975 MB + compilacion 260 MB + datos 52 MB, con margen
$EspacioDestinoMb = 512     # runtime 77 MB + datos 52 MB, con margen
$Script:Registro = $null

# Lo que se copia a la carpeta destino: exactamente lo que deja una construccion limpia
# (comprobado) y el lanzador necesita. 'ee-live', 'vu1-live', 'keys.ini', 'logs' y 'states'
# los crea ps2run.exe la primera vez que se juega, no el proceso de traduccion; copiarlos
# ademas pisaria las teclas que el usuario ya hubiera configurado.
$PiezasJuego = @('disc', 'entries.txt', 'vu0', 'vu1')
$PiezasRuntime = @('ps2run.exe', 'SDL2.dll', 'dxcompiler.dll', 'dxil.dll')

# ---------------------------------------------------------------- mensajes y registro

function Write-Log([string]$texto) {
    if (-not $Script:Registro) { return }
    try { Add-Content -LiteralPath $Script:Registro -Value ('{0:HH:mm:ss}  {1}' -f (Get-Date), $texto) } catch { }
}

function Write-Paso([string]$texto) {
    Write-Host ''
    Write-Host ("== $texto") -ForegroundColor Cyan
    Write-Log $texto
}

function Write-Detalle([string]$texto) {
    Write-Host ("   $texto")
    Write-Log $texto
}

# Todo error del instalador sale por aqui: mensaje en espanol y nunca por sorpresa.
function Stop-Installer([string]$mensaje) {
    throw [System.InvalidOperationException]::new($mensaje)
}

# ---------------------------------------------------------------- comprobaciones

# bash.exe de MSYS quiere rutas con barra normal y la letra de unidad: E:/dir/file
function ConvertTo-PosixPath([string]$path) {
    $path = $path.Replace('\', '/')
    if ($path -match '^([A-Za-z]):/(.*)$') { return $Matches[1] + ':/' + $Matches[2] }
    $path
}

function Get-FreeMb([string]$path) {
    $probe = $path
    while ($probe -and -not (Test-Path -LiteralPath $probe)) { $probe = Split-Path -Parent $probe }
    if (-not $probe) { return -1 }
    try {
        $raiz = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($probe))
        $unidad = New-Object System.IO.DriveInfo($raiz)
        return [int]($unidad.AvailableFreeSpace / 1MB)
    } catch { return -1 }
}

function Get-IsoProblem([string]$path) {
    $nl = [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($path)) { return 'No has elegido la imagen del disco.' }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return ("No encuentro ese archivo:" + $nl + $path) }
    $extension = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
    if ($extension -eq '.cue') {
        return 'Un .cue es solo una lista de pistas: elige el .bin al que apunta, o el .iso.'
    }
    if ($extension -notin @('.iso', '.bin')) {
        return ("Eso no es una imagen de disco (acaba en '{0}'). Elige el .iso de Ape Escape 3 PAL." -f $extension)
    }
    try {
        $stream = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
        $stream.Close()
    } catch {
        return ("No puedo leer ese archivo (puede estar abierto en otro programa o faltarte permiso):" + $nl + $path)
    }
    $mb = [int]((Get-Item -LiteralPath $path).Length / 1MB)
    if ($mb -lt 100) {
        return (("Ese archivo ocupa {0} MB; un disco de PS2 ronda los 4400 MB." -f $mb) + $nl + 'Puede que hayas elegido el archivo equivocado.')
    }
    return $null
}

# Devuelve la carpeta protegida dentro de la que esta $completa, o $null. El prefijo se
# compara con el separador detras: 'C:\Program FilesOld' no esta dentro de 'C:\Program Files'.
function Test-CarpetaProtegida([string]$completa) {
    foreach ($protegida in @($env:SystemRoot, $env:ProgramFiles, [Environment]::GetEnvironmentVariable('ProgramFiles(x86)'))) {
        if (-not $protegida) { continue }
        $prefijo = $protegida.TrimEnd('\') + '\'
        if ($completa.StartsWith($prefijo, [StringComparison]::OrdinalIgnoreCase)) { return $protegida }
    }
    return $null
}

function Get-DestinoProblem([string]$path) {
    $nl = [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($path)) { return 'No has elegido la carpeta de instalacion.' }
    $completa = [System.IO.Path]::GetFullPath($path)
    if (Test-Path -LiteralPath $completa -PathType Leaf) {
        return ("Esa ruta es un archivo, no una carpeta:" + $nl + $completa)
    }
    $protegida = Test-CarpetaProtegida $completa
    if ($protegida) {
        return ("No instales dentro de '{0}': Windows no deja escribir ahi sin permisos de administrador.{1}Elige algo como C:\Juegos\Ape Escape 3." -f $protegida, $nl)
    }
    if (-not (Test-Path -LiteralPath $completa)) {
        try { New-Item -ItemType Directory -Path $completa -Force | Out-Null }
        catch { return ("No puedo crear la carpeta:" + $nl + $completa) }
    }
    $prueba = Join-Path $completa ('.escritura-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        Set-Content -LiteralPath $prueba -Value 'x'
        Remove-Item -LiteralPath $prueba -Force
    } catch {
        return ("No puedo escribir en esa carpeta (permisos):" + $nl + $completa)
    }
    $libre = Get-FreeMb $completa
    if ($libre -ge 0 -and $libre -lt $EspacioDestinoMb) {
        return ("Esa unidad tiene {0} MB libres y hacen falta unos {1} MB." -f $libre, $EspacioDestinoMb)
    }
    return $null
}

# El config.ini del lanzador a partir de config.ini.example, con la linea 'iso='
# cambiada por la imagen elegida. Si la plantilla no tuviera esa linea, se anade.
function New-ConfigText([string]$template, [string]$isoPath) {
    $lineas = @(Get-Content -LiteralPath $template -Encoding UTF8)
    $salida = New-Object System.Collections.Generic.List[string]
    $puesta = $false
    foreach ($linea in $lineas) {
        if (-not $puesta -and $linea -match '^\s*iso\s*=') {
            $salida.Add("iso=$isoPath")
            $puesta = $true
        } else {
            $salida.Add($linea)
        }
    }
    if (-not $puesta) { $salida.Add("iso=$isoPath") }
    return (($salida -join "`r`n") + "`r`n")
}

# Ya construido con esta misma imagen: no se repite la media hora. Se compara la
# fecha del .exe con la del .iso, como hace el lanzador con sus piezas.
function Test-Built([string]$repo, [string]$isoPath) {
    $exe = Join-Path $repo ('build\native-{0}\ps2run.exe' -f $Juego)
    if (-not (Test-Path -LiteralPath $exe)) { return $false }
    try { return ((Get-Item -LiteralPath $exe).LastWriteTimeUtc -ge (Get-Item -LiteralPath $isoPath).LastWriteTimeUtc) }
    catch { return $false }
}

# ---------------------------------------------------------------- procesos

# Un proceso externo con la linea de argumentos tal cual: la necesita bash.exe
# (el runtime de MSYS la parte el mismo). La salida va a la consola del instalador.
function Invoke-Tool([string]$exe, [string]$argumentos, [string]$cwd) {
    Write-Log ("ejecuto: {0} {1}   (en {2})" -f $exe, $argumentos, $cwd)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $argumentos
    $psi.WorkingDirectory = $cwd
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $false
    $proceso = [System.Diagnostics.Process]::Start($psi)
    $proceso.WaitForExit()
    return $proceso.ExitCode
}

function Get-PowerShellExe {
    return (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe')
}

# ---------------------------------------------------------------- dialogos

function Select-IsoFile {
    Add-Type -AssemblyName System.Windows.Forms
    $dialogo = New-Object System.Windows.Forms.OpenFileDialog
    $dialogo.Title = 'Elige la imagen del disco de Ape Escape 3 (PAL)'
    $dialogo.Filter = 'Imagenes de disco (*.iso;*.bin)|*.iso;*.bin|Todos los archivos (*.*)|*.*'
    if ($dialogo.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
    return $dialogo.FileName
}

function Select-Folder {
    Add-Type -AssemblyName System.Windows.Forms
    $dialogo = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialogo.Description = 'Elige la carpeta donde instalar Ape Escape 3. Se crea si no existe.'
    $dialogo.ShowNewFolderButton = $true
    $dialogo.SelectedPath = $env:USERPROFILE
    if ($dialogo.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
    return $dialogo.SelectedPath
}

# ---------------------------------------------------------------- pasos

# El zip del otro proyecto. Sin git: la carpeta tiene que venir tal cual.
# El parametro NO se llama $cache: PowerShell no distingue mayusculas y seria la misma
# variable que el $Cache del script (y el dot-source de este fichero la escribe en quien lo carga).
function Get-RecompProject([string]$donde) {
    $destino = Join-Path $donde 'ps2-native-recomp'
    if (Test-Path -LiteralPath (Join-Path $destino 'scripts\port.sh')) {
        Write-Detalle 'El proyecto ya estaba descargado.'
        return $destino
    }
    $zip = Join-Path $donde 'ps2-native-recomp.zip'
    if (Test-Path -LiteralPath $destino) { Remove-Item -LiteralPath $destino -Recurse -Force }
    Write-Detalle 'Descargando ps2-native-recomp (unos 2 MB)...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Repositorio -OutFile $zip -UseBasicParsing
    $temporal = Join-Path $donde ('extraer-' + [Guid]::NewGuid().ToString('N'))
    Expand-Archive -LiteralPath $zip -DestinationPath $temporal -Force
    $raiz = @(Get-ChildItem -LiteralPath $temporal -Directory)
    if ($raiz.Count -ne 1) { Stop-Installer ('El zip descargado no tiene la forma esperada (' + $raiz.Count + ' carpetas dentro).') }
    Move-Item -LiteralPath $raiz[0].FullName -Destination $destino
    Remove-Item -LiteralPath $temporal -Recurse -Force
    Remove-Item -LiteralPath $zip -Force
    if (-not (Test-Path -LiteralPath (Join-Path $destino 'scripts\port.sh'))) {
        Stop-Installer 'El zip descargado no trae scripts\port.sh: no es el proyecto que esperaba.'
    }
    return $destino
}

function Copy-Pieces([string]$from, [string]$to, [string[]]$piezas, [string]$que) {
    $nl = [Environment]::NewLine
    if (-not (Test-Path -LiteralPath $from)) {
        Stop-Installer ("No encuentro {0} en:{1}{2}{1}{1}Borra la cache y vuelve a ejecutar el instalador." -f $que, $nl, $from)
    }
    if (-not (Test-Path -LiteralPath $to)) { New-Item -ItemType Directory -Path $to -Force | Out-Null }
    foreach ($pieza in $piezas) {
        $origen = Join-Path $from $pieza
        if (-not (Test-Path -LiteralPath $origen)) {
            Stop-Installer ("Falta '{0}' en {1}: la construccion no termino bien.{2}Borra la cache y vuelve a ejecutar el instalador." -f $pieza, $from, $nl)
        }
        $final = Join-Path $to $pieza
        if (Test-Path -LiteralPath $final) { Remove-Item -LiteralPath $final -Recurse -Force }
        Copy-Item -LiteralPath $origen -Destination $final -Recurse -Force
    }
    Write-Detalle ("{0}: {1} piezas" -f $to, $piezas.Count)
}

function New-Shortcut([string]$lnk, [string]$target, [string]$workdir) {
    try {
        $shell = New-Object -ComObject WScript.Shell
        $acceso = $shell.CreateShortcut($lnk)
        $acceso.TargetPath = $target
        $acceso.WorkingDirectory = $workdir
        $acceso.IconLocation = "$target,0"
        $acceso.Description = 'Ape Escape 3'
        $acceso.Save()
        return $null
    } catch {
        return $_.Exception.Message
    }
}

# ---------------------------------------------------------------- el flujo

function Main {
    $inicio = Get-Date
    $nl = [Environment]::NewLine
    $raiz = Split-Path -Parent $PSScriptRoot
    $lanzador = Join-Path $raiz 'ApeEscape3.exe'
    $plantilla = Join-Path $raiz 'config.ini.example'

    Write-Host 'Ape Escape 3 - instalador' -ForegroundColor Cyan
    Write-Host 'Construye el juego desde tu imagen del disco y deja la carpeta lista.'

    if (-not (Test-Path -LiteralPath $Cache)) { New-Item -ItemType Directory -Path $Cache -Force | Out-Null }
    $Script:Registro = Join-Path $Cache 'instalar.log'
    Write-Log '=== instalacion ==='

    # 1/6 ------------------------------------------------------------- imagen
    Write-Paso '1/6  La imagen del disco'
    if (-not $Iso) { $Iso = Select-IsoFile }
    if (-not $Iso) {
        Stop-Installer ('Cancelado: no hay imagen del disco.' + $nl +
            'El juego se construye desde tu propia copia de Ape Escape 3 PAL (.iso).')
    }
    $Iso = [System.IO.Path]::GetFullPath($Iso)
    $problema = Get-IsoProblem $Iso
    if ($problema) { Stop-Installer $problema }
    $mbIso = [int]((Get-Item -LiteralPath $Iso).Length / 1MB)
    Write-Detalle ("{0} ({1} MB)" -f $Iso, $mbIso)

    # 2/6 ------------------------------------------------------------ destino
    Write-Paso '2/6  Donde instalarlo'
    if (-not $Destino) { $Destino = Select-Folder }
    if (-not $Destino) { Stop-Installer 'Cancelado: no has elegido la carpeta donde instalar.' }
    $Destino = [System.IO.Path]::GetFullPath($Destino)
    $problema = Get-DestinoProblem $Destino
    if ($problema) { Stop-Installer $problema }
    Write-Detalle $Destino
    $libreCache = Get-FreeMb $Cache
    if ($libreCache -ge 0 -and $libreCache -lt $EspacioCacheMb) {
        Stop-Installer ("Para las herramientas hacen falta unos {0} MB y en esa unidad quedan {1} MB.{2}La cache esta en {3}; puedes cambiarla con -Cache." -f $EspacioCacheMb, $libreCache, $nl, $Cache)
    }

    # 3/6 --------------------------------------------------------- herramientas
    Write-Paso '3/6  Las herramientas de compilacion (solo la primera vez)'
    $recomp = Get-RecompProject $Cache
    $toolchain = Join-Path $recomp 'tools\portable'
    if (Test-Path -LiteralPath (Join-Path $toolchain 'env.ps1')) {
        Write-Detalle 'El toolchain ya estaba descargado.'
    } else {
        Write-Detalle 'Descargando 312 MB. Esto tarda: es lo mas lento despues de compilar.'
        $codigo = Invoke-Tool (Get-PowerShellExe) ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $recomp 'scripts\portable.ps1')) $recomp
        if ($codigo -ne 0) {
            Stop-Installer ("No he podido descargar el toolchain (codigo {0}).{1}Comprueba la conexion y vuelve a ejecutar el instalador: lo que ya estaba descargado no se repite." -f $codigo, $nl)
        }
    }

    # 4/6 ----------------------------------------------------------- construir
    Write-Paso '4/6  Construir el juego (30-45 minutos; no cierres esta ventana)'
    if ((-not $Forzar) -and (Test-Built $recomp $Iso)) {
        Write-Detalle 'Ya estaba construido con esta misma imagen: no lo repito.'
    } else {
        # env.ps1 deja el PATH con solo estas herramientas y borra el resto de variables: es
        # lo que esperan setup.sh y port.sh, y no toca nada fuera de este proceso.
        . (Join-Path $toolchain 'env.ps1') -Quiet -Keep 'PS2_JOBS', 'PS2_SCALE'
        $bash = Join-Path $toolchain 'mingit\usr\bin\bash.exe'
        if (-not (Test-Path -LiteralPath $bash)) { Stop-Installer ("No encuentro bash en el toolchain:" + $nl + $bash) }
        $codigo = Invoke-Tool $bash ('"{0}" --native-only' -f (ConvertTo-PosixPath (Join-Path $recomp 'scripts\setup.sh'))) $recomp
        if ($codigo -ne 0) {
            Stop-Installer ("El paso de preparacion fallo (codigo {0}).{1}Vuelve a ejecutar el instalador: reintenta solo lo que falta." -f $codigo, $nl)
        }
        $codigo = Invoke-Tool $bash ('"{0}" "{1}" "{2}" --native-only' -f (ConvertTo-PosixPath (Join-Path $recomp 'scripts\port.sh')), $Juego, (ConvertTo-PosixPath $Iso)) $recomp
        if ($codigo -ne 0) {
            Stop-Installer ("La traduccion del juego fallo (codigo {0}).{1}El registro del instalador esta en {2}; lo que imprimio la compilacion, mas arriba en esta ventana." -f $codigo, $nl, $Script:Registro)
        }
    }

    # 5/6 -------------------------------------------------------------- copiar
    Write-Paso '5/6  Copiar el juego a la carpeta destino'
    Copy-Pieces (Join-Path $recomp ('build\native-' + $Juego)) (Join-Path $Destino 'runtime') $PiezasRuntime 'el runtime'
    Copy-Pieces (Join-Path $recomp ('games\' + $Juego)) (Join-Path $Destino 'game') $PiezasJuego 'los datos del juego'

    $exeDestino = Join-Path $Destino 'ApeEscape3.exe'
    if (-not [StringComparer]::OrdinalIgnoreCase.Equals([System.IO.Path]::GetFullPath($exeDestino), [System.IO.Path]::GetFullPath($lanzador))) {
        if (-not (Test-Path -LiteralPath $lanzador)) {
            Stop-Installer 'Falta ApeEscape3.exe junto a Instalar.cmd: descomprime el zip entero y vuelve a intentarlo.'
        }
        Copy-Item -LiteralPath $lanzador -Destination $exeDestino -Force
    }
    if (-not (Test-Path -LiteralPath $plantilla)) {
        Stop-Installer 'Falta config.ini.example junto a Instalar.cmd: descomprime el zip entero y vuelve a intentarlo.'
    }
    $config = New-ConfigText $plantilla $Iso
    $configPath = Join-Path $Destino 'config.ini'
    [System.IO.File]::WriteAllText($configPath, $config, (New-Object System.Text.UTF8Encoding($false)))
    Write-Detalle $configPath

    # 6/6 -------------------------------------------------------------- acceso
    Write-Paso '6/6  Acceso directo'
    $lnk = Join-Path $Destino 'Jugar a Ape Escape 3.lnk'
    $problema = New-Shortcut $lnk $exeDestino $Destino
    if ($problema) {
        Write-Detalle ("No he podido crear el acceso directo ({0}). Doble clic en ApeEscape3.exe." -f $problema)
    } else {
        Write-Detalle $lnk
    }

    $segundos = [int]((Get-Date) - $inicio).TotalSeconds
    $mbCache = 0
    try {
        $suma = (Get-ChildItem -LiteralPath $Cache -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        if ($suma) { $mbCache = [int]($suma / 1MB) }
    } catch { }

    Write-Host ''
    Write-Host 'Listo.' -ForegroundColor Green
    Write-Host ("  Juego:    {0}" -f $Destino)
    Write-Host ("  Imagen:   {0}" -f $Iso)
    Write-Host '  Juega con el acceso directo "Jugar a Ape Escape 3".'
    Write-Host ("  Ha tardado {0} min." -f [int]($segundos / 60))
    if ($mbCache -gt 0) {
        Write-Host ("  Las herramientas ({0} MB) estan en {1}; se pueden borrar y se descargan otra vez si hacen falta." -f $mbCache, $Cache)
    } else {
        Write-Host ("  Las herramientas estan en {0}; se pueden borrar y se descargan otra vez si hacen falta." -f $Cache)
    }
    Write-Log ("fin: {0} s, cache {1} MB" -f $segundos, $mbCache)
}

# Dot-sourcing (. install\instalar.ps1) solo carga las funciones; ejecutarlo instala.
if ($MyInvocation.InvocationName -ne '.') {
    try {
        Main
        exit 0
    } catch {
        Write-Host ''
        Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Log ("ERROR: {0}" -f $_.Exception.Message)
        if ($Script:Registro) { Write-Host ("Registro completo: {0}" -f $Script:Registro) }
        exit 1
    }
}
