--# selene: allow(mixed_table)

local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create

local RULER_SIZE = 20

return function()
	return create("Frame")({
		Name = "RulerCorner",
		Size = UDim2.fromOffset(RULER_SIZE, RULER_SIZE),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(70, 70, 70),
		ZIndex = ZIndexes.RulerCorner,

		create("TextLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "×",
			TextSize = 12,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			Font = Enum.Font.GothamBold,
		}),
	})
end
