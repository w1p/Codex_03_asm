format PE console 4.0
entry test_start

UNIT_TEST = 1
include '..\src\pong.asm'

section '.tdata' data readable writeable
  tests_passed dd 0
  tests_failed dd 0
  fail_fmt db 'FAIL: %s (actual=%d expected=%d)',13,10,0
  summary_fmt db 'Tests passed: %d, failed: %d',13,10,0

  msg_test_clamp_left_y db 'pong:test_clamp_bounds left_y clamp',0
  msg_test_clamp_right_y db 'pong:test_clamp_bounds right_y clamp',0
  msg_test_reset_ball_x db 'pong:test_reset_ball ball_x reset',0
  msg_test_reset_ball_y db 'pong:test_reset_ball ball_y reset',0
  msg_test_reset_vx db 'pong:test_reset_ball vx reset',0
  msg_test_reset_vy db 'pong:test_reset_ball vy reset',0
  msg_test_reset_accum db 'pong:test_reset_ball accumulator reset',0
  msg_test_top_bounce_y db 'pong:test_top_bounce ball_y stays in bounds',0
  msg_test_top_bounce_vy db 'pong:test_top_bounce vy flips after top bounce',0
  msg_test_top_bounce_accum db 'pong:test_top_bounce accumulator consumes one step',0
  msg_test_left_hit_vx db 'pong:test_left_paddle_hit vx flips on paddle hit',0
  msg_test_left_hit_x db 'pong:test_left_paddle_hit ball_x stays at collision cell',0
  msg_test_left_miss_x db 'pong:test_left_miss_scores ball_x resets after score',0
  msg_test_left_miss_y db 'pong:test_left_miss_scores ball_y resets after score',0
  msg_test_left_miss_vx db 'pong:test_left_miss_scores vx serves toward scorer',0
  msg_test_left_miss_vy db 'pong:test_left_miss_scores vy resets after score',0
  msg_test_left_miss_accum db 'pong:test_left_miss_scores accumulator resets after score',0
  msg_test_left_miss_right_score db 'pong:test_left_miss_scores right score increments',0
  msg_test_left_miss_left_score db 'pong:test_left_miss_scores left score unchanged',0
  msg_test_frame_prefix_0 db 'pong:test_build_frame_ball_char frame prefix byte 0',0
  msg_test_frame_prefix_1 db 'pong:test_build_frame_ball_char frame prefix byte 1',0
  msg_test_frame_prefix_2 db 'pong:test_build_frame_ball_char frame prefix byte 2',0
  msg_test_frame_prefix_3 db 'pong:test_build_frame_ball_char frame prefix byte 3',0
  msg_test_frame_prefix_4 db 'pong:test_build_frame_ball_char frame prefix byte 4',0
  msg_test_frame_prefix_5 db 'pong:test_build_frame_ball_char frame prefix byte 5',0
  msg_test_frame_ball db 'pong:test_build_frame_ball_char ball glyph rendered',0

section '.tcode' code readable executable
include 'test_common.inc'

proc test_clamp_bounds
  mov dword [left_y],-7
  mov dword [right_y],999
  call clamp_paddles

  ASSERT_MEM_EQ msg_test_clamp_left_y, left_y, 1
  ASSERT_MEM_EQ msg_test_clamp_right_y, right_y, H-PADDLE_H-1
  ret
endp

proc test_reset_ball
  mov dword [ball_x],1
  mov dword [ball_y],1
  mov dword [vx],77
  mov dword [vy],-4
  mov dword [ball_accum_ms],55

  stdcall reset_ball, 0FFFFFFFFh

  ASSERT_MEM_EQ msg_test_reset_ball_x, ball_x, 40
  ASSERT_MEM_EQ msg_test_reset_ball_y, ball_y, 12
  ASSERT_MEM_EQ msg_test_reset_vx, vx, 0FFFFFFFFh
  ASSERT_MEM_EQ msg_test_reset_vy, vy, 1
  ASSERT_MEM_EQ msg_test_reset_accum, ball_accum_ms, 0
  ret
endp

proc test_top_bounce
  mov dword [left_y],10
  mov dword [right_y],10
  mov dword [ball_x],20
  mov dword [ball_y],1
  mov dword [vx],0
  mov dword [vy],-1
  mov dword [ball_accum_ms],67

  call update_game

  ASSERT_MEM_EQ msg_test_top_bounce_y, ball_y, 1
  ASSERT_MEM_EQ msg_test_top_bounce_vy, vy, 1
  ASSERT_MEM_EQ msg_test_top_bounce_accum, ball_accum_ms, 0
  ret
endp

proc test_left_paddle_hit
  mov dword [left_y],10
  mov dword [right_y],10
  mov dword [ball_x],4
  mov dword [ball_y],11
  mov dword [vx],-1
  mov dword [vy],0
  mov dword [ball_accum_ms],67

  call update_game

  ASSERT_MEM_EQ msg_test_left_hit_vx, vx, 1
  ASSERT_MEM_EQ msg_test_left_hit_x, ball_x, 3
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
  mov dword [ball_accum_ms],67

  call update_game

  ASSERT_MEM_EQ msg_test_left_miss_x, ball_x, 40
  ASSERT_MEM_EQ msg_test_left_miss_y, ball_y, 12
  ASSERT_MEM_EQ msg_test_left_miss_vx, vx, 1
  ASSERT_MEM_EQ msg_test_left_miss_vy, vy, 1
  ASSERT_MEM_EQ msg_test_left_miss_accum, ball_accum_ms, 0
  ASSERT_MEM_EQ msg_test_left_miss_right_score, right_score, 1
  ASSERT_MEM_EQ msg_test_left_miss_left_score, left_score, 0
  ret
endp

proc test_build_frame_ball_char
  mov dword [left_y],1
  mov dword [right_y],1
  mov dword [ball_x],10
  mov dword [ball_y],5

  call build_frame

  ASSERT_BYTE_EQ msg_test_frame_prefix_0, frame_buf, 27
  ASSERT_BYTE_EQ msg_test_frame_prefix_1, frame_buf+1, '['
  ASSERT_BYTE_EQ msg_test_frame_prefix_2, frame_buf+2, '2'
  ASSERT_BYTE_EQ msg_test_frame_prefix_3, frame_buf+3, ';'
  ASSERT_BYTE_EQ msg_test_frame_prefix_4, frame_buf+4, '1'
  ASSERT_BYTE_EQ msg_test_frame_prefix_5, frame_buf+5, 'H'
  ASSERT_BYTE_EQ msg_test_frame_ball, frame_buf+426, 'O'
  ret
endp

test_start:
  call test_clamp_bounds
  call test_reset_ball
  call test_top_bounce
  call test_left_paddle_hit
  call test_left_miss_scores
  call test_build_frame_ball_char

  cinvoke printf, summary_fmt, [tests_passed], [tests_failed]

  cmp dword [tests_failed],0
  jne .fail
  invoke ExitProcess, 0
.fail:
  invoke ExitProcess, 1

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL', \
          msvcrt,   'MSVCRT.DLL'

  import kernel32, \
         ExitProcess, 'ExitProcess'

  import msvcrt, \
         printf, 'printf'
