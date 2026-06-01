--!strict
--[[
	BiomeGenerator — deterministic world generation using layered noise
	and a Whittaker diagram for biome selection.
]]

local Xoshiro = require(script.Parent.Xoshiro)
local Biome = require(script.Parent.Biome)
local WorldMap = require(script.Parent.WorldMap)

local BiomeGenerator = {}
BiomeGenerator.__index = BiomeGenerator

export type BiomeGenerator = typeof(setmetatable(
	{} :: {
		_seed: number,
		_rng: Xoshiro.Xoshiro,
	},
	{} :: typeof({ __index = BiomeGenerator })
))

--[[
	Simple value noise with smooth interpolation.
	Uses the PRNG to build a hash grid and cosine interpolation.
]]

local function makeNoiseLayer(rng: Xoshiro.Xoshiro, scale: number)
	-- Pre-generate a grid of random values
	local gridSize = math.ceil(256 / scale) + 2
	local grid = {}
	for gy = 1, gridSize do
		grid[gy] = {}
		for gx = 1, gridSize do
			grid[gy][gx] = rng:next()
		end
	end

	return function(x: number, y: number): number
		-- Map world coords to grid coords
		local gx = x / scale + 1
		local gy = y / scale + 1
		local ix = math.floor(gx)
		local iy = math.floor(gy)
		local fx = gx - ix
		local fy = gy - iy

		-- Cosine interpolation
		local sx = (1 - math.cos(fx * math.pi)) * 0.5
		local sy = (1 - math.cos(fy * math.pi)) * 0.5

		-- Wrap grid indices
		local x0 = ((ix - 1) % #grid[1]) + 1
		local x1 = (ix % #grid[1]) + 1
		local y0 = ((iy - 1) % #grid) + 1
		local y1 = (iy % #grid) + 1

		local top = grid[y0][x0] * (1 - sx) + grid[y0][x1] * sx
		local bottom = grid[y1][x0] * (1 - sx) + grid[y1][x1] * sx
		return top * (1 - sy) + bottom * sy
	end
end

--[[
	Fractal noise — sums multiple octaves of value noise.
]]
local function makeFractalNoise(rng: Xoshiro.Xoshiro, baseScale: number, octaves: number)
	local layers = {}
	for i = 1, octaves do
		local scale = baseScale / (2 ^ (i - 1))
		local layer = makeNoiseLayer(rng, scale)
		table.insert(layers, { fn = layer, amplitude = 1 / (2 ^ (i - 1)) })
	end

	return function(x: number, y: number): number
		local sum = 0
		local totalAmp = 0
		for _, layer in layers do
			sum = sum + layer.fn(x, y) * layer.amplitude
			totalAmp = totalAmp + layer.amplitude
		end
		return sum / totalAmp
	end
end

--[[
	Whittaker diagram biome selection.
	Maps temperature + moisture + elevation to a biome name.
]]
local function selectBiome(temp: number, moisture: number, elevation: number): string
	-- Ocean: very low elevation
	if elevation < 0.1 then
		return "Ocean"
	end

	-- Volcano: very high elevation + hot
	if elevation > 0.7 and temp > 40 then
		return "Volcano"
	end

	-- FloatingIslands: very high elevation + moderate temp
	if elevation > 0.75 then
		return "FloatingIslands"
	end

	-- Tundra: very cold
	if temp < -5 then
		return "Tundra"
	end

	-- Desert: hot + dry
	if temp > 35 and moisture < 0.2 then
		return "Desert"
	end

	-- Mushroom Grove: warm + very wet
	if temp > 18 and moisture > 0.7 then
		return "MushroomGrove"
	end

	-- Forest: moderate temp + wet
	if temp > 8 and temp <= 28 and moisture > 0.55 then
		return "Forest"
	end

	-- Crystal Caves: low elevation + moderate
	if elevation < 0.2 and temp > 5 and temp < 20 and moisture >= 0.3 and moisture < 0.65 then
		return "CrystalCaves"
	end

	-- Ancient Ruins: mid elevation + moderate temp + moderate moisture
	if elevation >= 0.25 and elevation < 0.6 and moisture >= 0.15 and moisture < 0.5 and temp >= 15 then
		return "AncientRuins"
	end

	-- Default: Meadow
	return "Meadow"
end

function BiomeGenerator.new(seed: number?): BiomeGenerator
	local s = seed or 42
	local rng = Xoshiro.new(s)
	return setmetatable({
		_seed = s,
		_rng = rng,
	}, BiomeGenerator)
end

function BiomeGenerator:generate(width: number, height: number): WorldMap.WorldMap
	-- Create separate RNGs seeded deterministically from the main one
	-- so that each noise layer is independent but reproducible
	local tempSeed = self._rng:nextInt(1, 1000000)
	local moistSeed = self._rng:nextInt(1, 1000000)
	local elevSeed = self._rng:nextInt(1, 1000000)

	local tempRng = Xoshiro.new(tempSeed)
	local moistRng = Xoshiro.new(moistSeed)
	local elevRng = Xoshiro.new(elevSeed)

	-- Create noise layers
	local tempNoise = makeNoiseLayer(tempRng, 32)
	local moistNoise = makeFractalNoise(moistRng, 24, 3)
	local elevNoise = makeFractalNoise(elevRng, 28, 4)

	-- Generate grid
	local biomes: { { string } } = {}
	local temperatures: { { number } } = {}
	local moistures: { { number } } = {}
	local elevations: { { number } } = {}

	for y = 1, height do
		biomes[y] = {}
		temperatures[y] = {}
		moistures[y] = {}
		elevations[y] = {}
		for x = 1, width do
			-- Temperature: latitude-based + noise
			-- Poles are cold, equator is hot
			local latitude = math.abs(y - height / 2) / (height / 2) -- 0 at equator, 1 at poles
			local baseTemp = 45 * (1 - latitude) - 15 -- range: -15 to 30
			local tempNoiseVal = tempNoise(x, y) * 30 - 15 -- range: -15 to 15
			local temp = baseTemp + tempNoiseVal

			-- Moisture: fractal noise, clamped to [0, 1]
			local moist = math.clamp(moistNoise(x, y), 0, 1)

			-- Elevation: fractal noise, clamped to [0, 1]
			local elev = math.clamp(elevNoise(x, y), 0, 1)

			local biome = selectBiome(temp, moist, elev)

			temperatures[y][x] = temp
			moistures[y][x] = moist
			elevations[y][x] = elev
			biomes[y][x] = biome
		end
	end

	return WorldMap.new(width, height, biomes, temperatures, moistures, elevations)
end

return BiomeGenerator
