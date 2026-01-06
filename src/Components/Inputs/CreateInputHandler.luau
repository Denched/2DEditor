--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)
local HANDLE_POSITIONS = require(script.Parent.Handles)

export type HandlerConfig = {
	name: string,
	zIndex: number,
	usesHalfExtents: boolean,
	minSize: number,
	disableResize: boolean?,

	canHandle: (state: any) -> boolean,
	getSelectedObject: (state: any) -> (any?, string?, string?),
	findObjectAtPoint: (state: any, worldPoint: vector) -> (string?, string?),
	onSelect: (entityId: string?, objectId: string?) -> (),
	onDeselect: () -> (),
	updateObject: (entityId: string, objectId: string?, updates: { [string]: any }) -> (),

	waypointMove: string,
	waypointResize: string,
}

local create = vide.create
local source = vide.source

local HANDLE_SIZE = 8
local SELECTION_TOLERANCE = 5

local RESIZE_TABLE = {
	TopLeft = { posX = 0.5, posY = 0.5, sizeX = -1, sizeY = -1 },
	TopRight = { posX = 0.5, posY = 0.5, sizeX = 1, sizeY = -1 },
	BottomLeft = { posX = 0.5, posY = 0.5, sizeX = -1, sizeY = 1 },
	BottomRight = { posX = 0.5, posY = 0.5, sizeX = 1, sizeY = 1 },
	TopMiddle = { posX = 0, posY = 0.5, sizeX = 0, sizeY = -1 },
	BottomMiddle = { posX = 0, posY = 0.5, sizeX = 0, sizeY = 1 },
	LeftMiddle = { posX = 0.5, posY = 0, sizeX = -1, sizeY = 0 },
	RightMiddle = { posX = 0.5, posY = 0, sizeX = 1, sizeY = 0 },
}

local function getHandleAtPoint(
	screenPoint: vector,
	position: vector,
	size: vector,
	isHalfExtents: boolean,
	zoom: number
)
	local half = if isHalfExtents then size else vector.create(size.x / 2, size.y / 2, 0)
	local fullSize = if isHalfExtents then vector.create(size.x * 2, size.y * 2, 0) else size

	local topLeft = vector.create(position.x - half.x, position.y - half.y, 0)
	local screenTopLeft = EditorState.worldToScreen(topLeft)

	for _, handleInfo in HANDLE_POSITIONS do
		local handleAnchorX = screenTopLeft.x + (handleInfo.x * fullSize.x * zoom)
		local handleAnchorY = screenTopLeft.y + (handleInfo.y * fullSize.y * zoom)

		local handleCenterX = handleAnchorX + (0.5 - handleInfo.anchorX) * HANDLE_SIZE
		local handleCenterY = handleAnchorY + (0.5 - handleInfo.anchorY) * HANDLE_SIZE

		local distance = math.sqrt((screenPoint.x - handleCenterX) ^ 2 + (screenPoint.y - handleCenterY) ^ 2)

		if distance <= HANDLE_SIZE + SELECTION_TOLERANCE then
			return handleInfo
		end
	end

	return nil
end

local function computeResize(
	handleName: string,
	delta: vector,
	startPos: vector,
	startSize: vector,
	isHalfExtents: boolean
): (vector, vector)
	local r = RESIZE_TABLE[handleName]
	local sizeFactor = if isHalfExtents then 0.5 else 1

	local newPos = vector.create(startPos.x + delta.x * r.posX, startPos.y + delta.y * r.posY, 0)
	local newSize =
		vector.create(startSize.x + delta.x * r.sizeX * sizeFactor, startSize.y + delta.y * r.sizeY * sizeFactor, 0)

	return newPos, newSize
end

return function(config: HandlerConfig)
	return function()
		local state = EditorState.get()

		local isDragging = source(false)
		local isDraggingHandle = source(false)
		local dragStartMouseWorld = source(vector.create(0, 0, 0))
		local dragStartPos = source(vector.create(0, 0, 0))
		local dragStartSize = source(vector.create(0, 0, 0))
		local draggedHandle = source(nil)

		return create("Frame")({
			Name = config.name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Active = true,
			ZIndex = config.zIndex,

			InputBegan = function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end

				if not config.canHandle(state) then
					return
				end

				local mousePos = vector.create(input.Position.X, input.Position.Y, 0)
				local worldPos = EditorState.screenToWorld(mousePos)

				local selectedObject, _entityId, _objectId = config.getSelectedObject(state)

				if selectedObject and not config.disableResize then
					local size = if config.usesHalfExtents then selectedObject.halfExtents else selectedObject.size
					local handle =
						getHandleAtPoint(mousePos, selectedObject.position, size, config.usesHalfExtents, state.zoom())

					if handle then
						isDraggingHandle(true)
						draggedHandle(handle)
						dragStartMouseWorld(worldPos)
						dragStartPos(selectedObject.position)
						dragStartSize(size)
						return
					end
				end

				local foundEntityId, foundObjectId = config.findObjectAtPoint(state, worldPos)

				if foundEntityId then
					config.onSelect(foundEntityId, foundObjectId)

					local obj, _newEntityId, _newObjectId = config.getSelectedObject(state)
					if obj then
						isDragging(true)
						dragStartMouseWorld(worldPos)
						dragStartPos(obj.position)
					end
				else
					config.onDeselect()
				end
			end,

			InputChanged = function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then
					return
				end

				local mousePos = vector.create(input.Position.X, input.Position.Y, 0)
				local worldPos = EditorState.screenToWorld(mousePos)

				local selectedObject, entityId, objectId = config.getSelectedObject(state)

				if isDraggingHandle() and selectedObject then
					local handle = draggedHandle()
					if handle then
						local delta = worldPos - dragStartMouseWorld()
						local newPos, newSize =
							computeResize(handle.name, delta, dragStartPos(), dragStartSize(), config.usesHalfExtents)

						if newSize.x > config.minSize and newSize.y > config.minSize then
							local sizeKey = if config.usesHalfExtents then "halfExtents" else "size"
							config.updateObject(entityId :: string, objectId, {
								position = newPos,
								[sizeKey] = newSize,
							})
						end
					end
				elseif isDragging() and selectedObject then
					local delta = worldPos - dragStartMouseWorld()
					local newPos = dragStartPos() + delta

					config.updateObject(entityId :: string, objectId, {
						position = newPos,
					})
				end
			end,

			InputEnded = function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end

				if isDragging() or isDraggingHandle() then
					local action = if isDraggingHandle() then config.waypointResize else config.waypointMove
					EditorState.setWaypoint(action)
					isDragging(false)
					isDraggingHandle(false)
					draggedHandle(nil)
				end
			end,
		})
	end
end
