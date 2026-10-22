param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_f4_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('tests/F5Rules.spec.luau', 'tests/F5Match.server.luau', 'tests/F5Match.client.luau')
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F5 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F5 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F5 compilation failed: $file" }
    }
    $rules = Get-Content ReplicatedStorage/F4Rules.luau -Raw
    $spec = Get-Content tests/F5Rules.spec.luau -Raw
    $runner = "local Rules=(function()`n$rules`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Rules)`nassert(result.passed, 'F5 rules failed')`nprint('PASS: '..result.checks..' F5 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f5-rules-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F5 deterministic tests failed' }
} finally { Pop-Location }
