format PE console 4.0
entry test_start

define UNIT_TEST 1
include 'win32ax.inc'
include 'pong.asm'

section '.testdata' data readable writeable
  tests_passed dd 0
  tests_failed dd 0

section '.testcode' code readable executable

proc assert_mem_eq_imm, pMem, expected
  mov eax,[pMem]
  mov edx,[expected]
  cmp dword [eax],edx
  je .ok
  inc dword [tests_failed]
  ret
.ok:
  inc dword [tests_passed]
  ret
endp

proc test_clamp_bounds
  mov dword [left_y],-7
  mov dword [right_y],999
  call clamp_paddles

  stdcall assert_mem_eq_imm, left_y, 1
  stdcall assert_mem_eq_imm, right_y, H-PADDLE_H-1
  ret
endp

proc test_reset_ball
  mov dword [ball_x],1
  mov dword [ball_y],1
  mov dword [vx],77
  mov dword [vy],-4

  stdcall reset_ball, -1

  stdcall assert_mem_eq_imm, ball_x, 40
  stdcall assert_mem_eq_imm, ball_y, 12
  stdcall assert_mem_eq_imm, vx, -1
  stdcall assert_mem_eq_imm, vy, 1
  ret
endp

proc test_top_bounce
  mov dword [left_y],10
  mov dword [right_y],10
  mov dword [ball_x],20
  mov dword [ball_y],1
  mov dword [vx],0
  mov dword [vy],-1

  call update_game

  stdcall assert_mem_eq_imm, ball_y, 1
  stdcall assert_mem_eq_imm, vy, 1
  ret
endp

proc test_left_paddle_hit
  mov dword [left_y],10
  mov dword [right_y],10
  mov dword [ball_x],4
  mov dword [ball_y],11
  mov dword [vx],-1
  mov dword [vy],0

  call update_game

  stdcall assert_mem_eq_imm, vx, 1
  stdcall assert_mem_eq_imm, ball_x, 3
  ret
endp

proc test_left_miss_scores
  mov dword [left_y],10
  mov dword [right_y],10
  mov dword [ball_x],4
  mov dword [ball_y],1
  mov dword [vx],-1
  mov dword [vy],0

  call update_game

  stdcall assert_mem_eq_imm, ball_x, 40
  stdcall assert_mem_eq_imm, ball_y, 12
  stdcall assert_mem_eq_imm, vx, 1
  stdcall assert_mem_eq_imm, vy, 1
  ret
endp

proc test_build_frame_ball_char
  ; Keep paddles away from target cell to avoid overlap.
  mov dword [left_y],1
  mov dword [right_y],1
  mov dword [ball_x],10
  mov dword [ball_y],5

  call build_frame

  ; ESC[H prefix
  cmp byte [frame_buf],27
  je .p0_ok
  inc dword [tests_failed]
  jmp .p1
.p0_ok:
  inc dword [tests_passed]
.p1:
  cmp byte [frame_buf+1],'['
  je .p1_ok
  inc dword [tests_failed]
  jmp .p2
.p1_ok:
  inc dword [tests_passed]
.p2:
  cmp byte [frame_buf+2],'H'
  je .p2_ok
  inc dword [tests_failed]
  jmp .ball
.p2_ok:
  inc dword [tests_passed]

.ball:
  ; offset = 3 + (y * (W+2)) + x = 3 + (5*82) + 10 = 423
  cmp byte [frame_buf+423],'O'
  je .ball_ok
  inc dword [tests_failed]
  ret
.ball_ok:
  inc dword [tests_passed]
  ret
endp

test_start:
  call test_clamp_bounds
  call test_reset_ball
  call test_top_bounce
  call test_left_paddle_hit
  call test_left_miss_scores
  call test_build_frame_ball_char

  cmp dword [tests_failed],0
  jne .fail
  invoke ExitProcess, 0
.fail:
  invoke ExitProcess, 1

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL'

  import kernel32, \
         ExitProcess,   'ExitProcess'
