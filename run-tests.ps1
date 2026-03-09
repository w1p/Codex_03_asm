& "$PSScriptRoot\tests.exe"
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "Tests passed."
} else {
    Write-Host "Tests failed with exit code $exitCode."
}

exit $exitCode