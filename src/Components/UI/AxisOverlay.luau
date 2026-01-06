--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)
local vide = require(script.Parent.Parent.Parent.Packages.vide)
local REFERENCE_SIZE = vector.create(640, 360, 0)

local create = vide.create

local function Axis()
	local state = EditorState.get()

	return create("Frame")({
		Name = "AxisOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,

		create("Frame")({
			Name = "XAxis",
			BackgroundColor3 = Color3.new(1, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 2),
			Position = function()
				local offset = state.viewportOffset()
				return UDim2.fromOffset(0, offset.Y)
			end,
		}),

		create("Frame")({
			Name = "YAxis",
			BackgroundColor3 = Color3.new(0.227451, 0.945098, 0.082353),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 2, 1, 0),
			Position = function()
				local offset = state.viewportOffset()
				return UDim2.fromOffset(offset.X, 0)
			end,
		}),

		create("Frame")({
			Name = "ReferenceRect",
			BackgroundTransparency = 0.9,
			BackgroundColor3 = Color3.fromRGB(120, 120, 220),
			BorderColor3 = Color3.fromRGB(150, 150, 255),
			BorderSizePixel = 2,
			ZIndex = ZIndexes.ReferenceRect,
			Size = function()
				local zoom = state.zoom()
				return UDim2.fromOffset(REFERENCE_SIZE.X * zoom, REFERENCE_SIZE.Y * zoom)
			end,
			Position = function()
				local offset = state.viewportOffset()
				return UDim2.fromOffset(offset.X, offset.Y)
			end,
		}),
	})
end

return Axis
