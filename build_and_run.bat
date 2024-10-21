@echo off
setlocal enableextensions
cd /d "%~dp0"

::Run ps script
powershell.exe -executionpolicy bypass -NoProfile -NoLogo -file "%~dpn0.ps1"