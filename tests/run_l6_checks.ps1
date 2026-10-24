param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_l4_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ServerScriptService/L5Flow.luau', 'ServerScriptService/L5Arenas.luau', 'StarterPlayerScripts/L5Client.luau', 'StarterPlayerScripts/F3Client.luau', 'tests/L5Flow.spec.luau', 'tests/L6Journey.spec.luau')
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'L5/L6 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'L5/L6 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "L5/L6 compilation failed: $file" }
    }
    $source = Get-Content ServerScriptService/L5Flow.luau -Raw
    $spec = Get-Content tests/L5Flow.spec.luau -Raw
    $runner = "local Flow=(function()`n$source`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Flow)`nassert(result.passed, 'L5/L6 flow checks failed')`nprint('PASS: '..result.checks..' L5/L6 flow checks')"
    $runnerPath = Join-Path $Tools 'l5-flow-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'L5/L6 flow tests failed' }
    $source = Get-Content .tools/L4HarnessLobby.luau -Raw
    $source = $source.Replace('"L4Fixture', '"L6Fixture')
    $source = $source.Replace('require(script.Parent.F3Lives), require(script.Parent.F4Match)', 'testPlayers.Lives, testPlayers.Match')
    $source = $source.Replace('requestRemote.OnServerEvent:Connect(', 'testPlayers.Request.Event:Connect(')
    $source = $source.Replace('requestRemote:FireClient(', 'testPlayers:Private(')
    [IO.File]::WriteAllText((Join-Path $rootPath '.tools/L6HarnessLobby.luau'), $source)
    $source = Get-Content ServerScriptService/F4Match.luau -Raw
    $source = $source.Replace('local Players = game:GetService("Players")', 'local Players = testPlayers')
    $source = $source.Replace('local Lives = require(script.Parent.F3Lives)', 'local Lives = testLives')
    $source = $source.Replace('local Combat = require(script.Parent.F2Combat)', 'local Combat = testCombat')
    $source = $source.Replace('require(script.Parent.F4Admins)', 'require(game.ServerScriptService.F4Admins)')
    $source = $source.Replace('workspace:GetServerTimeNow()', 'testPlayers.Now')
    foreach ($name in @('F4State','F4Return','F4Admin','F6WeaponChoice','F10AbilityChoice')) {
        $source = $source.Replace('"' + $name + '"', '"L6Fixture' + $name + '"')
    }
    [IO.File]::WriteAllText((Join-Path $rootPath '.tools/L6HarnessMatch.luau'), "return function(testPlayers, testLives, testCombat)`n$source`nend`n")
    $source = Get-Content .tools/L1HarnessLives.luau -Raw
    $source = $source.Replace('workspace:GetServerTimeNow()', 'testPlayers.Now').Replace('L1FixtureKnockouts','L6FixtureKnockouts')
    [IO.File]::WriteAllText((Join-Path $rootPath '.tools/L6HarnessLives.luau'), $source)
    foreach ($file in @('.tools/L6HarnessLobby.luau','.tools/L6HarnessMatch.luau','.tools/L6HarnessLives.luau')) {
        & "$Tools/stylua/stylua.exe" $file
        & "$Tools/selene/selene.exe" $file
        if ($LASTEXITCODE) { throw "L6 harness lint failed: $file" }
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "L6 harness compilation failed: $file" }
    }
} finally { Pop-Location }
