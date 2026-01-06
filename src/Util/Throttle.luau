local function throttle(func: (...any) -> any, delay: number)
	local lastCall = 0
	local pending = false
	local timer = nil
	local args = nil

	return function(...)
		local now = os.clock()
		args = { ... }

		if now - lastCall >= delay then
			lastCall = now
			func(...)
		elseif not pending then
			pending = true
			if timer then
				task.cancel(timer)
			end
			timer = task.delay(delay - (now - lastCall), function()
				pending = false
				lastCall = os.clock()
				if args then
					func(table.unpack(args))
				end
				timer = nil
			end)
		end
	end
end

local function debounce(func: (...any) -> any, delay: number)
	local timer = nil

	return function(...)
		local args = { ... }

		if timer then
			task.cancel(timer)
		end

		timer = task.delay(delay, function()
			timer = nil
			func(table.unpack(args))
		end)
	end
end

return {
	throttle = throttle,
	debounce = debounce,
}
