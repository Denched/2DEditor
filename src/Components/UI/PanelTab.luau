--# selene: allow(mixed_table)

local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local source = vide.source

local TAB_HEIGHT = 22

return function(props: {
	title: string,
	onClose: () -> (),
	children: any,
	headerActions: any?,
})
	local isCloseHovered = source(false)

	return create("Frame")({
		Name = "PanelTab_" .. props.title,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(37, 37, 37),
		BorderSizePixel = 0,

		create("Frame")({
			Name = "TabHeader",
			Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
			BackgroundColor3 = Color3.fromRGB(48, 48, 48),
			BorderSizePixel = 0,

			create("Frame")({
				Name = "BottomBorder",
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Color3.fromRGB(28, 28, 28),
				BorderSizePixel = 0,
			}),

			create("TextLabel")({
				Name = "Title",
				Size = UDim2.new(1, -50, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				BackgroundTransparency = 1,
				Text = props.title,
				TextSize = 11,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),

			props.headerActions,

			create("TextButton")({
				Name = "CloseButton",
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(1, -20, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = function()
					if isCloseHovered() then
						return Color3.fromRGB(180, 60, 60)
					end
					return Color3.fromRGB(70, 70, 75)
				end,
				BackgroundTransparency = function()
					if isCloseHovered() then
						return 0
					end
					return 0.5
				end,
				BorderSizePixel = 0,
				Text = "×",
				TextSize = 12,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				MouseEnter = function()
					isCloseHovered(true)
				end,
				MouseLeave = function()
					isCloseHovered(false)
				end,
				MouseButton1Click = props.onClose,

				create("UICorner")({
					CornerRadius = UDim.new(0, 3),
				}),
			}),
		}),

		create("Frame")({
			Name = "Content",
			Size = UDim2.new(1, 0, 1, -TAB_HEIGHT),
			Position = UDim2.fromOffset(0, TAB_HEIGHT),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			props.children,
		}),
	})
end
