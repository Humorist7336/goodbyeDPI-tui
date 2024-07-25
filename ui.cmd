@echo off
setlocal enabledelayedexpansion

call :setArch

if not exist %windir%\system32\config\systemprofile\ (
  powershell -Command "Start-Process -Verb RunAs -FilePath '%0'"
  if errorlevel 1 (
    echo Couldn't get administrator privileges
    pause
  )
  exit /b
)

cd /D %~dp0

echo Select thing to do
echo 1. blacklist update
echo 2. service setup + blacklist update
echo 3. service setup
echo 4. service remove

set input="1"
set /p input="Select thing to do [1]: "

if "%input%" == "1" (
  call :listUpdate
  call :serviceRestart
  exit /b 0
) else if "%input%" == "2" (
  call :listUpdate
  call :serviceReinstall
  exit /b 0
) else if "%input%" == "3" (
  call :serviceReinstall
  exit /b 0
) else if "%input%" == "4" (
  call :serviceRemove
  exit /b 0
) else (
  msg * unknown arg
  pause
  exit /b 0
)

:setArch
  reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set arch=x86 || set arch=x86_64
exit /b 0

:listUpdate
  curl -o russia-blacklist.txt https://antizapret.prostovpn.org/domains-export.txt
  copy /b /y custom-blacklist.txt+russia-blacklist.txt blacklist.txt
exit /b 0

:serviceRemove
  sc stop "GoodbyeDPI"
  sc delete "GoodbyeDPI"
exit /b 0

:serviceCreate
  sc create "GoodbyeDPI" binPath= "\"%CD%\%arch%\goodbyedpi.exe\" -6 --frag-by-sni --blacklist \"%CD%\blacklist.txt\"" start= "auto"
  sc description "GoodbyeDPI" "Passive Deep Packet Inspection blocker and Active DPI circumvention utility"
  sc start "GoodbyeDPI"
exit /b 0

:serviceRestart
  sc stop "GoodbyeDPI"
  sc start "GoodbyeDPI"
exit /b 0

:serviceReinstall
  call :serviceRemove
  call :serviceCreate
exit /b 0
