$repoRoot = Split-Path $PSScriptRoot -Parent
$tests = @(
  @{ Name = 'pong'; Executable = 'tests\test_pong.exe' }
)

$failed = $false
foreach ($test in $tests) {
  $exePath = Join-Path $repoRoot $test.Executable
  Write-Host "== Running $($test.Name) tests =="
  & $exePath
  if ($LASTEXITCODE -ne 0) {
    $failed = $true
    Write-Host "Test suite '$($test.Name)' failed with exit code $LASTEXITCODE."
  } else {
    Write-Host "Test suite '$($test.Name)' passed."
  }
}

if ($failed) {
  exit 1
}

Write-Host 'All test suites passed.'
exit 0
