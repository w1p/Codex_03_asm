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
   - `D:\fasm`
3. Add that folder to your **PATH**:
   - Start Menu -> search **Environment Variables** -> open **Edit the system environment variables**
   - Click **Environment Variables...**
   - Under **User variables** (or **System variables**), select `Path` -> **Edit** -> **New**
   - Add: `D:\fasm`
   - Click **OK** on all dialogs
4. Close and reopen PowerShell / CMD.
5. Verify installation:

```bat
fasm
```

If PATH is correct, FASM prints its banner/help text.

## Important: fix for `include 'win32ax.inc'` not found

`pong.asm` uses:

```asm
include 'win32ax.inc'
```

So FASM must know where its `INCLUDE` folder is (usually `D:\fasm\INCLUDE`).

### Option A (recommended): pass include path in command

```bat
D:\fasm\fasm.exe -i"D:\fasm\INCLUDE\\" pong.asm pong.exe
```

### Option B: set `INCLUDE` environment variable once

```bat
setx INCLUDE D:\fasm\INCLUDE
```

Then open a **new terminal** and build normally:

```bat
D:\fasm\fasm.exe pong.asm pong.exe
```

### If you still see `pong.asm [344] ... 0, ... illegal instruction`

You are likely building an older copy of `pong.asm` where `CreateWindowEx` was split incorrectly.
In the current version, it must be a single `invoke` line:

```asm
invoke CreateWindowEx, 0, class_name, window_title, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, WINDOW_W, WINDOW_H, NULL, NULL, ebx, NULL
```

Quick checks in PowerShell:

```powershell
git pull
Select-String -Path .\pong.asm -Pattern 'invoke CreateWindowEx'
```

## Requirements (Windows 11)

- [FASM](https://flatassembler.net/) (Flat Assembler)
- A Windows machine (Intel/AMD)

## Build

From a Command Prompt or PowerShell in this repository:

```bat
D:\fasm\fasm.exe -i"D:\fasm\INCLUDE\\" pong.asm pong.exe
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
