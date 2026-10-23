param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_f9_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ReplicatedStorage/F10Bounce.luau') + @(Get-ChildItem tests -Filter F10*.luau -File | ForEach-Object { $_.FullName })
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F10 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F10 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F10 compilation failed: $file" }
    }
    $bounce = Get-Content ReplicatedStorage/F10Bounce.luau -Raw
    $spec = Get-Content tests/F10Bounce.spec.luau -Raw
    $runner = "local Bounce=(function()`n$bounce`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Bounce)`nassert(result.passed, 'F10 Bounce rules failed')`nprint('PASS: '..result.checks..' F10 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f10-bounce-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F10 deterministic tests failed' }
} finally { Pop-Location }
