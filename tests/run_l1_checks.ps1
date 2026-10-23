param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_f11_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ReplicatedStorage/F1Config.luau', 'ServerScriptService/L1SkyBridges.luau', 'ServerScriptService/F1Prototype.server.luau', 'ServerScriptService/F3Lives.luau', 'ServerScriptService/F2Contact.luau', 'ServerScriptService/F2Combat.luau') + @(Get-ChildItem tests -Filter L1*.luau -File | ForEach-Object { $_.FullName })
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'L1 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'L1 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "L1 compilation failed: $file" }
    }
    $source = Get-Content ServerScriptService/F3Lives.luau -Raw
    $source = $source.Replace('local Players = game:GetService("Players")', 'local Players = testPlayers')
    $source = $source.Replace('local Combat = require(script.Parent.F2Combat)', 'local Combat = testCombat')
    $source = $source.Replace('remote.Name, remote.Parent = "F3Knockouts", Storage', 'remote.Name, remote.Parent = "L1FixtureKnockouts", Storage')
    $harnessPath = Join-Path $rootPath '.tools/L1HarnessLives.luau'
    [IO.File]::WriteAllText($harnessPath, "return function(testPlayers, testCombat)`n$source`nend`n")
    & "$Tools/stylua/stylua.exe" $harnessPath
    & "$Tools/selene/selene.exe" $harnessPath
    if ($LASTEXITCODE) { throw 'L1 lives harness lint failed' }
    & "$Tools/luau/luau-compile.exe" --null $harnessPath
    if ($LASTEXITCODE) { throw 'L1 lives harness compilation failed' }
} finally { Pop-Location }
