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

```bat
D:\fasm\fasm.exe -i"D:\fasm\INCLUDE\\" pong.asm pong.exe
```

## Run

```bat
pong.exe
```

## Unit tests

The tests are implemented as a separate executable that includes `pong.asm` in `UNIT_TEST` mode.
In test mode, keyboard polling is bypassed so tests are deterministic.

Build tests:

```bat
D:\fasm\fasm.exe -i"D:\fasm\INCLUDE\\" tests.asm tests.exe
```

Run tests:

```bat
tests.exe
```

`tests.exe` returns exit code `0` when all tests pass, and `1` when any test fails.

## Controls

- `W` / `S` : move left paddle up/down
- Right paddle AI tracks incoming balls (and recenters when ball moves away)

## Notes

- Renders in terminal using ANSI escape sequences.
- Uses `MSVCRT` (`printf`, `_kbhit`, `_getch`) for text output + keyboard polling.
- Uses `kernel32` (`Sleep`) for frame pacing.
