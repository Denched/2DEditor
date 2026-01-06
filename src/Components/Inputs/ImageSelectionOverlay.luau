--# selene: allow(mixed_table)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)
local vide = require(script.Parent.Parent.Parent.Packages.vide)
local HANDLE_POSITIONS = require(script.Parent.Handles)

local create = vide.create

local HANDLE_SIZE = 8
local BORDER_THICKNESS = 1

local SELECTION_COLOR = Color3.fromRGB(0, 255, 100)

local function createHandle(handlePos)
	return create("Frame")({
		Name = "Handle",
		Size = UDim2.fromOffset(HANDLE_SIZE, HANDLE_SIZE),
		Position = UDim2.fromScale(handlePos.x, handlePos.y),
		AnchorPoint = Vector2.new(handlePos.anchorX, handlePos.anchorY),
		BackgroundColor3 = SELECTION_COLOR,
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Visible = true,
		ZIndex = ZIndexes.HitboxOverlay + 20, -- Above image border
	})
end

local function createHandlesIfSelected(isSelected: boolean)
	if not isSelected then
		return
	end

	local handles = {}
	for _, handlePos in HANDLE_POSITIONS do
		table.insert(handles, createHandle(handlePos))
	end
	return table.unpack(handles)
end

return function()
	return create("Frame")({
		Name = "ImageSelectionOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = ZIndexes.HitboxOverlay,

		function()
			local state = EditorState.get()
			local entities = state.entities()
			local selectedEntityId = state.selectedEntityId()
			local selectedPhysicsObjectId = state.selectedPhysicsObjectId()
			local zoom = state.zoom()
			local offset = state.viewportOffset()

			local overlays = {}

			for _, entity in entities do
				local screenPos =
					vector.create(entity.position.x * zoom + offset.x, entity.position.y * zoom + offset.y, 0)
				local screenSize = vector.create(entity.size.x * zoom, entity.size.y * zoom, 0)

				local topLeft = vector.create(screenPos.x - screenSize.x / 2, screenPos.y - screenSize.y / 2, 0)

				local isSelected = (selectedEntityId == entity.id and selectedPhysicsObjectId == nil)

				local overlay = create("Frame")({
					Name = "ImageSelection_" .. entity.name,
					Position = UDim2.fromOffset(topLeft.x, topLeft.y),
					Size = UDim2.fromOffset(screenSize.x, screenSize.y),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = ZIndexes.HitboxOverlay + 15,
					create("UIStroke")({
						Color = SELECTION_COLOR,
						Thickness = BORDER_THICKNESS,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Enabled = true,
					}),

					createHandlesIfSelected(isSelected),
				})

				table.insert(overlays, overlay)
			end

			return overlays
		end,
	})
end
