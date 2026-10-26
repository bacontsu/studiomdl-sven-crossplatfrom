@echo off
rem bacontsu: build studiomdl with MSVC, no make/gcc needed on Windows
rem usage: build-msvc.bat [x86 or x64]   (default x86, the 32-bit GoldSrc target)
setlocal EnableExtensions

set "ARCH=%~1"
if not defined ARCH set "ARCH=x86"

if /i "%ARCH%"=="x86" (
  set "VCVARS=vcvars32.bat"
) else if /i "%ARCH%"=="x64" (
  set "VCVARS=vcvars64.bat"
) else (
  echo error: unknown architecture "%ARCH%", use x86 or x64
  exit /b 2
)

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
  echo error: vswhere.exe not found - install Visual Studio with the C++ toolset
  exit /b 1
)

set "VSPATH="
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH (
  echo error: no Visual Studio installation with the C++ toolset found
  exit /b 1
)

call "%VSPATH%\VC\Auxiliary\Build\%VCVARS%" >nul
if errorlevel 1 (
  echo error: could not initialise the MSVC environment
  exit /b 1
)

pushd "%~dp0"
set "OUT=build\msvc-%ARCH%"
if not exist "%OUT%" mkdir "%OUT%"

rem bacontsu: _CRT_SECURE_NO_WARNINGS silences the MSVC deprecation noise of this legacy C code
cl /nologo /W3 /D_CONSOLE /DSYSTEM_WIN32 /DSTUDIOMDL /D_CRT_SECURE_NO_WARNINGS ^
   /Fo"%OUT%\\" /Fd"%OUT%\\" ^
   src\bmpread.c src\cmdlib.c src\mathlib.c src\scriplib.c src\studiomdl.c ^
   src\trilib.c src\tristrip.c src\write.c ^
   /link /OUT:"%OUT%\studiomdl.exe"
set "RC=%ERRORLEVEL%"
popd

if not "%RC%"=="0" (
  echo build failed
  exit /b %RC%
)

echo built %OUT%\studiomdl.exe
echo smoke test: cd tests ^&^& ..\%OUT%\studiomdl.exe tri.qc
exit /b 0
