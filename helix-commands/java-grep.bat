@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0java-grep-impl.ps1" %*
