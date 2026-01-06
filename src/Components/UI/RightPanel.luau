--# selene: allow(mixed_table)

local Inspector = require(script.Parent.Inspector)
local PanelTab = require(script.Parent.PanelTab)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create

return function()
	return create("Frame")({
		Name = "RightPanel",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(37, 37, 37),
		BorderSizePixel = 0,

		create("Frame")({
			Name = "LeftBorder",
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = Color3.fromRGB(28, 28, 28),
			BorderSizePixel = 0,
		}),

		PanelTab({
			title = "Inspector",
			onClose = function()
				EditorState.hideInspector()
			end,
			children = create("Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,

				Inspector(),
			}),
		}),
	})
end
