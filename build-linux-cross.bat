@echo off
rem bacontsu: cross compile the Linux binaries on Windows with zig cc, no Linux toolchain needed
rem
rem usage: build-linux-cross.bat [target ...]
rem   targets: musl64  x86_64-linux-musl, static, runs on any distro      (default)
rem            musl32  x86-linux-musl, static, 32 bit like the GoldSrc target
rem            gnu64   x86_64-linux-gnu 2.17, dynamic, needs glibc >= 2.17
rem            arm64   aarch64-linux-musl, static, for ARM VMs and boards
rem            all     every target above
rem
rem zig is picked up from %ZIG_EXE%, then PATH, then build\tools, and downloaded if missing.
setlocal EnableExtensions
pushd "%~dp0"

set "ZIGVER=0.14.1"
set "ZIGFOUND="

if defined ZIG_EXE if exist "%ZIG_EXE%" set "ZIGFOUND=%ZIG_EXE%"
if not defined ZIGFOUND for %%z in (zig.exe) do if exist "%%~$PATH:z" set "ZIGFOUND=%%~$PATH:z"
if not defined ZIGFOUND for /d %%d in ("build\tools\zig-*") do if exist "%%d\zig.exe" set "ZIGFOUND=%%d\zig.exe"

if not defined ZIGFOUND (
	echo zig not found, downloading zig %ZIGVER% into build\tools ...
	if not exist "build\tools" mkdir "build\tools"
	where curl >nul 2>nul
	if errorlevel 1 (
		echo error: curl.exe not available, install zig manually from https://ziglang.org/download/
		goto :fail
	)
	curl -L --fail --silent --show-error -o "build\tools\zig-%ZIGVER%.zip" "https://ziglang.org/download/%ZIGVER%/zig-x86_64-windows-%ZIGVER%.zip"
	if errorlevel 1 (
		echo error: download failed, install zig manually from https://ziglang.org/download/
		goto :fail
	)
	tar -xf "build\tools\zig-%ZIGVER%.zip" -C "build\tools"
	if errorlevel 1 (
		echo error: could not extract the zig archive
		goto :fail
	)
	for /d %%d in ("build\tools\zig-*") do if exist "%%d\zig.exe" set "ZIGFOUND=%%d\zig.exe"
)

if not defined ZIGFOUND (
	echo error: zig could not be located after the download
	goto :fail
)
echo using zig: %ZIGFOUND%

rem same defines the Makefile uses for the POSIX build
set "DEFS=-DSTUDIOMDL -DSYSTEM_POSIX -DHAVE_SYS_TIME_H -DHAVE_UNISTD_H -DHAVE_SYS_STAT_H -DHAVE_FCNTL_H -DHAVE_SYS_RESOURCE_H -D_strdup=strdup -D_strlwr=strlwr -D_strupr=strupr -Dstricmp=strcasecmp -D_unlink=unlink -D_open=open -D_read=read -D_close=close"
set "SRCS=src\bmpread.c src\cmdlib.c src\mathlib.c src\scriplib.c src\studiomdl.c src\trilib.c src\tristrip.c src\write.c"

set "SEL=%*"
if not defined SEL set "SEL=musl64"
if /i "%SEL%"=="all" set "SEL=musl64 musl32 gnu64 arm64"

for %%s in (%SEL%) do (
	call :build %%s
	if errorlevel 1 goto :fail
)

echo.
echo done, copy the binary you need to the Linux machine and run "chmod +x studiomdl":
if exist "build\linux-x86_64-musl\studiomdl"  echo   build\linux-x86_64-musl\studiomdl   static, 64 bit, no dependencies
if exist "build\linux-x86-musl\studiomdl"     echo   build\linux-x86-musl\studiomdl      static, 32 bit, no dependencies
if exist "build\linux-x86_64-gnu\studiomdl"   echo   build\linux-x86_64-gnu\studiomdl    dynamic, needs glibc 2.17 or newer
if exist "build\linux-aarch64-musl\studiomdl" echo   build\linux-aarch64-musl\studiomdl  static, arm64, no dependencies
popd
exit /b 0

:build
set "K=%~1"
set "TRIPLE="
set "NAME="
if /i "%K%"=="musl64" ( set "TRIPLE=x86_64-linux-musl" & set "NAME=x86_64-musl" )
if /i "%K%"=="musl32" ( set "TRIPLE=x86-linux-musl" & set "NAME=x86-musl" )
if /i "%K%"=="gnu64" ( set "TRIPLE=x86_64-linux-gnu.2.17" & set "NAME=x86_64-gnu" )
if /i "%K%"=="arm64" ( set "TRIPLE=aarch64-linux-musl" & set "NAME=aarch64-musl" )
if not defined TRIPLE (
	echo error: unknown target "%K%", use musl64, musl32, gnu64, arm64 or all
	exit /b 2
)
if not exist "build\linux-%NAME%" mkdir "build\linux-%NAME%"
echo building %NAME% [%TRIPLE%]
"%ZIGFOUND%" cc -target %TRIPLE% -O2 %DEFS% %SRCS% -lm -pthread -o "build\linux-%NAME%\studiomdl"
if errorlevel 1 (
	echo error: build failed for %NAME%
	exit /b 1
)
exit /b 0

:fail
popd
exit /b 1
