return table.freeze({
	Startup = 0.08,
	Active = 0.10,
	Recovery = 0.32,
	Duration = 0.50,
	BufferStart = 0.38,
	Size = Vector3.new(4, 5, 2),
	StrikeHeight = 0.20, -- Standard F1 R15 UpperTorso center, inspected in Studio.
	StartReach = 1,
	EndReach = 10,
	MoveScale = 0.7,
	LaunchSpeed = 50,
	LaunchUp = 12,
	Reaction = 0.15,
	Protection = 0.35,
	DisplacementFailsafe = 1.5, -- Preserves the study's bounded timeout cleanup.
	ObservedMotion = 0.5,
	InputInterval = 0.05,
	InputExpiry = 0.2,
	CorrectionHold = 0.1,
	ExposureStep = 0.25,
})
