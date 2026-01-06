--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create

local SPAWN_WORLD_SIZE = 24

return function()
	local state = EditorState.get()

	return create("Frame")({
		Name = "SpawnPointRenderer",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = ZIndexes.SpawnOverlay or 60,

		function()
			local spawns = state.spawnPoints()
			local selectedSpawnId = state.selectedSpawnPointId()
			local zoom = state.zoom()
			local offset = state.viewportOffset()

			local markers = {}
			for _, spawn in spawns do
				local isSelected = spawn.id == selectedSpawnId
				local color = EditorState.getSpawnColor(spawn.playerIndex)

				local screenSize = SPAWN_WORLD_SIZE * zoom
				local screenPos = vector.create(
					spawn.position.x * zoom + offset.x,
					spawn.position.y * zoom + offset.y,
					0
				)

				local marker = create("Frame")({
					Name = "Spawn_" .. spawn.id,
					Size = UDim2.fromOffset(screenSize, screenSize),
					Position = UDim2.fromOffset(screenPos.x, screenPos.y),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = color,
					BackgroundTransparency = 0.3,
					BorderSizePixel = if isSelected then 2 else 1,
					BorderColor3 = if isSelected then Color3.fromRGB(255, 255, 255) else color,
					ZIndex = ZIndexes.SpawnOverlay or 60,

					create("UICorner")({
						CornerRadius = UDim.new(0, 4),
					}),

					create("TextLabel")({
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "P" .. spawn.playerIndex,
						TextSize = math.clamp(screenSize * 0.45, 8, 14),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						ZIndex = ZIndexes.SpawnOverlay + 1 or 61,
					}),
				})

				table.insert(markers, marker)
			end
			return markers
		end,
	})
end
