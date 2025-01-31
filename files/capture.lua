-- Copyright (c) 2019-2020 David Vogel
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

CAPTURE_PIXEL_SIZE = 1 -- Screen to virtual pixel ratio
CAPTURE_GRID_SIZE = 512 -- in ingame pixels. There will always be exactly 4 images overlapping if the virtual resolution is 1024x1024
CAPTURE_FORCE_HP = 4 -- * 25HP

-- "Base layout" (Base layout. Every part outside this is based on a similar layout, but uses different materials/seeds)
CAPTURE_AREA_BASE_LAYOUT = {
	Left = -17920, -- in ingame pixels.
	Top = -7168, -- in ingame pixels.
	Right = 17920, -- in ingame pixels. (Coordinate is not included in the rectangle)
	Bottom = 17408 -- in ingame pixels. (Coordinate is not included in the rectangle)
}

-- "Main world" (The main world with 3 parts: sky, normal and hell)
CAPTURE_AREA_MAIN_WORLD = {
	Left = -17920, -- in ingame pixels.
	Top = -31744, -- in ingame pixels.
	Right = 17920, -- in ingame pixels. (Coordinate is not included in the rectangle)
	Bottom = 41984 -- in ingame pixels. (Coordinate is not included in the rectangle)
}

-- "Extended" (Main world + a fraction of the parallel worlds to the left and right)
CAPTURE_AREA_EXTENDED = {
	Left = -25600, -- in ingame pixels.
	Top = -31744, -- in ingame pixels.
	Right = 25600, -- in ingame pixels. (Coordinate is not included in the rectangle)
	Bottom = 41984 -- in ingame pixels. (Coordinate is not included in the rectangle)
}

CAPTURE_BG_EXTENDED = {
	Left = -53760, -- in ingame pixels.
	Top = -63488, -- in ingame pixels.
	Right = 53760, -- in ingame pixels. (Coordinate is not included in the rectangle)
	Bottom = 83968 -- in ingame pixels. (Coordinate is not included in the rectangle)
}

local function preparePlayer()
	local playerEntity = getPlayer()
	addEffectToEntity(playerEntity, "PROTECTION_ALL")

	--addPerkToPlayer("BREATH_UNDERWATER")
	--addPerkToPlayer("INVISIBILITY")
	--addPerkToPlayer("REMOVE_FOG_OF_WAR")
	--addPerkToPlayer("REPELLING_CAPE")
	--addPerkToPlayer("WORM_DETRACTOR")
	setPlayerHP(CAPTURE_FORCE_HP)
	
	local CharacterPlatforming = EntityGetFirstComponentIncludingDisabled(
    playerEntity,
    "CharacterPlatformingComponent"
  )

  EntitySetComponentIsEnabled(playerEntity, CharacterPlatforming, false)
end

local function captureScreenshot(x, y, rx, ry)
	local virtualWidth, virtualHeight =
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")),
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))

	local virtualHalfWidth, virtualHalfHeight = math.floor(virtualWidth / 2), math.floor(virtualHeight / 2)
	local xMin, yMin = x - virtualHalfWidth, y - virtualHalfHeight
	local xMax, yMax = xMin + virtualWidth, yMin + virtualHeight

	UiCaptureDelay = 0
	
	wait(0)
	GameSetCameraPos(x + 200, y + 200)
	wait(0)
	GameSetCameraPos(x - 200, y + 200)
	wait(0)
	GameSetCameraPos(x + 200, y - 200)
	wait(0)
	GameSetCameraPos(x - 200, y - 200)
	wait(0)
	
	
	GameSetCameraPos(x, y)
	repeat
		if UiCaptureDelay > 5 then
			-- Wiggle the screen a bit, as chunks sometimes don't want to load
			GameSetCameraPos(x + math.random(-100, 100), y + math.random(-100, 100))
			DrawUI()
			wait(0)
			UiCaptureDelay = UiCaptureDelay + 1
			GameSetCameraPos(x, y)
		end

		DrawUI()
		wait(0)
		UiCaptureDelay = UiCaptureDelay + 1
	until DoesWorldExistAt(xMin, yMin, xMax, yMax) -- Chunks will be drawn on the *next* frame

	wait(0) -- Without this line empty chunks may still appear, also it's needed for the UI to disappear
	if not TriggerCapture(rx, ry) then
		UiCaptureProblem = "Screen capture failed. Please restart Noita."
	end

	-- Reset monitor and PC standby each screenshot
	ResetStandbyTimer()
end

function startCapturingSpiral()
	local ox, oy = GameGetCameraPos()
	ox, oy = math.floor(ox / CAPTURE_GRID_SIZE) * CAPTURE_GRID_SIZE, math.floor(oy / CAPTURE_GRID_SIZE) * CAPTURE_GRID_SIZE
	ox, oy = ox + 256, oy + 256 -- Align screen with ingame chunk grid that is 512x512
	local x, y = ox, oy

	local virtualWidth, virtualHeight =
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")),
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))

	local virtualHalfWidth, virtualHalfHeight = math.floor(virtualWidth / 2), math.floor(virtualHeight / 2)

	preparePlayer()

	GameSetCameraFree(true)

	-- Coroutine to calculate next coordinate, and trigger screenshots
	local i = 1
	async_loop(
		function()
			-- +x
			for i = 1, i, 1 do
				local rx, ry = x * CAPTURE_PIXEL_SIZE - virtualHalfWidth, y * CAPTURE_PIXEL_SIZE - virtualHalfHeight
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					captureScreenshot(x, y, rx, ry)
				end
				x, y = x + CAPTURE_GRID_SIZE, y
			end
			-- +y
			for i = 1, i, 1 do
				local rx, ry = x * CAPTURE_PIXEL_SIZE - virtualHalfWidth, y * CAPTURE_PIXEL_SIZE - virtualHalfHeight
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					captureScreenshot(x, y, rx, ry)
				end
				x, y = x, y + CAPTURE_GRID_SIZE
			end
			i = i + 1
			-- -x
			for i = 1, i, 1 do
				local rx, ry = x * CAPTURE_PIXEL_SIZE - virtualHalfWidth, y * CAPTURE_PIXEL_SIZE - virtualHalfHeight
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					captureScreenshot(x, y, rx, ry)
				end
				x, y = x - CAPTURE_GRID_SIZE, y
			end
			-- -y
			for i = 1, i, 1 do
				local rx, ry = x * CAPTURE_PIXEL_SIZE - virtualHalfWidth, y * CAPTURE_PIXEL_SIZE - virtualHalfHeight
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					captureScreenshot(x, y, rx, ry)
				end
				x, y = x, y - CAPTURE_GRID_SIZE
			end
			i = i + 1
		end
	)
end

function startCapturingHilbert(area)
	local ox, oy = GameGetCameraPos()

	local virtualWidth, virtualHeight =
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")),
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))

	local virtualHalfWidth, virtualHalfHeight = math.floor(virtualWidth / 2), math.floor(virtualHeight / 2)

	-- Get size of the rectangle in grid/chunk coordinates
	local gridLeft = math.floor(area.Left / CAPTURE_GRID_SIZE)
	local gridTop = math.floor(area.Top / CAPTURE_GRID_SIZE)
	local gridRight = math.ceil(area.Right / CAPTURE_GRID_SIZE) -- This grid coordinate is not included
	local gridBottom = math.ceil(area.Bottom / CAPTURE_GRID_SIZE) -- This grid coordinate is not included

	-- Edge case
	if area.Left == area.Right then
		gridRight = gridLeft
	end
	if area.Top == area.Bottom then
		gridBottom = gridTop
	end

	-- Size of the grid in chunks
	local gridWidth = gridRight - gridLeft
	local gridHeight = gridBottom - gridTop

	-- Hilbert curve can only fit into a square, so get the longest side
	local gridPOTSize = math.ceil(math.log(math.max(gridWidth, gridHeight)) / math.log(2))
	-- Max size (Already rounded up to the next power of two)
	local gridMaxSize = math.pow(2, gridPOTSize)

	local t, tLimit = 0, gridMaxSize * gridMaxSize

	UiProgress = {Progress = 0, Max = gridWidth * gridHeight}

	preparePlayer()

	GameSetCameraFree(true)

	-- Coroutine to calculate next coordinate, and trigger screenshots
	async(
		function()
			while t < tLimit do
				local hx, hy = mapHilbert(t, gridPOTSize)
				if hx < gridWidth and hy < gridHeight then
					local x, y = (hx + gridLeft) * CAPTURE_GRID_SIZE, (hy + gridTop) * CAPTURE_GRID_SIZE
					x, y = x + 256, y + 256 -- Align screen with ingame chunk grid that is 512x512
					local rx, ry = x * CAPTURE_PIXEL_SIZE - virtualHalfWidth, y * CAPTURE_PIXEL_SIZE - virtualHalfHeight
					if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
						captureScreenshot(x, y, rx, ry)
					end
					UiProgress.Progress = UiProgress.Progress + 1
				end

				t = t + 1
			end

			UiProgress.Done = true
		end
	)
end
