proc report_assert_fail, msg, actual, expected
  cinvoke printf, fail_fmt, [msg], [actual], [expected]
  ret
endp

macro ASSERT_MEM_EQ msg, mem, expected
{
  local .ok, .done
  mov eax,[mem]
  cmp eax,expected
  je .ok
  inc dword [tests_failed]
  push expected
  push eax
  push msg
  call report_assert_fail
  jmp .done
.ok:
  inc dword [tests_passed]
.done:
}

macro ASSERT_BYTE_EQ msg, mem, expected
{
  local .ok, .done
  movzx eax,byte [mem]
  cmp eax,expected
  je .ok
  inc dword [tests_failed]
  push expected
  push eax
  push msg
  call report_assert_fail
  jmp .done
.ok:
  inc dword [tests_passed]
.done:
}
