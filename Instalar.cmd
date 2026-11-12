@echo off
rem Instalador de Ape Escape 3: doble clic. Pide la imagen del disco, pregunta la
rem carpeta destino y deja el juego listo para jugar, en un solo paso.
rem
rem -STA es para los dialogos y -ExecutionPolicy Bypass solo para esta ejecucion:
rem no cambia nada del sistema (la misma idea que Start.cmd del otro proyecto).
rem
rem Tambien vale sin dialogos:  Instalar.cmd -Iso "D:\juego.iso" -Destino "C:\Juegos\Ape Escape 3"

setlocal
set "SCRIPT=%~dp0install\instalar.ps1"
if not exist "%SCRIPT%" (
    echo Falta install\instalar.ps1 junto a Instalar.cmd.
    echo Descomprime el zip entero y vuelve a intentarlo.
    pause
    exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%SCRIPT%" %*
echo.
pause
