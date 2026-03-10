format PE console 4.0
entry start

UNIT_TEST = 0
include 'pong.asm'

section '.code' code readable executable
start:
  invoke GetStdHandle, STD_OUTPUT_HANDLE
  mov [out_handle],eax

  invoke GetConsoleMode, eax, old_mode
  test eax,eax
  jz .skip_vt
  mov eax,[old_mode]
  or eax,ENABLE_VIRTUAL_TERMINAL_PROCESSING
  invoke SetConsoleMode, [out_handle], eax
.skip_vt:

  cinvoke printf, esc_clear

.main_loop:
  call update_game
  cmp dword [quit_flag],0
  jne .exit
  call build_frame
  cinvoke printf, score_fmt, [left_score], [right_score]
  cinvoke printf, fmt_str, frame_buf
  cinvoke fflush, 0
  invoke Sleep, 33
  jmp .main_loop

.exit:
  invoke ExitProcess, 0

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL', \
          user32,   'USER32.DLL', \
          msvcrt,   'MSVCRT.DLL'

  import kernel32, \
         GetStdHandle,  'GetStdHandle', \
         GetConsoleMode,'GetConsoleMode', \
         SetConsoleMode,'SetConsoleMode', \
         Sleep,         'Sleep', \
         ExitProcess,   'ExitProcess'

  import user32, \
         GetAsyncKeyState, 'GetAsyncKeyState'

  import msvcrt, \
         printf,        'printf', \
         fflush,        'fflush'
