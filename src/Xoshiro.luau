--!strict
--[[
	Xoshiro256** PRNG — deterministic pseudo-random number generator.
	Port of xoshiro256** for Luau/Roblox.
]]

local type XoshiroState = { number, number, number, number }

local Xoshiro = {}
Xoshiro.__index = Xoshiro

export type Xoshiro = typeof(setmetatable(
	{} :: {
		_state: XoshiroState,
	},
	{} :: typeof({ __index = Xoshiro })
))

--[[
	SplitMix64 step — used to seed the 256-bit state from a single number.
]]
local function splitMix64(x: number): () -> number
	return function()
		x = (x + 0x9E3779B97F4A7C15) % (2 ^ 63)
		local z = x
		z = ((z >> 30) * x) % (2 ^ 63) -- bit rotate + multiply approximation
		-- Use bit32 for 32-bit operations, combine for 64-bit feel
		local lo = math.floor(z % (2 ^ 32))
		local hi = math.floor(z / (2 ^ 32)) % (2 ^ 32)
		-- Mix
		lo = bit32.bxor(lo, bit32.rshift(lo, 30) * 0xBF58476D1CE4E5B9 % (2 ^ 32))
		lo = (lo * 0x94D049BB133111EB) % (2 ^ 32)
		lo = bit32.bxor(lo, bit32.rshift(lo, 31))
		return lo / (2 ^ 32)
	end
end

--[[
	Rotate left (32-bit).
]]
local function rotl(x: number, k: number): number
	return bit32.bor(bit32.lshift(x, k), bit32.rshift(x, 32 - k))
end

function Xoshiro.new(seed: number?): Xoshiro
	local s: XoshiroState = { 0, 0, 0, 0 }
	local seedVal = seed or 1234567890
	local gen = splitMix64(seedVal)
	for i = 1, 4 do
		s[i] = gen()
	end
	return setmetatable({ _state = s }, Xoshiro)
end

--[[
	Generate the next random number in [0, 1).
]]
function Xoshiro:next(): number
	local s = self._state
	-- xoshiro256** core
	local result = rotl(s[1] * 5 % (2 ^ 32), 7) * 9 % (2 ^ 32)
	local t = bit32.lshift(s[2], 17)

	s[2] = bit32.bxor(s[2], s[3])
	s[3] = bit32.bxor(s[3], s[4])
	s[4] = bit32.bxor(s[4], s[1])

	s[1] = bit32.bxor(s[1], t)
	s[2] = bit32.bxor(s[2], rotl(s[2], 45))

	return result / (2 ^ 32)
end

--[[
	Generate a random integer in [min, max].
]]
function Xoshiro:nextInt(min: number, max: number): number
	local range = max - min + 1
	return math.floor(min + self:next() * range)
end

return Xoshiro
