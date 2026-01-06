--# selene: allow(mixed_table)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create

return function()
	return create("Frame")({
		Name = "ImageRenderer",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = ZIndexes.Entities,

		function()
			local state = EditorState.get()
			local entities = state.entities()
			local zoom = state.zoom()
			local offset = state.viewportOffset()
			local images = {}

			for _, entity in entities do
				local screenPos =
					vector.create(entity.position.x * zoom + offset.x, entity.position.y * zoom + offset.y, 0)

				local screenSize = vector.create(entity.size.x * zoom, entity.size.y * zoom, 0)

				local imageLabel = create("ImageLabel")({
					Name = entity.name,
					Position = UDim2.fromOffset(screenPos.x, screenPos.y),
					Size = UDim2.fromOffset(screenSize.x, screenSize.y),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = "rbxassetid://" .. entity.textureId,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = ZIndexes.Entities,
					ScaleType = Enum.ScaleType.Fit,
					ImageRectOffset = if entity.imageRectOffset
						then Vector2.new(entity.imageRectOffset.x, entity.imageRectOffset.y)
						else Vector2.new(0, 0),
					ImageRectSize = if entity.imageRectSize
							and (entity.imageRectSize.x > 0 or entity.imageRectSize.y > 0)
						then Vector2.new(entity.imageRectSize.x, entity.imageRectSize.y)
						else Vector2.new(0, 0),
				})

				table.insert(images, imageLabel)
			end

			return images
		end,
	})
end
