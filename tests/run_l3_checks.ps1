param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'))
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/run_l2_checks.ps1" -Tools $Tools
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $files = @('ReplicatedStorage/L3Config.luau', 'ServerScriptService/L3Queue.luau', 'ServerScriptService/L3Lobby.luau', 'StarterPlayerScripts/L3Client.luau', 'tests/L3Queue.spec.luau', 'tests/L3Lobby.spec.luau')
    & "$Tools/stylua/stylua.exe" --check @files
    if ($LASTEXITCODE) { throw 'L3 formatting failed' }
    & "$Tools/selene/selene.exe" @files
    if ($LASTEXITCODE) { throw 'L3 lint failed' }
    foreach ($file in $files) {
        & "$Tools/luau/luau-compile.exe" --null $file
        if ($LASTEXITCODE) { throw "L3 compilation failed: $file" }
    }
    $queue = Get-Content ServerScriptService/L3Queue.luau -Raw
    $spec = Get-Content tests/L3Queue.spec.luau -Raw
    $runner = "local Queue=(function()`n$queue`nend)()`nlocal run=(function()`n$spec`nend)()`nlocal result=run(Queue)`nassert(result.passed, 'L3 queue rules failed')`nprint('PASS: '..result.checks..' L3 queue checks')"
    $runnerPath = Join-Path $Tools 'l3-queue-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'L3 queue tests failed' }
    $source = Get-Content ServerScriptService/L3Lobby.luau -Raw
    $source = $source.Replace('local Players = game:GetService("Players")', 'local Players = testPlayers')
    $source = $source.Replace('playRemote.OnServerEvent:Connect(play)', 'testPlayers.Play.Event:Connect(play)')
    $source = $source.Replace('local Config = require(Storage.L3Config)', 'local Config = table.clone(require(Storage.L3Config)); Config.Origin += Vector3.new(200, 0, 0)')
    $source = $source.Replace('"L3Lobby"', '"L3FixtureLobby"').Replace('"L3QueueState"', '"L3FixtureQueueState"').Replace('"L3Play"', '"L3FixturePlay"')
    $source = $source.Replace('require(script.Parent.L3Queue)', 'require(game.ServerScriptService.L3Queue)')
    $source = $source.Replace('require(script.Parent.L4Dispatch)', 'require(game.ServerScriptService.L4Dispatch)')
    $source = $source.Replace('require(script.Parent.L5Flow)', 'require(game.ServerScriptService.L5Flow)')
    $source = $source.Replace('Config.Origin += Vector3.new(200, 0, 0)', 'Config.Origin += Vector3.new(200, 0, 0); Config.DispatchCountdown = math.huge')
    $source = $source.Replace('"L4State"', '"L3FixtureDispatchState"').Replace('"L4Return"', '"L3FixtureReturn"')
    $harnessPath = Join-Path $rootPath '.tools/L3HarnessLobby.luau'
    [IO.File]::WriteAllText($harnessPath, "return function(testPlayers)`n$source`nend`n")
    & "$Tools/stylua/stylua.exe" $harnessPath
    & "$Tools/selene/selene.exe" $harnessPath
    if ($LASTEXITCODE) { throw 'L3 lobby harness lint failed' }
    & "$Tools/luau/luau-compile.exe" --null $harnessPath
    if ($LASTEXITCODE) { throw 'L3 lobby harness compilation failed' }
} finally { Pop-Location }
