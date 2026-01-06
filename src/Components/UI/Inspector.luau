--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create

local ROW_HEIGHT = 30
local LABEL_WIDTH = 120

local function createStaticPropertyRow(props: {
	label: string,
	value: string,
	onEdit: (string) -> (),
})
	local function Box()
		local textBox

		textBox = create("TextBox")({
			Size = UDim2.new(1, -(LABEL_WIDTH + 10), 0, 24),
			Position = UDim2.fromOffset(LABEL_WIDTH + 5, 3),
			BackgroundColor3 = Color3.fromRGB(45, 45, 48),
			BorderSizePixel = 1,
			BorderColor3 = Color3.fromRGB(60, 60, 65),
			Text = props.value,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			PlaceholderText = "Enter value...",

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 5),
			}),

			FocusLost = function()
				props.onEdit(textBox.Text)
			end,
		})

		return textBox
	end
	return create("Frame")({
		Size = UDim2.new(1, -10, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,

		create("TextLabel")({
			Size = UDim2.fromOffset(LABEL_WIDTH, ROW_HEIGHT),
			Position = UDim2.fromOffset(5, 0),
			BackgroundTransparency = 1,
			Text = props.label,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),

		Box(),
	})
end

local function createNumericPropertyRow(props: {
	label: string,
	value: number,
	format: string?,
	onEdit: (number) -> (),
	min: number?,
})
	return createStaticPropertyRow({
		label = props.label,
		value = string.format(props.format or "%.1f", props.value),
		onEdit = function(newValue)
			local num = tonumber(newValue)
			if num and (not props.min or num > props.min) then
				props.onEdit(num)
			end
		end,
	})
end

local function createSectionHeader(text: string)
	return create("TextLabel")({
		Size = UDim2.new(1, -10, 0, 25),
		BackgroundColor3 = Color3.fromRGB(50, 50, 53),
		Text = text,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(220, 220, 220),
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,

		create("UIPadding")({
			PaddingLeft = UDim.new(0, 10),
		}),
	})
end

local function InspectPhysicsObject(entityId: string, objectId: string)
	local physicsObject = EditorState.getPhysicsObject(entityId, objectId)
	if not physicsObject then
		return {}
	end

	return {
		createSectionHeader("PhysicsObject"),

		createStaticPropertyRow({
			label = "Name",
			value = physicsObject.name,
			onEdit = function(newValue)
				EditorState.updatePhysicsObject(entityId, objectId, { name = newValue })
			end,
		}),

		createNumericPropertyRow({
			label = "Pos X",
			value = physicsObject.position.x,
			onEdit = function(num)
				EditorState.updatePhysicsObject(entityId, objectId, {
					position = vector.create(num, physicsObject.position.y, 0),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "Pos Y",
			value = physicsObject.position.y,
			onEdit = function(num)
				EditorState.updatePhysicsObject(entityId, objectId, {
					position = vector.create(physicsObject.position.x, num, 0),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "Width",
			value = physicsObject.halfExtents.x * 2,
			min = 0,
			onEdit = function(num)
				EditorState.updatePhysicsObject(entityId, objectId, {
					halfExtents = vector.create(num / 2, physicsObject.halfExtents.y, 0),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "Height",
			value = physicsObject.halfExtents.y * 2,
			min = 0,
			onEdit = function(num)
				EditorState.updatePhysicsObject(entityId, objectId, {
					halfExtents = vector.create(physicsObject.halfExtents.x, num / 2, 0),
				})
			end,
		}),
	}
end

local function InspectImageEntity(entityId: string)
	local entity = EditorState.getEntity(entityId)
	if not entity then
		return {}
	end

	return {
		createSectionHeader("Image Entity"),

		createStaticPropertyRow({
			label = "Name",
			value = entity.name,
			onEdit = function(newValue)
				EditorState.updateEntity(entityId, { name = newValue })
			end,
		}),

		createStaticPropertyRow({
			label = "Image ID",
			value = entity.textureId,
			onEdit = function(newValue)
				EditorState.updateEntity(entityId, { textureId = newValue })
			end,
		}),

		createNumericPropertyRow({
			label = "Pos X",
			value = entity.position.x,
			onEdit = function(num)
				EditorState.updateEntity(entityId, {
					position = vector.create(num, entity.position.y, 0),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "Pos Y",
			value = entity.position.y,
			onEdit = function(num)
				EditorState.updateEntity(entityId, {
					position = vector.create(entity.position.x, num, 0),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "Width",
			value = entity.size.x,
			min = 0,
			onEdit = function(num)
				EditorState.updateEntity(entityId, {
					size = vector.create(num, entity.size.y, 0),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "Height",
			value = entity.size.y,
			min = 0,
			onEdit = function(num)
				EditorState.updateEntity(entityId, {
					size = vector.create(entity.size.x, num, 0),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "ImageRect Offset X",
			value = entity.imageRectOffset and entity.imageRectOffset.x or 0,
			format = "%.0f",
			onEdit = function(num)
				local offset = entity.imageRectOffset or Vector2.new(0, 0)
				EditorState.updateEntity(entityId, {
					imageRectOffset = Vector2.new(num, offset.Y),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "ImageRect Offset Y",
			value = entity.imageRectOffset and entity.imageRectOffset.y or 0,
			format = "%.0f",
			onEdit = function(num)
				local offset = entity.imageRectOffset or Vector2.new(0, 0)
				EditorState.updateEntity(entityId, {
					imageRectOffset = Vector2.new(offset.X, num),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "ImageRect Size X",
			value = entity.imageRectSize and entity.imageRectSize.x or 0,
			format = "%.0f",
			min = -1,
			onEdit = function(num)
				local size = entity.imageRectSize or Vector2.new(0, 0)
				EditorState.updateEntity(entityId, {
					imageRectSize = Vector2.new(num, size.Y),
				})
			end,
		}),

		createNumericPropertyRow({
			label = "ImageRect Size Y",
			value = entity.imageRectSize and entity.imageRectSize.y or 0,
			format = "%.0f",
			min = -1,
			onEdit = function(num)
				local size = entity.imageRectSize or Vector2.new(0, 0)
				EditorState.updateEntity(entityId, {
					imageRectSize = Vector2.new(size.X, num),
				})
			end,
		}),
	}
end

local function InspectNothing()
	return {
		create("TextLabel")({
			Size = UDim2.new(1, -20, 0, 50),
			Position = UDim2.fromOffset(10, 40),
			BackgroundTransparency = 1,
			Text = "No selection.\nSelect an entity or physics object.",
			TextSize = 12,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LayoutOrder = 2,
		}),
	}
end

return function()
	local state = EditorState.get()

	return create("ScrollingFrame")({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		create("TextLabel")({
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "Properties",
			TextSize = 13,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 0,

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 10),
			}),
		}),

		function()
			local selectedEntityId = state.selectedEntityId()
			local selectedPhysicsObjectId = state.selectedPhysicsObjectId()

			if selectedPhysicsObjectId and selectedEntityId then
				return InspectPhysicsObject(selectedEntityId, selectedPhysicsObjectId)
			elseif selectedEntityId then
				return InspectImageEntity(selectedEntityId)
			else
				return InspectNothing()
			end
		end,
	})
end
