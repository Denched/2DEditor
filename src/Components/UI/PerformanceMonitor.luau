--# selene: allow(mixed_table)

local RunService = game:GetService("RunService")
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local source = vide.source

return function()
	local fps = source(0)
	local memory = source(0)
	local renderTime = source(0)

	local lastUpdate = os.clock()
	local frameCount = 0

	local connection = RunService.Heartbeat:Connect(function(a0: number)
		frameCount += 1

		local now = os.clock()

		if now - lastUpdate >= 0.5 then
			fps(math.floor(frameCount / (now - lastUpdate)))
			memory(math.floor(gcinfo() / 1024))
			renderTime(math.floor(a0 * 1000))

			frameCount = 0
			lastUpdate = now
		end
	end)

	vide.cleanup(function()
		connection:Disconnect()
	end)

	return create("Frame")({
		Name = "PerformanceMonitor",
		Size = UDim2.fromOffset(200, 80),
		Position = UDim2.new(1, -210, 0, 10),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,

		create("UICorner")({
			CornerRadius = UDim.new(0, 4),
		}),

		create("UIPadding")({
			PaddingTop = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
		}),

		create("TextLabel")({
			Name = "FPS",
			Size = UDim2.new(1, -8, 0, 20),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Code,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(100, 255, 100),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `FPS: {fps()}`
			end,
		}),

		create("TextLabel")({
			Name = "Memory",
			Size = UDim2.new(1, -8, 0, 20),
			Position = UDim2.fromOffset(0, 25),
			BackgroundTransparency = 1,
			Font = Enum.Font.Code,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 200, 100),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `Memory: {memory()} MB`
			end,
		}),

		create("TextLabel")({
			Name = "RenderTime",
			Size = UDim2.new(1, -8, 0, 20),
			Position = UDim2.fromOffset(0, 50),
			BackgroundTransparency = 1,
			Font = Enum.Font.Code,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(100, 200, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `Render: {renderTime()} ms`
			end,
		}),
	})
end
