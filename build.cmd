@echo off
rem Construye el lanzador y sus tests con el toolchain portable de llvm-mingw.
rem
rem   build.cmd         compila el lanzador (ApeEscape3.exe)
rem   build.cmd test    compila y ejecuta los tests
rem
rem Define LLVM_MINGW si el toolchain esta en otro sitio.

setlocal enabledelayedexpansion
cd /d "%~dp0"

if not defined LLVM_MINGW set "LLVM_MINGW=E:\Recomps\ps2-native-recomp\tools\portable\llvm-mingw"
set "CXX=%LLVM_MINGW%\bin\clang++.exe"
if not exist "%CXX%" (
    echo No se encuentra clang++ en "%CXX%".
    echo Define LLVM_MINGW con la carpeta del toolchain y vuelve a intentarlo.
    exit /b 1
)

if not exist build mkdir build

set "MODE=%~1"
if "%MODE%"=="" set "MODE=build"

if /I "%MODE%"=="test" goto test

rem ---- lanzador ----
set "SRCS="
for %%f in (src\*.cpp) do set "SRCS=!SRCS! %%f"

rem El icono: el oficial si el usuario lo ha puesto en su maquina, si no el del proyecto.
rem Se copia a build\ y el .rc incrusta siempre la misma ruta.
set "ICON=resources\ApeEscape3.ico"
if exist "resources\ApeEscape3-oficial.ico" set "ICON=resources\ApeEscape3-oficial.ico"

rem El recurso se genera solo si hay icono.
set "RES="
if exist "!ICON!" (
    copy /y "!ICON!" build\launcher.ico >nul
    if errorlevel 1 exit /b 1
    "!LLVM_MINGW!\bin\windres.exe" -I build resources\launcher.rc -O coff -o build\launcher.res
    if errorlevel 1 exit /b 1
    set "RES=build\launcher.res"
)

"!CXX!" -std=c++20 -O2 -Wall -Wextra -mwindows -static -I src -o ApeEscape3.exe !SRCS! !RES!
if errorlevel 1 exit /b 1
echo Construido ApeEscape3.exe
exit /b 0

:test
rem ---- tests (todo src\ salvo main.cpp) ----
set "SRCS="
for %%f in (src\*.cpp) do (
    if /I not "%%~nxf"=="main.cpp" set "SRCS=!SRCS! %%f"
)
"!CXX!" -std=c++20 -O1 -Wall -Wextra -static -I src -o build\tests.exe tests\tests.cpp !SRCS!
if errorlevel 1 exit /b 1
build\tests.exe
exit /b %errorlevel%
