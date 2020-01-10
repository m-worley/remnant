@echo off
set EMULATOR=tools/BGB/bgb.exe
set ROM=bin/gbtile.gb
if not exist %ROM% (
echo Game ROM not found!  Run build.bat first to build the game.
) ELSE (
start %EMULATOR% bin/gbtile.gb
)
