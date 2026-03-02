if ~defined UNIT_TEST
format PE console 4.0
entry start
end if

include 'win32ax.inc'

W = 80
H = 24
PADDLE_H = 4
LEFT_X = 2
RIGHT_X = 77

STD_OUTPUT_HANDLE = -11
ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4

section '.data' data readable writeable
  esc_clear db 27,'[2J',27,'[H',0
  esc_home  db 27,'[H',0
  fmt_str   db '%s',0
  frame_buf rb 4096

  left_y    dd 10
  right_y   dd 10
  ball_x    dd 40
  ball_y    dd 12
  vx        dd 1
  vy        dd 1

  out_handle dd 0
  old_mode   dd 0

section '.code' code readable executable

proc clamp_paddles
  mov eax,[left_y]
  cmp eax,1
  jge .l_top_ok
  mov [left_y],1
.l_top_ok:
  mov eax,H-PADDLE_H-1
  mov edx,[left_y]
  cmp edx,eax
  jle .l_done
  mov [left_y],eax
.l_done:

  mov eax,[right_y]
  cmp eax,1
  jge .r_top_ok
  mov [right_y],1
.r_top_ok:
  mov eax,H-PADDLE_H-1
  mov edx,[right_y]
  cmp edx,eax
  jle .done
  mov [right_y],eax
.done:
  ret
endp

proc reset_ball, dir
  mov [ball_x],40
  mov [ball_y],12
  mov eax,[dir]
  mov [vx],eax
  mov [vy],1
  ret
endp

proc handle_input
if defined UNIT_TEST
  ret
else
  cinvoke _kbhit
  test eax,eax
  jz .done

  cinvoke _getch
  cmp eax,'w'
  je .up
  cmp eax,'W'
  je .up
  cmp eax,'s'
  je .down
  cmp eax,'S'
  je .down
  jmp .done

.up:
  sub [left_y],1
  jmp .done
.down:
  add [left_y],1
.done:
  ret
end if
endp

proc update_game
  call handle_input

  ; right paddle AI: track only when ball is incoming (moving right)
  mov eax,[vx]
  cmp eax,0
  jle .ai_return_center

  ; incoming ball: follow its Y with small deadzone
  mov eax,[ball_y]
  mov edx,[right_y]
  add edx,PADDLE_H/2
  mov ecx,edx
  dec ecx
  cmp eax,ecx
  jl .ai_up
  mov ecx,edx
  inc ecx
  cmp eax,ecx
  jg .ai_down
  jmp .ai_done

.ai_return_center:
  ; when ball moves away, drift back toward screen center slowly
  mov eax,H/2
  mov edx,[right_y]
  add edx,PADDLE_H/2
  cmp edx,eax
  jl .ai_down
  jg .ai_up
  jmp .ai_done

.ai_up:
  sub [right_y],1
  jmp .ai_done
.ai_down:
  add [right_y],1
.ai_done:

  call clamp_paddles

  mov eax,[ball_x]
  add eax,[vx]
  mov [ball_x],eax

  mov eax,[ball_y]
  add eax,[vy]
  mov [ball_y],eax

  ; top/bottom
  mov eax,[ball_y]
  cmp eax,1
  jge .check_bottom
  mov [ball_y],1
  mov eax,[vy]
  neg eax
  mov [vy],eax
.check_bottom:
  mov eax,[ball_y]
  cmp eax,H-2
  jle .check_left
  mov dword [ball_y],H-2
  mov eax,[vy]
  neg eax
  mov [vy],eax

.check_left:
  mov eax,[vx]
  cmp eax,0
  jge .check_right
  mov eax,[ball_x]
  cmp eax,LEFT_X+1
  jne .check_right

  mov ecx,[ball_y]
  mov edx,[left_y]
  cmp ecx,edx
  jl .score_left
  add edx,PADDLE_H-1
  cmp ecx,edx
  jg .score_left

  mov eax,[vx]
  neg eax
  mov [vx],eax
  jmp .check_score

.check_right:
  mov eax,[vx]
  cmp eax,0
  jle .check_score
  mov eax,[ball_x]
  cmp eax,RIGHT_X-1
  jne .check_score

  mov ecx,[ball_y]
  mov edx,[right_y]
  cmp ecx,edx
  jl .score_right
  add edx,PADDLE_H-1
  cmp ecx,edx
  jg .score_right

  mov eax,[vx]
  neg eax
  mov [vx],eax
  jmp .check_score

.score_left:
  stdcall reset_ball, 1
  jmp .check_score

.score_right:
  stdcall reset_ball, 0FFFFFFFFh

.check_score:
  ret
endp

proc build_frame
  mov edi,frame_buf

  ; ESC[H
  mov byte [edi],27
  inc edi
  mov byte [edi],'['
  inc edi
  mov byte [edi],'H'
  inc edi

  xor ebx,ebx              ; y
.y_loop:
  cmp ebx,H
  jge .end_build

  xor ecx,ecx              ; x
.x_loop:
  cmp ecx,W
  jge .line_end

  mov al,' '

  ; borders
  cmp ebx,0
  je .put_border
  cmp ebx,H-1
  je .put_border
  cmp ecx,0
  je .put_border
  cmp ecx,W-1
  je .put_border

  ; left paddle
  cmp ecx,LEFT_X
  jne .check_right_paddle
  mov edx,[left_y]
  cmp ebx,edx
  jl .check_right_paddle
  add edx,PADDLE_H-1
  cmp ebx,edx
  jg .check_right_paddle
  mov al,'|'
  jmp .store

.check_right_paddle:
  cmp ecx,RIGHT_X
  jne .check_ball
  mov edx,[right_y]
  cmp ebx,edx
  jl .check_ball
  add edx,PADDLE_H-1
  cmp ebx,edx
  jg .check_ball
  mov al,'|'
  jmp .store

.check_ball:
  mov edx,[ball_x]
  cmp ecx,edx
  jne .store
  mov edx,[ball_y]
  cmp ebx,edx
  jne .store
  mov al,'O'
  jmp .store

.put_border:
  mov al,'#'

.store:
  mov [edi],al
  inc edi
  inc ecx
  jmp .x_loop

.line_end:
  mov byte [edi],13
  inc edi
  mov byte [edi],10
  inc edi
  inc ebx
  jmp .y_loop

.end_build:
  mov byte [edi],0
  ret
endp

if ~defined UNIT_TEST
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
  call build_frame
  cinvoke printf, fmt_str, frame_buf
  cinvoke fflush, 0
  invoke Sleep, 33
  jmp .main_loop

.exit:
  invoke ExitProcess, 0

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL', \
          msvcrt,   'MSVCRT.DLL'

  import kernel32, \
         GetStdHandle,  'GetStdHandle', \
         GetConsoleMode,'GetConsoleMode', \
         SetConsoleMode,'SetConsoleMode', \
         Sleep,         'Sleep', \
         ExitProcess,   'ExitProcess'

  import msvcrt, \
         printf,        'printf', \
         fflush,        'fflush', \
         _kbhit,        '_kbhit', \
         _getch,        '_getch'
end if
