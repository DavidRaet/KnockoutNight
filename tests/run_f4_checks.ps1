param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
$rootPath = Split-Path $PSScriptRoot -Parent
& "$PSScriptRoot/run_f3_checks.ps1" -Tools $Tools
$files = @('ReplicatedStorage/F4Config.luau', 'ReplicatedStorage/F4Rules.luau', 'ServerScriptService/F4Admins.luau', 'ServerScriptService/F4Match.luau', 'StarterPlayerScripts/F3Client.luau', 'tests/F4Rules.spec.luau', 'tests/F4Match.server.luau', 'tests/F4Match.client.luau')
Push-Location $rootPath
try {
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F4 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F4 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F4 compilation failed: $file" }
    }
    $rules = Get-Content -LiteralPath 'ReplicatedStorage/F4Rules.luau' -Raw
    $spec = Get-Content -LiteralPath 'tests/F4Rules.spec.luau' -Raw
    $runner = "local Rules=(function()`n$rules`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Rules)`nassert(result.passed, 'F4 rules failed')`nprint('PASS: '..result.checks..' F4 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f4-rules-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F4 deterministic tests failed' }
} finally { Pop-Location }
