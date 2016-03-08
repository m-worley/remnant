@echo off

::Create binary directory
set SRC_DIR="%~dp0src"
set BUILD_DIR="%~dp0bin"
set INCLUDES=%~dp0include\
set EXTERNAL_INCLUDES=%~dp0external\include\
mkdir %BUILD_DIR%

::Assemble source files.
echo assembling...
cd %SRC_DIR%
rgbasm95 -i%EXTERNAL_INCLUDES% -i%INCLUDES% -oremnant.obj remnant.asm
if errorlevel 1 goto end

::Link.
echo linking...
cmd /C ..\makelnk remnant > remnant.lnk
xlink95 -mremnant.map remnant.lnk
if errorlevel 1 goto end

::Fix checksums.
echo fixing...
rgbfix95 -v remnant.gb

::Copy to binary directory.
copy /V "remnant.gb" %BUILD_DIR%
copy /V "remnant.map" %BUILD_DIR%

:end
del *.obj
del *.lnk
del *.gb
del *.map
cd ..\