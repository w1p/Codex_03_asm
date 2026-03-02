format PE console 4.0
entry test_start

UNIT_TEST = 1
include 'pong.asm'

section '.testdata' data readable writeable
  tests_passed dd 0
  tests_failed dd 0

section '.testcode' code readable executable

macro ASSERT_MEM_EQ mem, expected
{
  local .ok, .done
  mov eax,[mem]
  cmp eax,expected
  je .ok
  inc dword [tests_failed]
  jmp .done
.ok:
  inc dword [tests_passed]
.done:
}
proc test_clamp_bounds
  mov dword [left_y],-7
  mov dword [right_y],999
  call clamp_paddles

  ASSERT_MEM_EQ left_y, 1
  ASSERT_MEM_EQ right_y, H-PADDLE_H-1
  ret
endp

proc test_reset_ball
  mov dword [ball_x],1
  mov dword [ball_y],1
  mov dword [vx],77
  mov dword [vy],-4
  mov dword [ball_accum_ms],55

  stdcall reset_ball, 0FFFFFFFFh

  ASSERT_MEM_EQ ball_x, 40
  ASSERT_MEM_EQ ball_y, 12
  ASSERT_MEM_EQ vx, 0FFFFFFFFh
  ASSERT_MEM_EQ vy, 1
  ASSERT_MEM_EQ ball_accum_ms, 0
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

  ASSERT_MEM_EQ ball_y, 1
  ASSERT_MEM_EQ vy, 1
  ASSERT_MEM_EQ ball_accum_ms, 0
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

  ASSERT_MEM_EQ vx, 1
  ASSERT_MEM_EQ ball_x, 3
  ret
endp

proc test_left_miss_scores
  mov dword [left_score],0
  mov dword [right_score],0
  mov dword [left_y],10
  mov dword [right_y],10
  mov dword [ball_x],4
  mov dword [ball_y],1
  mov dword [vx],-1
  mov dword [vy],0

  call update_game

  ASSERT_MEM_EQ ball_x, 40
  ASSERT_MEM_EQ ball_y, 12
  ASSERT_MEM_EQ vx, 1
  ASSERT_MEM_EQ vy, 1
  ASSERT_MEM_EQ ball_accum_ms, 0
  ASSERT_MEM_EQ right_score, 1
  ASSERT_MEM_EQ left_score, 0
  ret
endp

proc test_build_frame_ball_char
  ; Keep paddles away from target cell to avoid overlap.
  mov dword [left_y],1
  mov dword [right_y],1
  mov dword [ball_x],10
  mov dword [ball_y],5

  call build_frame

  ; ESC[2;1H prefix
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
  cmp byte [frame_buf+2],'2'
  je .p2_ok
  inc dword [tests_failed]
  jmp .p3
.p2_ok:
  inc dword [tests_passed]

.p3:
  cmp byte [frame_buf+3],';'
  je .p3_ok
  inc dword [tests_failed]
  jmp .p4
.p3_ok:
  inc dword [tests_passed]
.p4:
  cmp byte [frame_buf+4],'1'
  je .p4_ok
  inc dword [tests_failed]
  jmp .p5
.p4_ok:
  inc dword [tests_passed]
.p5:
  cmp byte [frame_buf+5],'H'
  je .p5_ok
  inc dword [tests_failed]
  jmp .ball
.p5_ok:
  inc dword [tests_passed]

.ball:
  ; offset = 6 + (y * (W+2)) + x = 6 + (5*82) + 10 = 426
  cmp byte [frame_buf+426],'O'
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
