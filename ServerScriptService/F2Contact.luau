local Storage = game:GetService("ReplicatedStorage")
local Config = require(Storage.F2Config)
local Fist = require(Storage.F2SpringFist)
local Hammer = require(Storage.F6Hammer)
local Paddles = require(Storage.F7Paddles)
local Gust = require(Storage.F8Gust)
local Slam = require(Storage.F11Slam)
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
		local half = probe.Size / 2
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

-- Sample a rotating radial blade, including the shaft, at sub-body-width intervals.
local function hammerSweep(probe, action, fromPosition, toPosition, first, last, excluded, victims)
	probe.Size = Hammer.Size
	local walls, found, seen = params(excluded, false, true), {}, {}
	local arc = math.abs(Hammer.angle(last - action.started) - Hammer.angle(first - action.started))
	local steps =
		math.max(1, math.ceil(((toPosition - fromPosition).Magnitude + arc * Hammer.EndReach) / Config.ExposureStep))
	local bodies = {}
	for _, victim in victims do
		if not action.encountered[victim] then
			bodies[victim] = Contact.body(victim.character)
		end
	end
	for step = 0, steps do
		local alpha = step / steps
		local time = first + (last - first) * alpha
		if time >= action.started + Hammer.Startup + Hammer.Active then
			break
		end
		local position = fromPosition:Lerp(toPosition, alpha)
		local cf = Hammer.frame(position, action.aim, time - action.started)
		for victim, body in bodies do
			if not seen[victim] then
				local point = exposed(probe, cf, body, position + Vector3.yAxis * Hammer.StrikeHeight, walls)
				if point then
					seen[victim] = true
					table.insert(found, { victim = victim, time = time, point = point, frame = cf })
				end
			end
		end
	end
	return found
end

function Contact.sweep(probe, action, fromPosition, toPosition, first, last, excluded, victims)
	if action.config == Paddles then
		probe.Size = Paddles.Size
		local walls, found, seen = params(excluded, false, true), {}, {}
		local steps = math.max(1, math.ceil((toPosition - fromPosition).Magnitude / Config.ExposureStep))
		local bodies = {}
		for _, victim in victims do
			if not action.encountered[victim] then
				bodies[victim] = Contact.body(victim.character)
			end
		end
		for step = 0, steps do
			local alpha = step / steps
			local time = first + (last - first) * alpha
			if time >= action.started + Paddles.Startup + Paddles.Active then
				break
			end
			local position = fromPosition:Lerp(toPosition, alpha)
			local cf = Paddles.frame(position, action.aim, action.hand)
			for victim, body in bodies do
				if not seen[victim] then
					local point = exposed(probe, cf, body, position, walls)
					if point then
						seen[victim] = true
						table.insert(found, { victim = victim, time = time, point = point, frame = cf })
					end
				end
			end
		end
		return found
	end
	if action.config == Hammer then
		return hammerSweep(probe, action, fromPosition, toPosition, first, last, excluded, victims)
	end
	probe.Size = Config.Size
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

-- Horizontal root cone with actual R15 body overlap in the five-stud-high burst.
function Contact.gust(origin, aim, victim, excluded, profile)
	profile = profile or Gust
	local delta = victim.root.Position - origin
	if not profile.contains(delta.X, delta.Z, aim.X, aim.Z) then
		return nil
	end
	local walls = params(excluded, false, true)
	for _, body in Contact.body(victim.character) do
		local cf, half = body.CFrame, body.Size / 2
		local extent = math.abs(cf.RightVector.Y) * half.X
			+ math.abs(cf.UpVector.Y) * half.Y
			+ math.abs(cf.LookVector.Y) * half.Z
		if
			body.Position.Y + extent >= origin.Y - profile.Height / 2
			and body.Position.Y - extent <= origin.Y + profile.Height / 2
		then
			local point = body:GetClosestPointOnSurface(
				Vector3.new(
					origin.X,
					math.clamp(body.Position.Y, origin.Y - profile.Height / 2, origin.Y + profile.Height / 2),
					origin.Z
				)
			)
			if not workspace:Raycast(origin, point - origin, walls) then
				return point
			end
		end
	end
	return nil
end

local function playable(hit)
	return hit
		and hit.Instance:IsDescendantOf(workspace)
		and hit.Instance.CanCollide
		and hit.Instance:GetAttribute("F11Playable") == true
		and hit.Normal.Y >= 0.95
end

function Contact.slamLanding(state, previous, excluded)
	local root = state.root
	local feet = state.humanoid.HipHeight + root.Size.Y / 2
	local origin = Vector3.new(root.Position.X, math.max(previous.Y, root.Position.Y), root.Position.Z)
	local hit = workspace:Raycast(
		origin,
		-Vector3.yAxis * (origin.Y - root.Position.Y + feet + 0.3),
		params(excluded, false, true)
	)
	return if playable(hit) then hit else nil
end

function Contact.slamTarget(origin, victim, excluded, surface)
	local delta = victim.root.Position - origin
	if Vector3.new(delta.X, 0, delta.Z).Magnitude > Slam.Radius then
		return nil
	end
	local ray = params(excluded, false, true)
	local feet = victim.humanoid.HipHeight + victim.root.Size.Y / 2
	local target = workspace:Raycast(victim.root.Position, -Vector3.yAxis * (feet + Slam.Elevation), ray)
	if
		not playable(target)
		or target.Instance ~= surface
		or math.abs(target.Position.Y - origin.Y) > Slam.Elevation
	then
		return nil
	end
	local path = target.Position - origin
	if workspace:Raycast(origin + Vector3.yAxis * 0.5, path, ray) then
		return nil
	end
	-- Sample continuous support so a clear air ray cannot bridge separate islands.
	local steps = math.max(1, math.ceil(path.Magnitude / 0.25))
	for i = 0, steps do
		local point = origin:Lerp(target.Position, i / steps)
		local support = workspace:Raycast(point + Vector3.yAxis * 0.5, -Vector3.yAxis, ray)
		if not playable(support) or math.abs(support.Position.Y - origin.Y) > 0.5 then
			return nil
		end
	end
	return target.Position
end

return Contact
