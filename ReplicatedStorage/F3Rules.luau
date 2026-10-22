local Rules = {}

function Rules.outside(position, center, lowerY, outerRadius)
	local x, z = position.X - center.X, position.Z - center.Z
	return position.Y <= lowerY or x * x + z * z >= outerRadius * outerRadius
end

function Rules.eliminate(state, life, now, delay)
	if state.life ~= life or state.status ~= "alive" then
		return false
	end
	state.status = "eliminated"
	state.eliminatedAt, state.respawnAt = now, now + delay
	return true
end

-- Start after the last selected point so exact distance ties rotate deterministically.
function Rules.choose(distances, previous)
	local best, distance = nil, -math.huge
	for offset = 1, #distances do
		local index = (previous + offset - 1) % #distances + 1
		if distances[index] > distance then
			best, distance = index, distances[index]
		end
	end
	return best
end

return table.freeze(Rules)
