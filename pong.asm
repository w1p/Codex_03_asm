format PE GUI 4.0
entry start

include 'win32ax.inc'

WINDOW_W      = 800
WINDOW_H      = 600
PADDLE_W      = 12
PADDLE_H      = 96
PADDLE_MARGIN = 24
PADDLE_SPEED  = 8
BALL_SIZE     = 12

section '.data' data readable writeable
  class_name    db 'AsmPongWindow',0
  window_title  db 'x86 Assembly Pong - Win32/FASM',0

  hwnd_main     dd 0

  screen_w      dd WINDOW_W
  screen_h      dd WINDOW_H

  left_y        dd 240
  right_y       dd 240

  ball_x        dd 394
  ball_y        dd 294
  ball_vx       dd 5
  ball_vy       dd 4

  key_up        dd 0
  key_down      dd 0

  wc            WNDCLASS
  msg           MSG
  ps            PAINTSTRUCT
  client_rc     RECT

section '.code' code readable executable

proc clamp_paddles
  ; Left paddle clamp
  mov eax,[left_y]
  cmp eax,0
  jge .left_top_ok
  mov [left_y],0
.left_top_ok:
  mov eax,[screen_h]
  sub eax,PADDLE_H
  mov edx,[left_y]
  cmp edx,eax
  jle .left_bottom_ok
  mov [left_y],eax
.left_bottom_ok:

  ; Right paddle clamp
  mov eax,[right_y]
  cmp eax,0
  jge .right_top_ok
  mov [right_y],0
.right_top_ok:
  mov eax,[screen_h]
  sub eax,PADDLE_H
  mov edx,[right_y]
  cmp edx,eax
  jle .done
  mov [right_y],eax
.done:
  ret
endp

proc reset_ball, dir
  mov eax,[screen_w]
  sub eax,BALL_SIZE
  shr eax,1
  mov [ball_x],eax

  mov eax,[screen_h]
  sub eax,BALL_SIZE
  shr eax,1
  mov [ball_y],eax

  mov eax,[dir]
  imul eax,5
  mov [ball_vx],eax
  mov [ball_vy],4
  ret
endp

proc update_game
  ; Player movement (left paddle)
  cmp [key_up],0
  je .skip_up
  sub [left_y],PADDLE_SPEED
.skip_up:
  cmp [key_down],0
  je .skip_down
  add [left_y],PADDLE_SPEED
.skip_down:

  ; Simple AI (right paddle follows ball)
  mov eax,[ball_y]
  add eax,BALL_SIZE/2
  mov edx,[right_y]
  add edx,PADDLE_H/2
  cmp eax,edx
  jle .ai_up
  add [right_y],6
  jmp .ai_done
.ai_up:
  sub [right_y],6
.ai_done:

  call clamp_paddles

  ; Move ball
  mov eax,[ball_x]
  add eax,[ball_vx]
  mov [ball_x],eax

  mov eax,[ball_y]
  add eax,[ball_vy]
  mov [ball_y],eax

  ; Top/bottom wall collision
  mov eax,[ball_y]
  cmp eax,0
  jge .check_bottom
  mov [ball_y],0
  mov eax,[ball_vy]
  neg eax
  mov [ball_vy],eax
.check_bottom:
  mov eax,[screen_h]
  sub eax,BALL_SIZE
  mov edx,[ball_y]
  cmp edx,eax
  jle .check_left_paddle
  mov [ball_y],eax
  mov eax,[ball_vy]
  neg eax
  mov [ball_vy],eax

.check_left_paddle:
  ; Collision with left paddle when moving left
  mov eax,[ball_vx]
  cmp eax,0
  jge .check_right_paddle

  mov eax,[ball_x]
  cmp eax,PADDLE_MARGIN + PADDLE_W
  jg .check_right_paddle

  mov ecx,[ball_y]
  add ecx,BALL_SIZE
  mov edx,[left_y]
  cmp ecx,edx
  jle .check_score_left

  mov ecx,[left_y]
  add ecx,PADDLE_H
  mov edx,[ball_y]
  cmp edx,ecx
  jge .check_score_left

  mov dword [ball_x],PADDLE_MARGIN + PADDLE_W
  mov eax,[ball_vx]
  neg eax
  mov [ball_vx],eax

.check_right_paddle:
  ; Collision with right paddle when moving right
  mov eax,[ball_vx]
  cmp eax,0
  jle .check_score_left

  mov eax,[screen_w]
  sub eax,PADDLE_MARGIN + PADDLE_W + BALL_SIZE
  mov edx,[ball_x]
  cmp edx,eax
  jl .check_score_left

  mov ecx,[ball_y]
  add ecx,BALL_SIZE
  mov edx,[right_y]
  cmp ecx,edx
  jle .check_score_left

  mov ecx,[right_y]
  add ecx,PADDLE_H
  mov edx,[ball_y]
  cmp edx,ecx
  jge .check_score_left

  mov [ball_x],eax
  mov eax,[ball_vx]
  neg eax
  mov [ball_vx],eax

.check_score_left:
  ; Ball leaves left side -> reset toward right
  mov eax,[ball_x]
  cmp eax,0
  jge .check_score_right
  stdcall reset_ball, 1
  jmp .done

.check_score_right:
  ; Ball leaves right side -> reset toward left
  mov eax,[screen_w]
  sub eax,BALL_SIZE
  mov edx,[ball_x]
  cmp edx,eax
  jle .done
  stdcall reset_ball, -1

.done:
  ret
endp

proc draw_game, hdc
  ; Clear background
  invoke PatBlt, [hdc], 0, 0, [screen_w], [screen_h], BLACKNESS

  ; Left paddle
  invoke PatBlt, [hdc], PADDLE_MARGIN, [left_y], PADDLE_W, PADDLE_H, WHITENESS

  ; Right paddle
  mov eax,[screen_w]
  sub eax,PADDLE_MARGIN + PADDLE_W
  invoke PatBlt, [hdc], eax, [right_y], PADDLE_W, PADDLE_H, WHITENESS

  ; Ball
  invoke PatBlt, [hdc], [ball_x], [ball_y], BALL_SIZE, BALL_SIZE, WHITENESS

  ret
endp

proc WndProc, hwnd, wmsg, wparam, lparam
  cmp [wmsg], WM_CREATE
  je .wmcreate
  cmp [wmsg], WM_SIZE
  je .wmsize
  cmp [wmsg], WM_TIMER
  je .wmtimer
  cmp [wmsg], WM_KEYDOWN
  je .wmkeydown
  cmp [wmsg], WM_KEYUP
  je .wmkeyup
  cmp [wmsg], WM_PAINT
  je .wmpaint
  cmp [wmsg], WM_DESTROY
  je .wmdestroy

.defwnd:
  invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
  ret

.wmcreate:
  invoke SetTimer, [hwnd], 1, 16, 0
  xor eax,eax
  ret

.wmsize:
  mov eax,[lparam]
  and eax,0FFFFh
  mov [screen_w],eax

  mov eax,[lparam]
  shr eax,16
  and eax,0FFFFh
  mov [screen_h],eax

  call clamp_paddles
  xor eax,eax
  ret

.wmtimer:
  call update_game
  invoke InvalidateRect, [hwnd], 0, FALSE
  xor eax,eax
  ret

.wmkeydown:
  cmp [wparam], VK_UP
  jne .check_down_press
  mov [key_up],1
  xor eax,eax
  ret
.check_down_press:
  cmp [wparam], VK_DOWN
  jne .defwnd
  mov [key_down],1
  xor eax,eax
  ret

.wmkeyup:
  cmp [wparam], VK_UP
  jne .check_down_release
  mov [key_up],0
  xor eax,eax
  ret
.check_down_release:
  cmp [wparam], VK_DOWN
  jne .defwnd
  mov [key_down],0
  xor eax,eax
  ret

.wmpaint:
  invoke BeginPaint, [hwnd], ps
  invoke draw_game, eax
  invoke EndPaint, [hwnd], ps
  xor eax,eax
  ret

.wmdestroy:
  invoke KillTimer, [hwnd], 1
  invoke PostQuitMessage, 0
  xor eax,eax
  ret
endp

start:
  invoke GetModuleHandle, 0
  mov ebx,eax

  mov [wc.style], CS_HREDRAW + CS_VREDRAW
  mov [wc.lpfnWndProc], WndProc
  mov [wc.cbClsExtra], 0
  mov [wc.cbWndExtra], 0
  mov [wc.hInstance], ebx
  invoke LoadIcon, 0, IDI_APPLICATION
  mov [wc.hIcon], eax
  invoke LoadCursor, 0, IDC_ARROW
  mov [wc.hCursor], eax
  mov [wc.hbrBackground], COLOR_WINDOW + 1
  mov [wc.lpszMenuName], 0
  mov [wc.lpszClassName], class_name

  invoke RegisterClass, wc

  invoke CreateWindowEx, 0, class_name, window_title, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, WINDOW_W, WINDOW_H, NULL, NULL, ebx, NULL

  mov [hwnd_main], eax

  invoke ShowWindow, eax, SW_SHOWNORMAL
  invoke UpdateWindow, eax

.msg_loop:
  invoke GetMessage, msg, NULL, 0, 0
  cmp eax,0
  jle .exit
  invoke TranslateMessage, msg
  invoke DispatchMessage, msg
  jmp .msg_loop

.exit:
  invoke ExitProcess, [msg.wParam]

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL', \
          user32,   'USER32.DLL',   \
          gdi32,    'GDI32.DLL'

  import kernel32, \
         GetModuleHandle, 'GetModuleHandleA', \
         ExitProcess,     'ExitProcess'

  import user32, \
         RegisterClass,   'RegisterClassA', \
         CreateWindowEx,  'CreateWindowExA', \
         DefWindowProc,   'DefWindowProcA', \
         ShowWindow,      'ShowWindow', \
         UpdateWindow,    'UpdateWindow', \
         GetMessage,      'GetMessageA', \
         TranslateMessage,'TranslateMessage', \
         DispatchMessage, 'DispatchMessageA', \
         PostQuitMessage, 'PostQuitMessage', \
         LoadCursor,      'LoadCursorA', \
         LoadIcon,        'LoadIconA', \
         BeginPaint,      'BeginPaint', \
         EndPaint,        'EndPaint', \
         InvalidateRect,  'InvalidateRect', \
         SetTimer,        'SetTimer', \
         KillTimer,       'KillTimer'

  import gdi32, \
         PatBlt,          'PatBlt'
