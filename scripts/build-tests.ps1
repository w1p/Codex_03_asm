param(
  [string]$Fasm = 'D:\fasm\fasm.exe'
)

$repoRoot = Split-Path $PSScriptRoot -Parent
$tests = @(
  @{ Name = 'pong'; Source = 'tests\test_pong.asm'; Output = 'tests\test_pong.exe' }
)

$failed = $false
foreach ($test in $tests) {
  $sourcePath = Join-Path $repoRoot $test.Source
  $outputPath = Join-Path $repoRoot $test.Output

  Write-Host "Building $($test.Name) tests..."
  & $Fasm $sourcePath $outputPath
  if ($LASTEXITCODE -ne 0) {
    $failed = $true
    break
  }
}

if ($failed) {
  exit 1
}

Write-Host 'All test executables built successfully.'
exit 0
