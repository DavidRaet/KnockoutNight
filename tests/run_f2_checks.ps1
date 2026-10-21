param([string]$Tools = "$env:TEMP\KnockoutNight-F2Checks")
$ErrorActionPreference = 'Stop'
$rootPath = Split-Path $PSScriptRoot -Parent
$files = @('ReplicatedStorage/F2Config.luau', 'ReplicatedStorage/F2SpringFist.luau', 'ServerScriptService/F2Contact.luau', 'ServerScriptService/F2Combat.luau', 'ServerScriptService/F2Prototype.server.luau', 'StarterPlayerScripts/F2Client.luau', 'StarterPlayerScripts/F1Controller.local.luau', 'tests/F2SpringFist.spec.luau', 'tests/F2Contact.spec.luau', 'tests/F2Combat.server.luau', 'tests/F2Combat.client.luau', 'tests/F1Multiplayer.server.luau')
Push-Location $rootPath
try {
    & "$Tools\stylua\stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'Spring Fist formatting failed' }
    & "$Tools\selene\selene.exe" @files
    if ($LASTEXITCODE) { throw 'Spring Fist lint failed' }
    foreach ($file in $files) {
        & "$Tools\luau\luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "Spring Fist compilation failed: $file" }
    }
    # Config's only engine constructor is irrelevant to these pure timeline/ordering checks.
    $configSource = Get-Content -LiteralPath 'ReplicatedStorage/F2Config.luau' -Raw
    $fistSource = Get-Content -LiteralPath 'ReplicatedStorage/F2SpringFist.luau' -Raw
    $testSource = Get-Content -LiteralPath 'tests/F2SpringFist.spec.luau' -Raw
    $runner = "local Vector3 = {new=function(x,y,z) return {X=x,Y=y,Z=z} end}`nlocal Config=(function()`n$configSource`nend)()`nlocal Fist=(function()`n$fistSource`nend)()`nlocal run=(function()`n$testSource`nend)()`nlocal result=run(Fist,Config)`nassert(result.passed, 'Spring Fist pure checks failed')`nprint('PASS: '..result.checks..' Spring Fist deterministic checks')"
    $runnerPath = Join-Path $Tools 'spring-fist-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools\luau\luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'Spring Fist deterministic tests failed' }
} finally { Pop-Location }
