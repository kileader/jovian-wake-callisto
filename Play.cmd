@echo off
if exist "%~dp0builds\windows\CallistoPlayground-v0.3.exe" (
    start "Callisto Playground" "%~dp0builds\windows\CallistoPlayground-v0.3.exe"
) else if exist "%~dp0builds\windows\CallistoPlayground-v0.2.exe" (
    start "Callisto Playground" "%~dp0builds\windows\CallistoPlayground-v0.2.exe"
) else if exist "%~dp0builds\windows\CallistoPlayground.exe" (
    start "Callisto Playground" "%~dp0builds\windows\CallistoPlayground.exe"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\godot.ps1" play
)
