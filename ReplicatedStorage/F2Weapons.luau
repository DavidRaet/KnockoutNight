local Storage = game:GetService("ReplicatedStorage")
local Weapons = {
	SpringFist = require(Storage.F2Config),
	WreckingHammer = require(Storage.F6Hammer),
}

-- Server-owned prototype choice; the future loadout UI is outside F6.
function Weapons.forPlayer(player)
	local name = player:GetAttribute("F2Weapon")
	return if name == "WreckingHammer" then name else "SpringFist"
end

return table.freeze(Weapons)
