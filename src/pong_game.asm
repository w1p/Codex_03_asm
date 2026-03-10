format PE console 4.0
entry start

UNIT_TEST = 0
include 'pong.asm'

section '.code' code readable executable
start:
  invoke GetStdHandle, STD_INPUT_HANDLE
  mov [in_handle],eax
  invoke GetConsoleMode, eax, old_in_mode
  test eax,eax
  jz .skip_input_mode
  mov eax,[old_in_mode]
  and eax,not (ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or ENABLE_PROCESSED_INPUT)
  invoke SetConsoleMode, [in_handle], eax
.skip_input_mode:

  invoke GetStdHandle, STD_OUTPUT_HANDLE
  mov [out_handle],eax

  invoke GetConsoleMode, eax, old_out_mode
  test eax,eax
  jz .skip_vt
  mov eax,[old_out_mode]
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
  cmp dword [in_handle],0
  je .skip_restore_input
  cmp dword [old_in_mode],0
  je .skip_restore_input
  invoke SetConsoleMode, [in_handle], [old_in_mode]
  invoke FlushConsoleInputBuffer, [in_handle]
.skip_restore_input:

  cmp dword [out_handle],0
  je .skip_restore_output
  cmp dword [old_out_mode],0
  je .skip_restore_output
  invoke SetConsoleMode, [out_handle], [old_out_mode]
.skip_restore_output:

  invoke ExitProcess, 0

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL', \
          user32,   'USER32.DLL', \
          msvcrt,   'MSVCRT.DLL'

  import kernel32, \
         GetStdHandle,  'GetStdHandle', \
         GetConsoleMode,'GetConsoleMode', \
         SetConsoleMode,'SetConsoleMode', \
         FlushConsoleInputBuffer,'FlushConsoleInputBuffer', \
         Sleep,         'Sleep', \
         ExitProcess,   'ExitProcess'

  import user32, \
         GetAsyncKeyState, 'GetAsyncKeyState'

  import msvcrt, \
         printf,        'printf', \
         fflush,        'fflush'
