param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_f5_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ReplicatedStorage/F6Hammer.luau', 'ReplicatedStorage/F2Weapons.luau', 'tests/F6Hammer.spec.luau', 'tests/F6Contact.spec.luau', 'tests/F6Combat.server.luau', 'tests/F6Combat.client.luau', 'tests/F6Knockback.server.luau')
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F6 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F6 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F6 compilation failed: $file" }
    }
    $config = Get-Content ReplicatedStorage/F2Config.luau -Raw
    $hammer = Get-Content ReplicatedStorage/F6Hammer.luau -Raw
    $fist = Get-Content ReplicatedStorage/F2SpringFist.luau -Raw
    $spec = Get-Content tests/F6Hammer.spec.luau -Raw
    $runner = "local Vector3 = {new=function(x,y,z) return {X=x,Y=y,Z=z} end}`nlocal Config=(function()`n$config`nend)()`nlocal Hammer=(function()`n$hammer`nend)()`nlocal Fist=(function()`n$fist`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Fist,Hammer,Config)`nassert(result.passed, 'F6 rules failed')`nprint('PASS: '..result.checks..' F6 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f6-hammer-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F6 deterministic tests failed' }
} finally { Pop-Location }
