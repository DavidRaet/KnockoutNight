param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
$rootPath = Split-Path $PSScriptRoot -Parent
& "$PSScriptRoot/run_f2_checks.ps1" -Tools $Tools
$files = @('ReplicatedStorage/F3Config.luau', 'ReplicatedStorage/F3Rules.luau', 'ServerScriptService/F1Prototype.server.luau', 'ServerScriptService/F3Lives.luau', 'StarterPlayerScripts/F3Client.luau', 'tests/F3Rules.spec.luau', 'tests/F3Lives.server.luau', 'tests/F3Lives.client.luau')
Push-Location $rootPath
try {
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F3 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F3 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F3 compilation failed: $file" }
    }
    $rules = Get-Content -LiteralPath 'ReplicatedStorage/F3Rules.luau' -Raw
    $spec = Get-Content -LiteralPath 'tests/F3Rules.spec.luau' -Raw
    $runner = "local Rules=(function()`n$rules`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Rules)`nassert(result.passed, 'F3 rules failed')`nprint('PASS: '..result.checks..' F3 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f3-rules-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F3 deterministic tests failed' }
} finally { Pop-Location }
