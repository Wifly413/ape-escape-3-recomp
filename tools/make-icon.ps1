# Dibuja el icono del lanzador y escribe el .ico multirresolucion.
#
#   powershell -ExecutionPolicy Bypass -File tools\make-icon.ps1
#   powershell -ExecutionPolicy Bypass -File tools\make-icon.ps1 -Source resources\mi-icon.png
#
# Sin -Source dibuja el icono por codigo (un mono asomando sobre una tira de pelicula).
# Con -Source, redimensiona el PNG que le pases. En los dos casos escribe el .ico con
# los tamanos 16, 24, 32, 48, 64, 128 y 256 px.
#
# Parametros:
#   -Source  PNG de partida (opcional)
#   -Out     .ico de salida (por defecto resources\ApeEscape3.ico)
#   -Preview PNG grande de previsualizacion (por defecto resources\icon-preview.png)

param(
    [string]$Source = '',
    [string]$Out = 'resources\ApeEscape3.ico',
    [string]$Preview = 'resources\icon-preview.png'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$sizes = @(16, 24, 32, 48, 64, 128, 256)

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-Master {
    $s = 1024
    $bmp = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $card = New-RoundedPath 0 0 $s $s 224
    $g.SetClip($card)

    # Fondo: violeta profundo con un halo arriba.
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point(0, $s)),
        [System.Drawing.Color]::FromArgb(255, 62, 32, 96), [System.Drawing.Color]::FromArgb(255, 24, 12, 38))
    $g.FillRectangle($bg, 0, 0, $s, $s)
    $glow = New-Object System.Drawing.Drawing2D.PathGradientBrush($card)
    $glow.CenterPoint = New-Object System.Drawing.Point(512, 300)
    $glow.CenterColor = [System.Drawing.Color]::FromArgb(120, 160, 110, 220)
    $glow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 160, 110, 220))
    $g.FillRectangle($glow, 0, 0, $s, $s)
    $bg.Dispose(); $glow.Dispose()

    # Tira de pelicula: banda dorada con los hoyos de paso.
    $band = New-Object System.Drawing.Rectangle(0, 596, $s, 272)
    $film = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 240, 194, 78))
    $g.FillRectangle($film, $band)
    $hole = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 26, 14, 40))
    for ($x = 30; $x -lt $s; $x += 152) {
        foreach ($hy in 616, 796) {
            $p = New-RoundedPath $x $hy 74 40 14
            $g.FillPath($hole, $p)
            $p.Dispose()
        }
    }
    $film.Dispose(); $hole.Dispose()

    # Mono: orejas, cabeza, pelo, hocico, ojos y nariz.
    $fur = [System.Drawing.Color]::FromArgb(255, 156, 107, 67)
    $furDark = [System.Drawing.Color]::FromArgb(255, 107, 69, 39)
    $muzzle = [System.Drawing.Color]::FromArgb(255, 217, 179, 140)
    $ink = [System.Drawing.Color]::FromArgb(255, 42, 26, 18)

    $g.FillEllipse((New-Object System.Drawing.SolidBrush($fur)), 253, 315, 190, 190)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($fur)), 581, 315, 190, 190)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($furDark)), 291, 353, 114, 114)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($furDark)), 619, 353, 114, 114)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($fur)), 277, 195, 470, 470)

    $g.FillEllipse((New-Object System.Drawing.SolidBrush($furDark)), 372, 168, 120, 120)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($furDark)), 452, 132, 130, 130)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($furDark)), 542, 168, 120, 120)

    $g.FillEllipse((New-Object System.Drawing.SolidBrush($muzzle)), 367, 387, 290, 185)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($ink)), 371, 302, 96, 96)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($ink)), 557, 302, 96, 96)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), 397, 326, 32, 32)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), 583, 326, 32, 32)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($furDark)), 472, 432, 80, 58)

    $g.ResetClip()
    $card.Dispose()
    $g.Dispose()
    return $bmp
}

function Save-PngBytes([System.Drawing.Image]$img, [int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $size, $size)))
    $g.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $bytes = $ms.ToArray()
    $ms.Dispose()
    return $bytes
}

if ($Source) {
    if (-not (Test-Path -LiteralPath $Source)) { throw "${Source}: no such file" }
    $master = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $Source))
} else {
    $master = New-Master
}

$previewPath = Join-Path $root $Preview
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $previewPath) | Out-Null
$master.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)

$entries = @()
$payload = @()
foreach ($size in $sizes) {
    $bytes = Save-PngBytes $master $size
    $entries += [pscustomobject]@{ Size = $size; Length = $bytes.Length; Offset = 0 }
    $payload += $bytes
}

$outPath = Join-Path $root $Out
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outPath) | Out-Null
$offset = 6 + (16 * $entries.Count)
foreach ($e in $entries) { $e.Offset = $offset; $offset += $e.Length }

$stream = [System.IO.File]::Create($outPath)
$writer = New-Object System.IO.BinaryWriter($stream)
$writer.Write([uint16]0)
$writer.Write([uint16]1)
$writer.Write([uint16]$entries.Count)
foreach ($e in $entries) {
    $w = if ($e.Size -ge 256) { 0 } else { $e.Size }
    $writer.Write([byte]$w)
    $writer.Write([byte]$w)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]32)
    $writer.Write([uint32]$e.Length)
    $writer.Write([uint32]$e.Offset)
}
foreach ($bytes in $payload) { $writer.Write($bytes) }
$writer.Flush()
$writer.Dispose()
$stream.Dispose()

if (-not $Source) { $master.Dispose() } else { $master.Dispose() }

Write-Host "preview: $previewPath"
Write-Host "icono:   $outPath ($($sizes.Count) tamanos: $($sizes -join ', '))"
