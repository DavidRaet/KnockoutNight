# Build an isolated engine fixture from the current production combat source.
$ErrorActionPreference = 'Stop'
$rootPath = Split-Path $PSScriptRoot -Parent
$source = Get-Content (Join-Path $rootPath 'ServerScriptService/F2Combat.luau') -Raw
$source = $source.Replace('local Players = game:GetService("Players")', 'local Players = testPlayers')
$source = $source.Replace('local function own(state, owner)', 'local function own(state, _owner)')
$source = $source.Replace('state.root:SetNetworkOwner(owner)', 'state.root:SetNetworkOwner(nil)')
$source = $source.Replace('probe.Parent = workspace', 'probe.Parent = game.Workspace')
$source = $source.Replace('require(script.Parent.F2Contact)', 'require(game.ServerScriptService.F2Contact)')
$source = 'return function(testPlayers, Instance, workspace)' + "`n" + $source + "`nend`n"
$path = Join-Path $rootPath '.tools/F9HarnessCombat.luau'
[IO.File]::WriteAllText($path, $source)
$tools = Join-Path $rootPath '.tools/RobloxChecks'
& "$tools/stylua/stylua.exe" $path
& "$tools/stylua/stylua.exe" --check $path
if ($LASTEXITCODE) { throw 'F9 harness formatting failed' }
& "$tools/selene/selene.exe" $path
if ($LASTEXITCODE) { throw 'F9 harness lint failed' }
& "$tools/luau/luau-compile.exe" --null $path
if ($LASTEXITCODE) { throw 'F9 harness compilation failed' }
