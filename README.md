# x86 Assembly Pong (Win32)

This repository contains a small **Pong** game written in **32-bit x86 assembly** using the Win32 API.
It runs on Intel/AMD CPUs and is intended for Windows 11 development.

## Files

- `pong.asm` - game source code (**FASM syntax**).

## Which assembler should I use on Windows 11?

Use **FASM (Flat Assembler)**.

Why:
- `pong.asm` is already written with FASM directives/macros (`format PE`, `proc`, `invoke`, `library`, `import`, etc.).
- It is the most direct path (no syntax conversion needed).
- Works well on modern Intel/AMD Windows 11 machines for 32-bit PE output.

You *can* use MASM/UASM/NASM, but that requires rewriting parts of the source to match their syntax and macro systems.

## FASM setup on Windows 11

1. Download FASM for Windows from: https://flatassembler.net/
2. Extract it to a stable folder, for example:
   - `C:\tools\fasm`
3. Add that folder to your **PATH**:
   - Start Menu -> search **Environment Variables** -> open **Edit the system environment variables**
   - Click **Environment Variables...**
   - Under **User variables** (or **System variables**), select `Path` -> **Edit** -> **New**
   - Add: `C:\tools\fasm`
   - Click **OK** on all dialogs
4. Close and reopen PowerShell / CMD.
5. Verify installation:

```bat
fasm
```

If PATH is correct, FASM prints its banner/help text.

### Quick no-PATH alternative

If you prefer not to set PATH, run FASM by full path:

```bat
C:\tools\fasm\fasm.exe pong.asm pong.exe
```

## Requirements (Windows 11)

- [FASM](https://flatassembler.net/) (Flat Assembler)
- A Windows machine (Intel/AMD)

## Build

From a Command Prompt or PowerShell in this repository:

```bat
fasm pong.asm pong.exe
```

If build succeeds, `pong.exe` is created in the same folder.

## Run

```bat
pong.exe
```

## Controls

- `↑` : move left paddle up
- `↓` : move left paddle down

Right paddle is controlled by a simple AI.

## Notes

- The game uses a 16 ms Win32 timer (~60 FPS target).
- Window resize is supported; paddles stay clamped within the client area.
