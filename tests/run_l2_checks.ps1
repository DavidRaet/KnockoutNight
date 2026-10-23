param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_l1_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ServerScriptService/L2Dungeon.luau', 'tests/L2Dungeon.spec.luau')
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'L2 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'L2 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "L2 compilation failed: $file" }
    }
} finally { Pop-Location }
