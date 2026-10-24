param([string]$Tools = (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/RobloxChecks'), [switch]$AppearanceOnly)
$ErrorActionPreference = 'Stop'
$rootPath = Split-Path $PSScriptRoot -Parent
Push-Location $rootPath
try {
    $source = Get-Content ServerScriptService/F1Prototype.server.luau -Raw
    $source = $source.Replace('local Players = game:GetService("Players")', 'local Players = testPlayers')
    $source = $source.Replace('local Config = require(configInstance)', 'local Config = testConfig')
    $source = $source.Replace('local Lives = require(script.Parent.F3Lives)', 'local Lives = testLives')
    $source = $source.Replace('local Match = require(script.Parent.F4Match)', 'local Match = testMatch')
    $source = $source.Replace('local Arenas = require(script.Parent.L5Arenas)', 'local Arenas = testArenas')
    $source = $source.Replace('require(script.Parent.L3Lobby)', 'testLobby')
    $source = $source.Replace('game:BindToClose(lobby.stop)', '-- fixture does not register process shutdown')
    $spec = Get-Content tests/F1Appearance.spec.luau -Raw
    $stub = @'
local function runBootstrap(testPlayers)
    local function warn() end
    local capturedSpawn
    local testConfig = {DeveloperArenaMode=false,Arena="Dungeon",WalkSpeed=16,JumpHeight=7}
    local testLives = {start=function(spawn) capturedSpawn=spawn end}
    local testMatch = {}
    local testLobby = {start=function() end,stop=function() end}
    local testArenas = {build=function() return {},{}, {},{} end}
    local signal = {Connect=function() return {Disconnect=function() end} end}
    local script = {Destroying=signal}
    local workspace = {FindFirstChild=function() return nil end}
    local Enum = {HumanoidRigType={R15="R15"},DevComputerMovementMode={Scriptable="Scriptable"},HumanoidDisplayDistanceType={None="None"},HumanoidStateType={Climbing="Climbing",Swimming="Swimming"}}
    local Instance = {new=function() return {Destroy=function() end} end}
    local services = {PhysicsService={IsCollisionGroupRegistered=function() return true end,CollisionGroupSetCollidable=function() end},ReplicatedStorage={WaitForChild=function() return {IsA=function() return true end} end},StarterPlayer={}}
    local game = {GetService=function(_,name) return services[name] end}
    local task = {spawn=function(callback,...) callback(...) end}
'@
    $runner = "$stub`n$source`nreturn capturedSpawn`nend`nlocal run=(function()`n$spec`nend)()`nlocal result=run(runBootstrap)`nassert(result.passed, 'Appearance regression failed')`nprint('PASS: '..result.checks..' appearance checks')"
    $runnerPath = Join-Path $Tools 'player-appearance-checks.luau'
    [IO.File]::WriteAllText($runnerPath, $runner)
    & "$Tools/luau/luau.exe" $runnerPath
    if ($LASTEXITCODE) { throw 'Player appearance regression failed' }
    if (-not $AppearanceOnly) {
        $files = @('ReplicatedStorage/F1Movement.luau','tests/F1Appearance.spec.luau','tests/F1MouseLock.spec.luau','tests/F1Controls.spec.luau')
        & "$Tools/stylua/stylua.exe" --check @files
        if ($LASTEXITCODE) { throw 'Player controls formatting failed' }
        & "$Tools/selene/selene.exe" @files
        if ($LASTEXITCODE) { throw 'Player controls lint failed' }
        foreach ($file in $files) {
            & "$Tools/luau/luau-compile.exe" --null $file
            if ($LASTEXITCODE) { throw "Player controls compilation failed: $file" }
        }
        $movement = Get-Content ReplicatedStorage/F1Movement.luau -Raw
        $mouseSpec = Get-Content tests/F1MouseLock.spec.luau -Raw
        $runner = "local Movement=(function()`n$movement`nend)()`nlocal run=(function()`n$mouseSpec`nend)()`nlocal result=run(Movement)`nassert(result.passed, 'Mouse lock rules failed')`nprint('PASS: '..result.checks..' mouse lock checks')"
        $runnerPath = Join-Path $Tools 'player-mouse-lock-checks.luau'
        [IO.File]::WriteAllText($runnerPath, $runner)
        & "$Tools/luau/luau.exe" $runnerPath
        if ($LASTEXITCODE) { throw 'Mouse lock tests failed' }
        & "$PSScriptRoot/run_l6_checks.ps1" -Tools $Tools
    }
} finally { Pop-Location }
