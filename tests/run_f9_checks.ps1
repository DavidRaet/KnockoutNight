param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_f8_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ReplicatedStorage/F9Magnet.luau') + @(Get-ChildItem tests -Filter F9*.luau -File | ForEach-Object { $_.FullName })
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F9 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F9 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F9 compilation failed: $file" }
    }
    $config = Get-Content ReplicatedStorage/F2Config.luau -Raw
    $magnet = Get-Content ReplicatedStorage/F9Magnet.luau -Raw
    $fist = Get-Content ReplicatedStorage/F2SpringFist.luau -Raw
    $spec = Get-Content tests/F9Magnet.spec.luau -Raw
    $runner = "local Vector3 = {new=function(x,y,z) return {X=x,Y=y,Z=z} end}`nlocal Config=(function()`n$config`nend)()`nlocal Magnet=(function()`n$magnet`nend)()`nlocal Fist=(function()`n$fist`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Magnet,Fist,Config)`nassert(result.passed, 'F9 Magnet rules failed')`nprint('PASS: '..result.checks..' F9 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f9-magnet-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F9 deterministic tests failed' }
} finally { Pop-Location }
