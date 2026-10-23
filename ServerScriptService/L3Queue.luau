local Queue = {}

function Queue.contains(x, y, z, halfX, halfZ)
	return math.abs(x) <= halfX and math.abs(z) <= halfZ and y >= 0 and y <= 15
end

function Queue.update(queue, player, inside)
	local position = table.find(queue, player)
	if inside and not position then
		table.insert(queue, player)
		return true
	elseif not inside and position then
		table.remove(queue, position)
		return true
	end
	return false
end

return Queue
