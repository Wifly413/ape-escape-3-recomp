# Tests del instalador. Cada CHECK es un comportamiento concreto.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\instalar.tests.ps1
#
# No instala nada: hace dot-source de install\instalar.ps1 y llama a sus funciones
# sueltas sobre una carpeta temporal que se borra al terminar, aunque haya fallos.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$Script:Checks = 0
$Script:Fallos = 0

function Check([bool]$ok, [string]$que) {
    $Script:Checks = $Script:Checks + 1
    if (-not $ok) {
        $Script:Fallos = $Script:Fallos + 1
        Write-Host ('FALLO ' + $que)
    }
}

function Write-Texto([string]$ruta, [string]$texto) {
    [System.IO.File]::WriteAllText($ruta, $texto, (New-Object System.Text.UTF8Encoding($false)))
}

function New-Carpeta([string]$ruta) {
    New-Item -ItemType Directory -Path $ruta -Force | Out-Null
}

$nl = [Environment]::NewLine
$raizRepo = Split-Path -Parent $PSScriptRoot
$instalador = Join-Path $raizRepo 'install\instalar.ps1'
$plantilla = Join-Path $raizRepo 'config.ini.example'
$psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

# Letras que no pueden estar en este archivo: PowerShell 5.1 sin BOM las rompe.
$oAcento = [char]0x00F3
$aAcento = [char]0x00E1
$enye = [char]0x00F1

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('ape3-instalar-tests-' + [Guid]::NewGuid().ToString('N'))
New-Carpeta $temp

try {
    . $instalador

    # -------------------------------------------------- ConvertTo-PosixPath
    Check ((ConvertTo-PosixPath 'E:\a b\c.iso') -eq 'E:/a b/c.iso') 'ConvertTo-PosixPath: E:\a b\c.iso -> E:/a b/c.iso'
    Check ((ConvertTo-PosixPath 'C:\dir (1)\Ape Escape 3.iso') -eq 'C:/dir (1)/Ape Escape 3.iso') 'ConvertTo-PosixPath: ruta con parentesis'
    Check ((ConvertTo-PosixPath 'E:/a/b.iso') -eq 'E:/a/b.iso') 'ConvertTo-PosixPath: ruta ya con barras normales'
    Check ((ConvertTo-PosixPath 'game\disc') -eq 'game/disc') 'ConvertTo-PosixPath: ruta relativa'

    # ------------------------------------------------------ Get-IsoProblem
    $problema = Get-IsoProblem ''
    Check ($null -ne $problema -and $problema.Length -gt 0) 'Get-IsoProblem: ruta vacia -> mensaje'

    $problema = Get-IsoProblem (Join-Path $temp 'no-existe.iso')
    Check ($null -ne $problema -and $problema.Length -gt 0) 'Get-IsoProblem: fichero inexistente -> mensaje'

    $texto = Join-Path $temp 'notas.txt'
    Write-Texto $texto 'hola'
    $problema = Get-IsoProblem $texto
    Check (($null -ne $problema) -and $problema.Contains('.txt')) 'Get-IsoProblem: .txt -> mensaje que nombra la extension'

    # Un .cue es una lista de pistas, no la imagen: hay que mandar al .bin (y no hablar de MB).
    $cue = Join-Path $temp 'sonda.cue'
    Write-Texto $cue 'FILE "disco.bin" BINARY'
    $problema = Get-IsoProblem $cue
    Check (($null -ne $problema) -and $problema.Contains('.cue') -and ($problema -notmatch 'MB')) 'Get-IsoProblem: .cue -> pide el .bin'

    # Un .iso de verdad no se escribe: se reserva el tamano y el sistema no lo llena.
    $disco = Join-Path $temp 'disco.iso'
    $flujo = [System.IO.File]::Create($disco)
    $flujo.SetLength(200MB)
    $flujo.Close()
    $problema = Get-IsoProblem $disco
    Check ($null -eq $problema) 'Get-IsoProblem: .iso de 200 MB -> $null'

    # -------------------------------------------------- Get-DestinoProblem
    $problema = Get-DestinoProblem $texto
    Check ($null -ne $problema -and $problema.Length -gt 0) 'Get-DestinoProblem: un fichero -> mensaje'

    if ($env:ProgramFiles) {
        $problema = Get-DestinoProblem (Join-Path $env:ProgramFiles 'ApeEscape3-tests-instalador')
        Check ($null -ne $problema -and $problema.Length -gt 0) 'Get-DestinoProblem: dentro de C:\Program Files -> mensaje'
    }

    # El prefijo protegido se compara con el separador detras. Se prueba la funcion pura,
    # sin crear nada en C:\ (que es lo que haria Get-DestinoProblem con una ruta nueva).
    Check ($null -ne (Test-CarpetaProtegida (Join-Path $env:ProgramFiles 'juego'))) 'Test-CarpetaProtegida: dentro de C:\Program Files'
    Check ($null -eq (Test-CarpetaProtegida ($env:ProgramFiles + 'Old\juego'))) 'Test-CarpetaProtegida: C:\Program FilesOld no esta dentro'
    Check ($null -eq (Test-CarpetaProtegida ($env:SystemRoot + 'Apps\juego'))) 'Test-CarpetaProtegida: C:\WindowsApps no esta dentro'

    $carpetaAcentos = Join-Path $temp ('Prueba instalaci' + $oAcento + 'n ' + $enye)
    $problema = Get-DestinoProblem $carpetaAcentos
    Check ($null -eq $problema) 'Get-DestinoProblem: carpeta nueva con acentos -> $null'
    Check (Test-Path -LiteralPath $carpetaAcentos -PathType Container) 'Get-DestinoProblem: la carpeta queda creada'

    # ----------------------------------------------------- New-ConfigText
    $isoElegido = 'E:\Juegos\Ape Escape 3 (Europe).iso'
    $config = New-ConfigText $plantilla $isoElegido
    Check ($config.Length -gt 0 -and $config[0] -ne [char]0xFEFF) 'New-ConfigText: el texto no empieza por BOM'
    $lineas = $config -split $nl
    Check ($lineas[$lineas.Count - 1] -eq '') 'New-ConfigText: termina en salto de linea'
    $puestas = @($lineas | Where-Object { $_ -match '^\s*iso\s*=' })
    Check ($puestas.Count -eq 1) 'New-ConfigText: una sola linea iso='
    Check ($puestas[0] -eq ('iso=' + $isoElegido)) 'New-ConfigText: la linea iso= lleva la ruta elegida'
    $plantillaLineas = @(Get-Content -LiteralPath $plantilla -Encoding UTF8)
    Check ($lineas.Count -eq ($plantillaLineas.Count + 1)) 'New-ConfigText: cuenta de lineas igual'
    $obtenidas = @($lineas[0..($lineas.Count - 2)])
    $esperadas = @($plantillaLineas | ForEach-Object {
        if ($_ -match '^\s*iso\s*=') { 'iso=' + $isoElegido } else { $_ }
    })
    Check ((($obtenidas -join $nl) -eq ($esperadas -join $nl))) 'New-ConfigText: el resto de lineas intactas'

    # ---------------------------------------------------------- Test-Built
    $recomp = Join-Path $temp 'recomp'
    New-Carpeta (Join-Path $recomp 'build\native-ape3')
    $exe = Join-Path $recomp 'build\native-ape3\ps2run.exe'
    $iso = Join-Path $temp 'a.iso'
    Write-Texto $iso 'imagen'
    Check (-not (Test-Built $recomp $iso)) 'Test-Built: sin ps2run.exe -> $false'
    Write-Texto $exe 'runtime'
    [System.IO.File]::SetLastWriteTimeUtc($exe, [datetime]::UtcNow.AddHours(-1))
    [System.IO.File]::SetLastWriteTimeUtc($iso, [datetime]::UtcNow.AddHours(-2))
    Check (Test-Built $recomp $iso) 'Test-Built: exe mas nuevo que el iso -> $true'
    [System.IO.File]::SetLastWriteTimeUtc($iso, [datetime]::UtcNow)
    Check (-not (Test-Built $recomp $iso)) 'Test-Built: iso mas nuevo que el exe -> $false'

    # --------------------------------------------------------- Copy-Pieces
    $origen = Join-Path $temp 'build\native-ape3'
    $destino = Join-Path $temp 'destino\game'
    New-Carpeta (Join-Path $origen 'disc')
    Write-Texto (Join-Path $origen 'entries.txt') 'nuevo'
    Write-Texto (Join-Path $origen 'disc\SCES_536.42') 'elf'
    New-Carpeta (Join-Path $destino 'disc')
    Write-Texto (Join-Path $destino 'entries.txt') 'viejo'
    Write-Texto (Join-Path $destino 'disc\sobra.txt') 'resto'
    Copy-Pieces $origen $destino @('disc', 'entries.txt') 'los datos del juego'
    Check (Test-Path -LiteralPath (Join-Path $destino 'disc\SCES_536.42') -PathType Leaf) 'Copy-Pieces: copia las piezas pedidas'
    $copiado = [System.IO.File]::ReadAllText((Join-Path $destino 'entries.txt'))
    Check ($copiado -eq 'nuevo') 'Copy-Pieces: sustituye el fichero que ya estaba'
    Check (-not (Test-Path -LiteralPath (Join-Path $destino 'disc\sobra.txt'))) 'Copy-Pieces: borra los restos previos de la pieza'

    $lanzo = $false
    $mensaje = ''
    try { Copy-Pieces $origen $destino @('disc', 'keys.ini') 'los datos del juego' }
    catch { $lanzo = $true; $mensaje = $_.Exception.Message }
    Check $lanzo 'Copy-Pieces: si falta una pieza lanza una excepcion'
    Check ($mensaje.Contains('keys.ini')) 'Copy-Pieces: el mensaje dice que pieza falta'

    # -------------------------------------------------------- New-Shortcut
    $carpetaLnks = Join-Path $temp ('Accesos ' + $aAcento)
    New-Carpeta $carpetaLnks
    $destinoExe = Join-Path $carpetaLnks 'ApeEscape3.exe'
    Write-Texto $destinoExe 'no es un exe de verdad'
    $lnk = Join-Path $carpetaLnks 'Jugar a Ape Escape 3.lnk'
    $rompio = $false
    $problema = $null
    try { $problema = New-Shortcut $lnk $destinoExe $carpetaLnks }
    catch { $rompio = $true; $problema = $_.Exception.Message }
    Check (-not $rompio) 'New-Shortcut: nunca lanza'
    if ((-not $rompio) -and ($null -eq $problema)) {
        $shell = New-Object -ComObject WScript.Shell
        $leido = $shell.CreateShortcut($lnk)
        Check ((Test-Path -LiteralPath $lnk -PathType Leaf) -and ($leido.TargetPath -eq $destinoExe)) 'New-Shortcut: el .lnk se lee por COM y apunta al exe'
        Check ($leido.WorkingDirectory -eq $carpetaLnks) 'New-Shortcut: el .lnk guarda la carpeta de trabajo'
    } elseif (-not $rompio) {
        Check ($problema.Length -gt 0) 'New-Shortcut: devuelve un mensaje en vez del .lnk'
    }

    # -------------------------------------------------- dot-source del script
    $ayuda = Join-Path $temp 'solo-funciones.ps1'
    $ayudaTexto = @(
        '$ErrorActionPreference = ''Stop''',
        ('. ''' + $instalador.Replace("'", "''") + ''''),
        '$faltan = @()',
        'foreach ($nombre in @(''ConvertTo-PosixPath'', ''Get-IsoProblem'', ''Get-DestinoProblem'', ''New-ConfigText'', ''Test-Built'', ''Copy-Pieces'', ''New-Shortcut'', ''Main'')) {',
        '    if (-not (Get-Command -Name $nombre -CommandType Function -ErrorAction SilentlyContinue)) { $faltan += $nombre }',
        '}',
        'if ($faltan.Count -gt 0) { Write-Output (''FALTAN: '' + ($faltan -join '','')) } else { Write-Output ''SOLO-FUNCIONES'' }'
    ) -join $nl
    Write-Texto $ayuda $ayudaTexto

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $psExe
    $psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $ayuda + '"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proceso = [System.Diagnostics.Process]::Start($psi)
    $salida = $proceso.StandardOutput.ReadToEnd()
    $errores = $proceso.StandardError.ReadToEnd()
    $proceso.WaitForExit()
    Check ($proceso.ExitCode -eq 0) ('dot-source: codigo 0 (error: ' + $errores.Trim() + ')')
    Check ($salida.Trim() -eq 'SOLO-FUNCIONES') 'dot-source: no imprime nada y solo define funciones'
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}

if ($Script:Fallos -eq 0) {
    Write-Host ('instalar: {0} checks, 0 failures' -f $Script:Checks)
    exit 0
}

Write-Host ('instalar: {0} checks, {1} failures' -f $Script:Checks, $Script:Fallos)
exit 1
