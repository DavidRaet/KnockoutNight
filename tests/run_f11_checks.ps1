param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_f10_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ReplicatedStorage/F11Slam.luau', 'ServerScriptService/F1Prototype.server.luau') + @(Get-ChildItem tests -Filter F11*.luau -File | ForEach-Object { $_.FullName })
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F11 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F11 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F11 compilation failed: $file" }
    }
    $config = Get-Content ReplicatedStorage/F2Config.luau -Raw
    $slam = Get-Content ReplicatedStorage/F11Slam.luau -Raw
    $fist = Get-Content ReplicatedStorage/F2SpringFist.luau -Raw
    $spec = Get-Content tests/F11Slam.spec.luau -Raw
    $runner = "local Vector3 = {new=function(x,y,z) return {X=x,Y=y,Z=z} end}`nlocal Config=(function()`n$config`nend)()`nlocal Slam=(function()`n$slam`nend)()`nlocal Fist=(function()`n$fist`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Slam,Fist,Config)`nassert(result.passed, 'F11 Slam rules failed')`nprint('PASS: '..result.checks..' F11 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f11-slam-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F11 deterministic tests failed' }
    & "$PSScriptRoot/build_f9_harness.ps1"
} finally { Pop-Location }
