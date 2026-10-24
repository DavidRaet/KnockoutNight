param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_l3_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ServerScriptService/L4Dispatch.luau', 'tests/L4Dispatch.spec.luau', 'tests/L4Lobby.spec.luau', 'StarterPlayerScripts/F1Controller.local.luau')
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'L4 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'L4 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "L4 compilation failed: $file" }
    }
    $source = Get-Content ServerScriptService/L4Dispatch.luau -Raw
    $spec = Get-Content tests/L4Dispatch.spec.luau -Raw
    $runner = "local Dispatch=(function()`n$source`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Dispatch)`nassert(result.passed, 'L4 dispatch checks failed')`nprint('PASS: '..result.checks..' L4 dispatch checks')"
    $runnerPath = Join-Path $Tools 'l4-dispatch-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'L4 dispatch tests failed' }
    $source = Get-Content ServerScriptService/L3Lobby.luau -Raw
    $source = $source.Replace('local Players = game:GetService("Players")', 'local Players = testPlayers')
    $source = $source.Replace('local RunService = game:GetService("RunService")', 'local RunService = testPlayers.RunService')
    $source = $source.Replace('workspace:GetServerTimeNow()', 'testPlayers.Now')
    $source = $source.Replace('playRemote.OnServerEvent:Connect(play)', 'testPlayers.Play.Event:Connect(play)')
    $source = $source.Replace('returnRemote.OnServerEvent:Connect(', 'testPlayers.Return.Event:Connect(')
    $source = $source.Replace('require(script.Parent.L3Queue)', 'require(game.ServerScriptService.L3Queue)')
    $source = $source.Replace('require(script.Parent.L4Dispatch)', 'require(game.ServerScriptService.L4Dispatch)')
    $source = $source.Replace('require(script.Parent.L5Flow)', 'require(game.ServerScriptService.L5Flow)')
    $source = $source.Replace('"L3Lobby"', '"L4FixtureLobby"').Replace('"L3QueueState"', '"L4FixtureQueue"').Replace('"L3Play"', '"L4FixturePlay"')
    $source = $source.Replace('"L4State"', '"L4FixtureState"').Replace('"L4Return"', '"L4FixtureReturn"')
    $harnessPath = Join-Path $rootPath '.tools/L4HarnessLobby.luau'
    [IO.File]::WriteAllText($harnessPath, "return function(testPlayers)`n$source`nend`n")
    & "$Tools/stylua/stylua.exe" $harnessPath
    & "$Tools/selene/selene.exe" $harnessPath
    if ($LASTEXITCODE) { throw 'L4 lobby harness lint failed' }
    & "$Tools/luau/luau-compile.exe" --null $harnessPath
    if ($LASTEXITCODE) { throw 'L4 lobby harness compilation failed' }
} finally { Pop-Location }
