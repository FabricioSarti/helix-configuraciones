@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0java-del-impl.ps1" %*
