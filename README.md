# x86 Assembly Pong (ANSI Console)

This repo now uses a **pure ANSI text console** version of Pong (no Win32 GUI/GDI drawing).
It is written in **32-bit x86 assembly** using **FASM** and runs in a Windows terminal.

## Files

- `pong.asm` - console Pong source (FASM syntax).
- `tests.asm` - unit test harness for core game procedures.

## Requirements

- Windows 11 (Intel/AMD)
- FASM for Windows (`fasm.exe`)

## Build

The commands below were verified from PowerShell. Using the old -i... form may print FASM usage instead of building, depending on how PowerShell passes the arguments.

```powershell
& 'D:\fasm\fasm.exe' 'pong.asm' 'pong.exe'
```

## Run

```bat
pong.exe
```

## Unit tests

The tests are implemented as a separate executable that includes `pong.asm` in `UNIT_TEST` mode.
In test mode, keyboard polling is bypassed so tests are deterministic.

Build tests:

```powershell
& 'D:\fasm\fasm.exe' 'tests.asm' 'tests.exe'
```

Run tests:

```bat
tests.exe
```

`tests.exe` returns exit code `0` when all tests pass, and `1` when any test fails.

You can also use the helper scripts in this repo:

Batch:

```bat
run-tests.bat
echo %ERRORLEVEL%
```

PowerShell:

```powershell
.\run-tests.ps1
$LASTEXITCODE
```

Both scripts:

- run `tests.exe`
- print a short success or failure message
- exit with the same code as `tests.exe`

That means they work well in CI or other scripts that need to fail automatically when a test fails.

## Controls

- `W` / `S` : move left paddle up/down
- `O` / `L` : move right paddle up/down
- `Q` : quit

## Notes

- Renders in terminal using ANSI escape sequences with a reserved HUD row while keeping output within a 24-line terminal viewport.
- Uses `MSVCRT` (`printf`, `_kbhit`, `_getch`) for text output + keyboard polling.
- Uses `kernel32` (`Sleep`) for frame pacing.
