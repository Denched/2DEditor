--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create

local RULER_SIZE = 20
local MAJOR_TICK_HEIGHT = 10
local MINOR_TICK_HEIGHT = 5

local function getTickIntervals(zoom: number): (number, number, boolean)
	local targetPixelSpacing = 100

	local worldUnitsPerTarget = targetPixelSpacing / zoom

	local intervals = { 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000 }
	local majorInterval = 100

	for _, interval in ipairs(intervals) do
		if interval >= worldUnitsPerTarget then
			majorInterval = interval
			break
		end
	end

	local minorInterval = majorInterval / 5

	local showMinorTicks = minorInterval * zoom >= 10

	return majorInterval, minorInterval, showMinorTicks
end

local function createTicks(isHorizontal: boolean, offset: vector, zoom: number, viewportDimension: number)
	local ticks = {}

	local offsetValue = if isHorizontal then offset.x else offset.y

	local majorInterval, minorInterval, showMinorTicks = getTickIntervals(zoom)

	local startWorld = -offsetValue / zoom
	local endWorld = (viewportDimension - offsetValue) / zoom

	local iterationInterval = showMinorTicks and minorInterval or majorInterval
	local startTick = math.floor(startWorld / iterationInterval) * iterationInterval
	local endTick = math.ceil(endWorld / iterationInterval) * iterationInterval

	for worldPos = startTick, endTick, iterationInterval do
		local screenPos = worldPos * zoom + offsetValue

		if screenPos < -10 or screenPos > viewportDimension + 10 then
			continue
		end

		local isMajor = worldPos % majorInterval == 0
		local tickHeight = isMajor and MAJOR_TICK_HEIGHT or MINOR_TICK_HEIGHT

		if isHorizontal then
			table.insert(
				ticks,
				create("Frame")({
					Size = UDim2.fromOffset(1, tickHeight),
					Position = UDim2.fromOffset(screenPos, RULER_SIZE - tickHeight),
					BackgroundColor3 = Color3.fromRGB(180, 180, 180),
					BorderSizePixel = 0,
					ZIndex = 2,
				})
			)
		else
			table.insert(
				ticks,
				create("Frame")({
					Size = UDim2.fromOffset(tickHeight, 1),
					Position = UDim2.fromOffset(RULER_SIZE - tickHeight, screenPos),
					BackgroundColor3 = Color3.fromRGB(180, 180, 180),
					BorderSizePixel = 0,
					ZIndex = 2,
				})
			)
		end

		if isMajor then
			if isHorizontal then
				table.insert(
					ticks,
					create("TextLabel")({
						Size = UDim2.fromOffset(60, RULER_SIZE - MAJOR_TICK_HEIGHT - 2),
						Position = UDim2.fromOffset(screenPos - 30, 2),
						BackgroundTransparency = 1,
						Text = tostring(worldPos),
						TextSize = 10,
						TextColor3 = Color3.fromRGB(220, 220, 220),
						Font = Enum.Font.Code,
						TextXAlignment = Enum.TextXAlignment.Center,
						ZIndex = 2,
					})
				)
			else
				table.insert(
					ticks,
					create("TextLabel")({
						Size = UDim2.fromOffset(RULER_SIZE - MAJOR_TICK_HEIGHT - 2, 20),
						Position = UDim2.fromOffset(2, screenPos - 10),
						BackgroundTransparency = 1,
						Text = tostring(worldPos),
						TextSize = 10,
						TextColor3 = Color3.fromRGB(220, 220, 220),
						Font = Enum.Font.Code,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						ZIndex = 2,
					})
				)
			end
		end
	end

	return ticks
end

return function(props: { isHorizontal: boolean })
	local state = EditorState.get()
	local isHorizontal = props.isHorizontal

	local frame = create("Frame")({
		Name = if isHorizontal then "HorizontalRuler" else "VerticalRuler",
		Size = if isHorizontal
			then UDim2.new(1, -RULER_SIZE, 0, RULER_SIZE)
			else UDim2.new(0, RULER_SIZE, 1, -RULER_SIZE),
		Position = if isHorizontal then UDim2.fromOffset(RULER_SIZE, 0) else UDim2.fromOffset(0, RULER_SIZE),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = ZIndexes.Rulers,

		create("Frame")({
			Name = "Background",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			BorderSizePixel = 1,
			BorderColor3 = Color3.fromRGB(70, 70, 70),
			ZIndex = 1,
		}),

		function()
			local offset = state.viewportOffset()
			local zoom = state.zoom()
			local canvasSize = state.canvasSize()

			local viewportDimension = if isHorizontal then canvasSize.x else canvasSize.y

			local ticks = createTicks(isHorizontal, offset, zoom, viewportDimension)
			return ticks
		end,
	})

	return frame
end
