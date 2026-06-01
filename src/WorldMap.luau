--!strict
--[[
	WorldMap — stores a generated 2D grid of biomes with query methods.
]]

local Biome = require(script.Parent.Biome)

local WorldMap = {}
WorldMap.__index = WorldMap

export type WorldMap = typeof(setmetatable(
	{} :: {
		_width: number,
		_height: number,
		_biomes: { { string } },
		_temperatures: { { number } },
		_moistures: { { number } },
		_elevations: { { number } },
	},
	{} :: typeof({ __index = WorldMap })
))

function WorldMap.new(
	width: number,
	height: number,
	biomes: { { string } },
	temperatures: { { number } },
	moistures: { { number } },
	elevations: { { number } }
): WorldMap
	return setmetatable({
		_width = width,
		_height = height,
		_biomes = biomes,
		_temperatures = temperatures,
		_moistures = moistures,
		_elevations = elevations,
	}, WorldMap)
end

function WorldMap:width(): number
	return self._width
end

function WorldMap:height(): number
	return self._height
end

function WorldMap:biomeAt(x: number, y: number): string
	assert(x >= 1 and x <= self._width, string.format("x out of bounds: %d (1-%d)", x, self._width))
	assert(y >= 1 and y <= self._height, string.format("y out of bounds: %d (1-%d)", y, self._height))
	return self._biomes[y][x]
end

function WorldMap:temperatureAt(x: number, y: number): number
	assert(x >= 1 and x <= self._width, string.format("x out of bounds: %d (1-%d)", x, self._width))
	assert(y >= 1 and y <= self._height, string.format("y out of bounds: %d (1-%d)", y, self._height))
	return self._temperatures[y][x]
end

function WorldMap:moistureAt(x: number, y: number): number
	assert(x >= 1 and x <= self._width, string.format("x out of bounds: %d (1-%d)", x, self._width))
	assert(y >= 1 and y <= self._height, string.format("y out of bounds: %d (1-%d)", y, self._height))
	return self._moistures[y][x]
end

function WorldMap:elevationAt(x: number, y: number): number
	assert(x >= 1 and x <= self._width, string.format("x out of bounds: %d (1-%d)", x, self._width))
	assert(y >= 1 and y <= self._height, string.format("y out of bounds: %d (1-%d)", y, self._height))
	return self._elevations[y][x]
end

function WorldMap:resourcesAt(x: number, y: number): { string }
	local biomeName = self:biomeAt(x, y)
	local props = Biome.fromName(biomeName)
	if props then
		return props.resources
	end
	return {}
end

return WorldMap
