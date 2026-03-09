include 'win32ax.inc'

W = 80
H = 23
PADDLE_H = 4
LEFT_X = 2
RIGHT_X = 77
BALL_STEP_MS = 100
FRAME_MS = 33

STD_OUTPUT_HANDLE = -11
ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4

section '.data' data readable writeable
  esc_clear db 27,'[2J',27,'[H',0
  esc_home  db 27,'[H',0
  fmt_str   db '%s',0
  frame_buf rb 4096
  score_fmt  db 27,'[HLeft [%d] vs [%d] Right   (W/S: left, O/L: right, Q: quit)',13,10,0

  left_y    dd 10
  right_y   dd 10
  ball_x    dd 40
  ball_y    dd 12
  vx        dd 1
  vy        dd 1
  ball_accum_ms dd 0
  left_score  dd 0
  right_score dd 0
  quit_flag   dd 0

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
  mov dword [ball_accum_ms],0
  ret
endp

proc handle_input
if defined UNIT_TEST & UNIT_TEST = 1
  ret
else
  ; Immediate held-key movement + tap detection between frame polls.
  invoke GetAsyncKeyState, 57h ; W
  test eax,8001h
  jz handle_input_check_left_down
  sub dword [left_y],1

handle_input_check_left_down:
  invoke GetAsyncKeyState, 53h ; S
  test eax,8001h
  jz handle_input_check_right_up
  add dword [left_y],1

handle_input_check_right_up:
  invoke GetAsyncKeyState, 4Fh ; O
  test eax,8001h
  jz handle_input_check_right_down
  sub dword [right_y],1

handle_input_check_right_down:
  invoke GetAsyncKeyState, 4Ch ; L
  test eax,8001h
  jz handle_input_check_quit
  add dword [right_y],1

handle_input_check_quit:
  invoke GetAsyncKeyState, 51h ; Q
  test eax,8001h
  jz handle_input_done
  mov dword [quit_flag],1

handle_input_done:
  ret
end if
endp

proc update_game
  call handle_input

  call clamp_paddles

  add dword [ball_accum_ms],FRAME_MS

.move_loop_check:
  mov eax,[ball_accum_ms]
  cmp eax,BALL_STEP_MS
  jl .check_score
  sub dword [ball_accum_ms],BALL_STEP_MS

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
  jmp .move_loop_check

.check_right:
  mov eax,[vx]
  cmp eax,0
  jle .move_loop_check
  mov eax,[ball_x]
  cmp eax,RIGHT_X-1
  jne .move_loop_check

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
  jmp .move_loop_check

.score_left:
  add dword [right_score],1
  stdcall reset_ball, 1
  jmp .check_score

.score_right:
  add dword [left_score],1
  stdcall reset_ball, 0FFFFFFFFh

.check_score:
  ret
endp

proc build_frame
  mov edi,frame_buf

  ; ESC[2;1H (reserve top row for score/controls)
  mov byte [edi],27
  inc edi
  mov byte [edi],'['
  inc edi
  mov byte [edi],'2'
  inc edi
  mov byte [edi],';'
  inc edi
  mov byte [edi],'1'
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
