--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create

local function Zoom()
	local state = EditorState.get()
	local function ZoomButton(props)
		return create("TextButton")({
			Size = UDim2.fromOffset(30, 30),
			Text = props.Text,
			TextScaled = true,
			BackgroundColor3 = Color3.fromRGB(70, 70, 70),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,

			Activated = props.OnClick,
		})
	end

	return create("Frame")({
		Name = "ZoomControls",
		Position = UDim2.new(1, -150, 1, -50),
		Size = UDim2.fromOffset(140, 40),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderSizePixel = 0,

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 5),
		}),

		create("UIPadding")({
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),

		ZoomButton({
			Text = "-",
			OnClick = function()
				EditorState.setZoom(state.zoom() * 0.8)
			end,
		}),

		create("TextLabel")({
			Size = UDim2.fromOffset(50, 30),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = function()
				return string.format("%d%%", math.floor(state.zoom() * 100))
			end,
			TextScaled = true,
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		ZoomButton({
			Text = "+",
			OnClick = function()
				EditorState.setZoom(state.zoom() * 1.25)
			end,
		}),
	})
end

return Zoom
