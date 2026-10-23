param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_f6_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ReplicatedStorage/F7Paddles.luau') + @(Get-ChildItem tests -Filter F7*.luau -File | ForEach-Object { $_.FullName })
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F7 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F7 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F7 compilation failed: $file" }
    }
    $config = Get-Content ReplicatedStorage/F2Config.luau -Raw
    $paddles = Get-Content ReplicatedStorage/F7Paddles.luau -Raw
    $fist = Get-Content ReplicatedStorage/F2SpringFist.luau -Raw
    $spec = Get-Content tests/F7Paddles.spec.luau -Raw
    $runner = "local Vector3 = {new=function(x,y,z) return {X=x,Y=y,Z=z} end}`nlocal Config=(function()`n$config`nend)()`nlocal Paddles=(function()`n$paddles`nend)()`nlocal Fist=(function()`n$fist`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Fist,Paddles,Config)`nassert(result.passed, 'F7 rules failed')`nprint('PASS: '..result.checks..' F7 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f7-paddles-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F7 deterministic tests failed' }
} finally { Pop-Location }
