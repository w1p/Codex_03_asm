# x86 Assembly Pong (ANSI Console)

This repo uses a pure ANSI text-console version of Pong written in 32-bit x86 assembly with FASM.

## Folder layout

- `src/` contains game source files.
- `tests/` contains module-specific test executables and shared test helpers.
- `scripts/` contains build and test entry points.

Current files:

- `src/pong.asm` - shared Pong game logic and state.
- `src/pong_game.asm` - executable game wrapper and imports.
- `tests/test_pong.asm` - tests for `src/pong.asm`.
- `tests/test_common.inc` - shared test helper include for assertions and test utilities.
- `scripts/build-game.ps1` - builds the game executable.
- `scripts/build-tests.ps1` - builds all test executables.
- `scripts/run-tests.ps1` - runs all test executables and returns a CI-friendly exit code.

## Requirements

- Windows 11 (Intel/AMD)
- FASM for Windows (`fasm.exe`)

## Build the game

```powershell
.\scripts\build-game.ps1
```

This builds `pong.exe` from `src/pong_game.asm`, which includes `src/pong.asm`.

## Run the game

```bat
pong.exe
```

## Build tests

```powershell
.\scripts\build-tests.ps1
```

This currently builds:

- `tests/test_pong.exe`

## Run tests

```powershell
.\scripts\run-tests.ps1
```

Or use the root compatibility wrappers:

```powershell
.\run-tests.ps1
```

```bat
run-tests.bat
```

The test runner prints one section per test suite, for example `pong`, and each failing assertion includes the suite and behavior name, such as:

```text
FAIL: pong:test_left_miss_scores right score increments (actual=0 expected=1)
```

That makes it clear which source area the failing test belongs to.

## Adding more assembly modules

When the project grows, follow the same pattern:

- put shared production logic in `src/<module>.asm`
- add an executable wrapper in `src/<module>_game.asm` when needed
- add tests in `tests/test_<module>.asm`
- keep shared assertions in `tests/test_common.inc`
- register the new test executable in `scripts/build-tests.ps1` and `scripts/run-tests.ps1`

Example future layout:

```text
src/
  pong.asm
  pong_game.asm
  physics.asm
  render.asm

tests/
  test_common.inc
  test_pong.asm
  test_physics.asm
  test_render.asm
```
