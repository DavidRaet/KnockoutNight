param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_f7_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ReplicatedStorage/F8Gust.luau') + @(Get-ChildItem tests -Filter F8*.luau -File | ForEach-Object { $_.FullName })
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'F8 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'F8 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "F8 compilation failed: $file" }
    }
    $config = Get-Content ReplicatedStorage/F2Config.luau -Raw
    $gust = Get-Content ReplicatedStorage/F8Gust.luau -Raw
    $fist = Get-Content ReplicatedStorage/F2SpringFist.luau -Raw
    $spec = Get-Content tests/F8Gust.spec.luau -Raw
    $runner = "local Vector3 = {new=function(x,y,z) return {X=x,Y=y,Z=z} end}`nlocal Config=(function()`n$config`nend)()`nlocal Gust=(function()`n$gust`nend)()`nlocal Fist=(function()`n$fist`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Gust,Fist,Config)`nassert(result.passed, 'F8 Gust rules failed')`nprint('PASS: '..result.checks..' F8 deterministic checks')"
    $runnerPath = Join-Path $Tools 'f8-gust-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'F8 deterministic tests failed' }
} finally { Pop-Location }
