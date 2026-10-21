local Storage = game:GetService("ReplicatedStorage")
local Config = require(Storage.F2Config)
local Fist = require(Storage.F2SpringFist)
local Contact = {}

function Contact.frame(position, aim, reach)
	local center = position + Vector3.yAxis * Config.StrikeHeight + aim * reach
	return CFrame.lookAt(center, center + aim)
end

local function params(instances, include, solid)
	local ray = RaycastParams.new()
	ray.FilterType = if include then Enum.RaycastFilterType.Include else Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = instances
	ray.RespectCanCollide = solid == true
	return ray
end

local function overlaps(probe, cf, instances, solid)
	probe.CFrame = cf
	local overlap = OverlapParams.new()
	overlap.FilterType = if solid then Enum.RaycastFilterType.Exclude else Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = instances
	overlap.RespectCanCollide = solid == true
	return workspace:GetPartsInPart(probe, overlap)
end

function Contact.body(character)
	local parts = {}
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return parts
	end
	for _, part in character:GetChildren() do
		if
			part:IsA("BasePart")
			and part.Name ~= "HumanoidRootPart"
			and humanoid:GetBodyPartR15(part) ~= Enum.BodyPartR15.Unknown
		then
			table.insert(parts, part)
		end
	end
	return parts
end

-- Probe overlapping body regions, rather than accepting a clear ray to the target's center.
local function exposed(probe, cf, body, origin, walls)
	local touching = overlaps(probe, cf, body, false)
	for _, part in touching do
		local half = Config.Size / 2
		local function regionPoint(sample)
			local point = part:GetClosestPointOnSurface(sample)
			local localPoint = cf:PointToObjectSpace(point)
			if
				math.abs(localPoint.X) > half.X + 0.00001
				or math.abs(localPoint.Y) > half.Y + 0.00001
				or math.abs(localPoint.Z) > half.Z + 0.00001
			then
				return nil
			end
			if not workspace:Raycast(origin, point - origin, walls) then
				return point
			end
			return nil
		end
		local candidate = cf.Position
		for _ = 1, 12 do
			local point = regionPoint(candidate)
			if point then
				return point
			end
			local localPoint = cf:PointToObjectSpace(part:GetClosestPointOnSurface(candidate))
			candidate = cf:PointToWorldSpace(
				Vector3.new(
					math.clamp(localPoint.X, -half.X, half.X),
					math.clamp(localPoint.Y, -half.Y, half.Y),
					math.clamp(localPoint.Z, -half.Z, half.Z)
				)
			)
		end
		local center = cf:PointToObjectSpace(part.Position)
		local radius = part.Size.Magnitude / 2
		local lo = center - Vector3.one * radius
		local hi = center + Vector3.one * radius
		for x = math.max(-half.X, lo.X), math.min(half.X, hi.X), Config.ExposureStep do
			for y = math.max(-half.Y, lo.Y), math.min(half.Y, hi.Y), Config.ExposureStep do
				for z = math.max(-half.Z, lo.Z), math.min(half.Z, hi.Z), Config.ExposureStep do
					local point = regionPoint(cf:PointToWorldSpace(Vector3.new(x, y, z)))
					if point then
						return point
					end
				end
			end
		end
	end
	return nil
end

function Contact.sweep(probe, action, fromPosition, toPosition, first, last, excluded, victims)
	local firstReach = if action.wallStopped then action.stoppedReach else Fist.reach(first - action.started, Config)
	local lastReach = if action.wallStopped then action.stoppedReach else Fist.reach(last - action.started, Config)
	local from = Contact.frame(fromPosition, action.aim, firstReach)
	local to = Contact.frame(toPosition, action.aim, lastReach)
	local delta = to.Position - from.Position
	local walls = params(excluded, false, true)
	local stop = 1
	if #overlaps(probe, from, excluded, true) > 0 then
		stop = 0
	elseif delta.Magnitude > 0 then
		local wall = workspace:Blockcast(from, Config.Size, delta, walls)
		if wall then
			stop = math.clamp(wall.Distance / delta.Magnitude, 0, 1)
		end
	end
	if stop < 1 then
		action.wallStopped = true
	end
	local found = {}
	for _, victim in victims do
		if action.encountered[victim] then
			continue
		end
		local body = Contact.body(victim.character)
		local fraction
		if #overlaps(probe, from, body, false) > 0 then
			fraction = 0
		elseif delta.Magnitude > 0 then
			local hit = workspace:Blockcast(from, Config.Size, delta, params(body, true, false))
			if hit then
				fraction = hit.Distance / delta.Magnitude
			end
		end
		if fraction and fraction <= stop then
			-- shortcut: targets use current server geometry; no rewind. Exposure uses a 0.25-stud grid; refine if tiny slivers matter.
			local steps = math.max(1, math.ceil(delta.Magnitude * (stop - fraction) / Config.ExposureStep))
			for step = 0, steps do
				local alpha = fraction + (stop - fraction) * step / steps
				local cf = from:Lerp(to, alpha)
				-- Nudge inside the exact cast boundary for occupied-space overlap queries.
				local inside = from:Lerp(to, math.min(stop, alpha + 0.0001))
				local origin = fromPosition:Lerp(toPosition, alpha) + Vector3.yAxis * Config.StrikeHeight
				local point = exposed(probe, inside, body, origin, walls)
				if point and first + (last - first) * alpha < action.started + Config.Startup + Config.Active then
					table.insert(
						found,
						{ victim = victim, time = first + (last - first) * alpha, point = point, frame = cf }
					)
					break
				end
			end
		end
	end
	action.stoppedReach = firstReach + (lastReach - firstReach) * stop
	return found
end

return Contact
