# Recorta el logo oficial de Ape Escape 3 de una imagen de la caratula o de la etiqueta
# del disco, y lo deja en un cuadro cuadrado con el color de fondo, para usarlo de icono.
#
#   powershell -ExecutionPolicy Bypass -File tools\make-icon-from-cover.ps1 `
#       -Source tmp\lb\e67f5df3-....png -Crop 205,110,370,230 -Sample 170,140
#
# Parametros:
#   -Source  imagen de partida (obligatorio)
#   -Crop    x,y,ancho,alto del logo dentro de la imagen
#   -Sample  x,y de un punto del fondo, para tomar su color
#   -Out     PNG cuadrado de salida (por defecto resources\official-icon.png)
#   -Size    lado del cuadro de salida (por defecto 1024)

param(
    [Parameter(Mandatory = $true)][string]$Source,
    [string]$Crop = '205,110,370,230',
    [string]$Sample = '170,140',
    [string]$Mask = '',
    [string]$Out = 'resources\official-icon.png',
    [int]$Size = 1024
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$srcPath = if ([System.IO.Path]::IsPathRooted($Source)) { $Source } else { Join-Path $root $Source }
if (-not (Test-Path -LiteralPath $srcPath)) { throw "${srcPath}: no such file" }

$parts = $Crop.Split(',') | ForEach-Object { [int]$_.Trim() }
$logo = New-Object System.Drawing.Rectangle($parts[0], $parts[1], $parts[2], $parts[3])
$sp = $Sample.Split(',') | ForEach-Object { [int]$_.Trim() }

$src = [System.Drawing.Image]::FromFile($srcPath)
$flat = New-Object System.Drawing.Bitmap($src)
$sky = $flat.GetPixel($sp[0], $sp[1])

# Las mascaras tapan trozos de la ilustracion que no son del logo, con el color del fondo.
if ($Mask) {
    $brush = New-Object System.Drawing.SolidBrush($sky)
    $mg = [System.Drawing.Graphics]::FromImage($flat)
    $mg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    foreach ($m in ($Mask -split ';')) {
        if (-not $m.Trim()) { continue }
        $mp = $m.Split(',') | ForEach-Object { [int]$_.Trim() }
        $mg.FillRectangle($brush, $mp[0], $mp[1], $mp[2], $mp[3])
        Write-Host "mascara: $($mp[0]),$($mp[1]) $($mp[2])x$($mp[3])"
    }
    $mg.Dispose()
    $brush.Dispose()
}

$dst = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear($sky)

$scale = [Math]::Min(($Size * 0.94) / $logo.Width, ($Size * 0.56) / $logo.Height)
$w = [int]($logo.Width * $scale)
$h = [int]($logo.Height * $scale)
$x = [int](($Size - $w) / 2)
$y = [int](($Size - $h) / 2)
$g.DrawImage($flat, (New-Object System.Drawing.Rectangle($x, $y, $w, $h)), $logo, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$flat.Dispose()

$outPath = Join-Path $root $Out
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outPath) | Out-Null
$dst.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose()
$src.Dispose()

Write-Host "origen:    $Source ($($logo.Width)x$($logo.Height) recortado)"
Write-Host "fondo:     RGB($($sky.R),$($sky.G),$($sky.B))"
Write-Host "logo:      $w x $h en ($x,$y)"
Write-Host "icono:     $outPath"
