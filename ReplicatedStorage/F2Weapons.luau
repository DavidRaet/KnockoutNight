local Storage = game:GetService("ReplicatedStorage")
local Weapons = {
	SpringFist = require(Storage.F2Config),
	WreckingHammer = require(Storage.F6Hammer),
	PaddlePops = require(Storage.F7Paddles),
}

-- Server-owned prototype choice; full intermission loadouts remain a later slice.
function Weapons.forPlayer(player)
	local name = player:GetAttribute("F2Weapon")
	return if name == "WreckingHammer" or name == "PaddlePops" then name else "SpringFist"
end

return table.freeze(Weapons)
