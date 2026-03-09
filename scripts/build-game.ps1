param(
  [string]$Fasm = 'D:\fasm\fasm.exe'
)

$repoRoot = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repoRoot 'src\pong_game.asm'
$output = Join-Path $repoRoot 'pong.exe'

& $Fasm $source $output
exit $LASTEXITCODE
