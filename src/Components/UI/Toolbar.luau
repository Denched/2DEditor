--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local function Toolbar()
	local state = EditorState.get()
	return create("Frame")({
		Name = "Toolbar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		BorderSizePixel = 0,

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		create("UIPadding")({
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
		}),

		create("TextButton")({
			Size = UDim2.fromOffset(80, 30),
			Text = "Axes",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundColor3 = function()
				return state.gridVisible() and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(50, 50, 50)
			end,
			BorderSizePixel = 0,
			LayoutOrder = 1,

			Activated = function()
				state.gridVisible(not state.gridVisible())
			end,
		}),

		create("TextButton")({
			Size = UDim2.fromOffset(100, 30),
			Text = "Reset View",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			BorderSizePixel = 0,
			LayoutOrder = 2,

			Activated = function()
				EditorState.resetView()
			end,
		}),
	})
end

return Toolbar
