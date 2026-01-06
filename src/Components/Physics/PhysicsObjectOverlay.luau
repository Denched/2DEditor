--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)
local vide = require(script.Parent.Parent.Parent.Packages.vide)
local HANDLE_POSITIONS = require(script.Parent.Parent.Inputs.Handles)

local create = vide.create

local HANDLE_SIZE = 8
local BORDER_THICKNESS = 1

local BORDER_COLOR = Color3.fromRGB(255, 0, 0)

local function createHandle(handlePos)
	return create("Frame")({
		Name = "Handle",
		Size = UDim2.fromOffset(HANDLE_SIZE, HANDLE_SIZE),
		Position = UDim2.fromScale(handlePos.x, handlePos.y),
		AnchorPoint = Vector2.new(handlePos.anchorX, handlePos.anchorY),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Visible = true,
		ZIndex = ZIndexes.HitboxOverlay + 11,
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
	local state = EditorState.get()

	return create("Frame")({
		Name = "PhysicsObjectOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = ZIndexes.HitboxOverlay,

		function()
			local entities = state.entities()
			local selectedPhysicsObjectId = state.selectedPhysicsObjectId()
			local zoom = state.zoom()
			local offset = state.viewportOffset()
			local overlays = {}

			for _, entity in entities do
				for _, physicsObject in entity.physicsObjects do
					local isSelected = selectedPhysicsObjectId == physicsObject.id

					local screenPos = vector.create(
						physicsObject.position.x * zoom + offset.x,
						physicsObject.position.y * zoom + offset.y,
						0
					)
					local size = vector.create(physicsObject.halfExtents.x * 2, physicsObject.halfExtents.y * 2, 0)
					local screenSize = vector.create(size.x * zoom, size.y * zoom, 0)

					local overlay = create("Frame")({
						Name = physicsObject.name,
						Position = UDim2.fromOffset(screenPos.x, screenPos.y),
						Size = UDim2.fromOffset(screenSize.x, screenSize.y),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = ZIndexes.HitboxOverlay,

						create("UIStroke")({
							Color = BORDER_COLOR,
							Thickness = BORDER_THICKNESS,
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Enabled = true,
						}),

						createHandlesIfSelected(isSelected),
					})

					table.insert(overlays, overlay)
				end
			end

			return overlays
		end,
	})
end
