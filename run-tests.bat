@echo off
tests.exe
set EXIT_CODE=%ERRORLEVEL%

if %EXIT_CODE% equ 0 (
    echo Tests passed.
) else (
    echo Tests failed with exit code %EXIT_CODE%.
)

exit /b %EXIT_CODE%