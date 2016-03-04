@echo off

if exist %1.gb del %1.gb

:: Create binary directory
set BUILD_DIR="%~dp0bin"
mkdir %BUILD_DIR%

:: Assemble and link
cmd /C makelnk %1 > %1.lnk
echo assembling...
rgbasm -o%1.obj %1.asm
if errorlevel 1 goto end
echo linking...
xlink -mmap %1.lnk
if errorlevel 1 goto end
echo fixing...
rgbfix -v map

::Copy to binary directory.
copy /V "%~dp0%1.gb" %BUILD_DIR%

:end
del *.obj