@echo off

::Create binary directory
set SRC_DIR="%~dp0src"
set BUILD_DIR="%~dp0bin"
if not exist %BUILD_DIR% (
mkdir %BUILD_DIR%
echo Build directory created...
)

::Set paths for assembling the source files.
set PROJECT_INCLUDES=..\include\
set EXTERNAL_INCLUDES=..\external\include\
set ASSEMBLER=%~dp0tools\RGBASM\rgbasm95.exe
set LINKER=%~dp0tools\RGBASM\xlink95.exe
set CHECKSUM_FIXER=%~dp0tools\RGBASM\rgbfix95.exe

::Assemble source files.
echo Assembling...
cd %SRC_DIR%
cmd /C %ASSEMBLER% -i%PROJECT_INCLUDES% -i%EXTERNAL_INCLUDES% -ogbtile.obj gbtile.asm
if errorlevel 1 goto end

::Link.
echo Linking...
cmd /C ..\makelnk gbtile > gbtile.lnk
cmd /C %LINKER% -mgbtile.map gbtile.lnk
if errorlevel 1 goto end

::Fix checksums.
echo Fixing...
cmd /C %CHECKSUM_FIXER% -v gbtile.gb

::Copy to binary directory.
echo Copying files to build directory...
copy /V "gbtile.gb" %BUILD_DIR%
copy /V "gbtile.map" %BUILD_DIR%

:end
echo Cleaning up...
del *.obj
del *.lnk
del *.map
del *.gb
cd ..\
echo Build complete.