--!strict

-- Prototype settings: PRD DD01 / section 17; camera and steering need playtesting.
return table.freeze({
	-- Enable only in a separate developer test session to use the original arena staging path.
	DeveloperArenaMode = false,
	Arena = "Dungeon",
	WalkSpeed = 16,
	JumpHeight = 7,
	AirControl = 0.6,
	PlatformCenter = Vector3.new(0, 40, 0),
	PlatformDiameter = 70,
	PlatformThickness = 4,
	SpawnOffset = 18,
	CameraDistance = 16,
	CameraMinDistance = 8,
	CameraMaxDistance = 24,
	CameraZoomStep = 2,
	CameraPitch = math.rad(-22),
	CameraMinPitch = math.rad(-65),
	CameraMaxPitch = math.rad(20),
	CameraSensitivity = math.rad(0.16),
	CameraFocusHeight = 2,
	CameraRadius = 0.5,
	CameraWallPadding = 0.25,
})
