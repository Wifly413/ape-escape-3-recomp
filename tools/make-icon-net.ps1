# Dibuja el icono del lanzador: una red de captura (Red Reloj) en turquesa, la misma
# herramienta de la serie Ape Escape pero con una paleta que no es la del juego.
#
#   powershell -ExecutionPolicy Bypass -File tools\make-icon-net.ps1
#
# Parametros:
#   -Out     .ico de salida (por defecto resources\ApeEscape3.ico)
#   -Preview PNG grande de previsualizacion (por defecto resources\icon-preview.png)

param(
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

function New-NetIcon {
    $s = 1024
    $bmp = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $card = New-RoundedPath 0 0 $s $s 224
    $g.SetClip($card)

    # Fondo: petroleo oscuro con un halo turquesa arriba a la izquierda.
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point(0, $s)),
        [System.Drawing.Color]::FromArgb(255, 14, 62, 74), [System.Drawing.Color]::FromArgb(255, 5, 22, 30))
    $g.FillRectangle($bg, 0, 0, $s, $s)
    $glow = New-Object System.Drawing.Drawing2D.PathGradientBrush($card)
    $glow.CenterPoint = New-Object System.Drawing.Point(330, 250)
    $glow.CenterColor = [System.Drawing.Color]::FromArgb(130, 60, 220, 205)
    $glow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 60, 220, 205))
    $g.FillRectangle($glow, 0, 0, $s, $s)
    $bg.Dispose(); $glow.Dispose()

    $hoop = New-Object System.Drawing.Rectangle(150, 120, 560, 560)
    $cx = $hoop.X + $hoop.Width / 2
    $cy = $hoop.Y + $hoop.Height / 2
    $r = $hoop.Width / 2

    # Malla: lineas cruzadas recortadas dentro del aro.
    $inner = New-Object System.Drawing.Drawing2D.GraphicsPath
    $inner.AddEllipse(($hoop.X + 34), ($hoop.Y + 34), ($hoop.Width - 68), ($hoop.Height - 68))
    $mesh = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(115, 94, 236, 214)), 9
    $g.SetClip($inner)
    for ($i = -2; $i -le 8; $i++) {
        $o = $i * 90
        $g.DrawLine($mesh, ($cx - $r + $o), ($cy - $r), ($cx - $r + $o + 2 * $r), ($cy + $r))
        $g.DrawLine($mesh, ($cx - $r + $o), ($cy + $r), ($cx - $r + $o + 2 * $r), ($cy - $r))
    }
    $g.ResetClip()
    $mesh.Dispose(); $inner.Dispose()

    # Aro.
    $rim = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 74, 232, 204)), 52
    $rim.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawEllipse($rim, $hoop)
    $rim.Dispose()

    # Mango: de la parte de abajo del aro hacia la esquina, en ambar.
    $handle = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 240, 168, 66)), 64
    $handle.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $handle.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($handle, ($cx + 150), ($cy + 160), 880, 900)
    $g.DrawLine($handle, ($cx + 150), ($cy + 160), 880, 900)
    $g.DrawLine($handle, ($cx + 150), ($cy + 160), 880, 900)
    $handle.Dispose()

    # Remache del aro, en la union con el mango.
    $rivet = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 240, 168, 66))
    $g.FillEllipse($rivet, ($cx + 128), ($cy + 138), 54, 54)
    $rivet.Dispose()

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

$master = New-NetIcon
$previewPath = Join-Path $root $Preview
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $previewPath) | Out-Null
$master.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)

$entries = @(); $payload = @()
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
$writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$entries.Count)
foreach ($e in $entries) {
    $w = if ($e.Size -ge 256) { 0 } else { $e.Size }
    $writer.Write([byte]$w); $writer.Write([byte]$w); $writer.Write([byte]0); $writer.Write([byte]0)
    $writer.Write([uint16]1); $writer.Write([uint16]32)
    $writer.Write([uint32]$e.Length); $writer.Write([uint32]$e.Offset)
}
foreach ($bytes in $payload) { $writer.Write($bytes) }
$writer.Flush(); $writer.Dispose(); $stream.Dispose()
$master.Dispose()

Write-Host "preview: $previewPath"
Write-Host "icono:   $outPath ($($sizes.Count) tamanos)"
