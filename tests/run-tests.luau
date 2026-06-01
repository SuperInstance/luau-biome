--!strict
--[[
	Test suite for luau-biome — 25+ tests covering all modules.
	Run with: luau tests/run-tests.luau (or inside Roblox Studio test runner)
]]

-- In Roblox, modules are required via script.Parent paths.
-- For standalone testing, we simulate the hierarchy.
-- When running inside Roblox, replace these requires with:
-- local Biome = require(script.Parent.src.Biome)
-- etc.

local Biome
local Xoshiro
local BiomeGenerator
local WorldMap

-- Standalone loading: attempt to find modules relative to this file
-- In Roblox, script.Parent.src.* would be used instead
local ok, err = pcall(function()
	local src = script and script.Parent and script.Parent:FindFirstChild("src")
	if src then
		Biome = require(src:FindFirstChild("Biome"))
		Xoshiro = require(src:FindFirstChild("Xoshiro"))
		BiomeGenerator = require(src:FindFirstChild("BiomeGenerator"))
		WorldMap = require(src:FindFirstChild("WorldMap"))
	end
end)

if not Biome then
	-- Fallback: try relative path loading (for non-Roblox environments)
	-- This allows the test file to be run outside Studio
	error("Could not load modules. Run from within Roblox Studio or provide module paths.")
end

---------------------------------------------------------------------------
-- Test framework
---------------------------------------------------------------------------

local passed = 0
local failed = 0
local total = 0

local function test(name: string, fn: () -> ())
	total = total + 1
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
		print(string.format("  ✅ PASS: %s", name))
	else
		failed = failed + 1
		print(string.format("  ❌ FAIL: %s — %s", name, tostring(err)))
	end
end

local function assertEqual(actual: any, expected: any, msg: string?)
	if actual ~= expected then
		error(string.format("%s\n  expected: %s\n  got: %s", msg or "assertion failed", tostring(expected), tostring(actual)))
	end
end

local function assertInRange(value: number, min: number, max: number, msg: string?)
	if value < min or value > max then
		error(string.format("%s\n  value %f not in [%f, %f]", msg or "out of range", value, min, max))
	end
end

local function assertTrue(condition: boolean, msg: string?)
	if not condition then
		error(msg or "expected true")
	end
end

---------------------------------------------------------------------------
-- Xoshiro tests
---------------------------------------------------------------------------

print("\n=== Xoshiro Tests ===")

test("Xoshiro: same seed produces same sequence", function()
	local a = Xoshiro.new(42)
	local b = Xoshiro.new(42)
	for _ = 1, 100 do
		assertEqual(a:next(), b:next(), "sequences diverged")
	end
end)

test("Xoshiro: different seeds produce different first values", function()
	local a = Xoshiro.new(42)
	local b = Xoshiro.new(99)
	local va = a:next()
	local vb = b:next()
	assertTrue(va ~= vb, string.format("both seeds produced %f", va))
end)

test("Xoshiro: next() returns values in [0, 1)", function()
	local rng = Xoshiro.new(12345)
	for _ = 1, 1000 do
		local v = rng:next()
		assertTrue(v >= 0 and v < 1, string.format("value %f out of [0,1)", v))
	end
end)

test("Xoshiro: nextInt returns integers in range", function()
	local rng = Xoshiro.new(777)
	for _ = 1, 500 do
		local v = rng:nextInt(5, 10)
		assertTrue(v >= 5 and v <= 10, string.format("value %d not in [5,10]", v))
		assertEqual(v, math.floor(v), "not an integer")
	end
end)

test("Xoshiro: deterministic across 10000 calls", function()
	local a = Xoshiro.new(2024)
	local values = {}
	for i = 1, 10000 do
		values[i] = a:next()
	end
	local b = Xoshiro.new(2024)
	for i = 1, 10000 do
		assertEqual(b:next(), values[i], string.format("diverged at call %d", i))
	end
end)

---------------------------------------------------------------------------
-- Biome tests
---------------------------------------------------------------------------

print("\n=== Biome Tests ===")

test("Biome: all() returns 10 biomes", function()
	local all = Biome.all()
	assertEqual(#all, 10, "expected 10 biomes")
end)

test("Biome: all 10 expected biome names exist", function()
	local expected = {
		"Meadow", "Forest", "Desert", "Tundra", "Ocean",
		"Volcano", "CrystalCaves", "FloatingIslands", "MushroomGrove", "AncientRuins",
	}
	local all = Biome.all()
	for _, name in expected do
		local found = false
		for _, n in all do
			if n == name then found = true break end
		end
		assertTrue(found, string.format("biome %s not found in all()", name))
	end
end)

test("Biome: fromName returns properties for each biome", function()
	for _, name in Biome.all() do
		local props = Biome.fromName(name)
		assertTrue(props ~= nil, string.format("fromName(%s) returned nil", name))
		assertEqual(props.name, name, "name mismatch")
	end
end)

test("Biome: fromName returns nil for unknown biome", function()
	local result = Biome.fromName("NonexistentBiome")
	assertEqual(result, nil, "expected nil for unknown biome")
end)

test("Biome: Meadow has correct properties", function()
	local m = Biome.fromName("Meadow")
	assertEqual(m.name, "Meadow")
	assertEqual(m.temperatureRange[1], 15)
	assertEqual(m.temperatureRange[2], 30)
	assertEqual(m.mathematicalTheme, "Fibonacci sequences in flower petal arrangements")
	assertTrue(#m.resources == 4, "expected 4 resources")
end)

test("Biome: Desert has correct temperature range", function()
	local d = Biome.fromName("Desert")
	assertEqual(d.temperatureRange[1], 35)
	assertEqual(d.temperatureRange[2], 55)
	assertEqual(d.moistureRange[2], 0.15)
end)

test("Biome: Tundra has cold temperatures", function()
	local t = Biome.fromName("Tundra")
	assertEqual(t.temperatureRange[1], -30)
	assertEqual(t.temperatureRange[2], 0)
end)

test("Biome: Ocean has low elevation range", function()
	local o = Biome.fromName("Ocean")
	assertEqual(o.elevationRange[1], 0)
	assertEqual(o.elevationRange[2], 0.1)
end)

test("Biome: resourceRarity values are in [0, 1]", function()
	for _, name in Biome.all() do
		local props = Biome.fromName(name)
		for res, rarity in props.resourceRarity do
			assertInRange(rarity, 0, 1, string.format("%s.%s rarity = %f", name, res, rarity))
		end
	end
end)

test("Biome: each resource has a corresponding rarity", function()
	for _, name in Biome.all() do
		local props = Biome.fromName(name)
		for _, res in props.resources do
			local rarity = props.resourceRarity[res]
			assertTrue(rarity ~= nil, string.format("%s: no rarity for resource %s", name, res))
			assertTrue(rarity > 0, string.format("%s: rarity 0 for %s", name, res))
		end
	end
end)

test("Biome: tempRange() helper works", function()
	local d = Biome.fromName("Desert")
	local range = Biome.tempRange(d)
	assertEqual(range[1], 35)
	assertEqual(range[2], 55)
end)

test("Biome: resourcesList() helper works", function()
	local m = Biome.fromName("Meadow")
	local res = Biome.resourcesList(m)
	assertEqual(#res, 4)
end)

test("Biome: rarityOf() helper works", function()
	local d = Biome.fromName("Desert")
	local goldRarity = Biome.rarityOf(d, "Gold")
	assertEqual(goldRarity, 0.15)
	local unknown = Biome.rarityOf(d, "Unobtainium")
	assertEqual(unknown, 0)
end)

test("Biome: every biome has a symmetryGroup", function()
	for _, name in Biome.all() do
		local props = Biome.fromName(name)
		assertTrue(#props.symmetryGroup > 0, string.format("%s missing symmetryGroup", name))
	end
end)

test("Biome: every biome has a mathematicalTheme", function()
	for _, name in Biome.all() do
		local props = Biome.fromName(name)
		assertTrue(#props.mathematicalTheme > 0, string.format("%s missing mathematicalTheme", name))
	end
end)

---------------------------------------------------------------------------
-- BiomeGenerator + WorldMap tests
---------------------------------------------------------------------------

print("\n=== BiomeGenerator & WorldMap Tests ===")

test("Generator: same seed produces identical maps", function()
	local gen1 = BiomeGenerator.new(42)
	local map1 = gen1:generate(16, 16)
	local gen2 = BiomeGenerator.new(42)
	local map2 = gen2:generate(16, 16)

	for y = 1, 16 do
		for x = 1, 16 do
			assertEqual(map1:biomeAt(x, y), map2:biomeAt(x, y),
				string.format("biome mismatch at (%d,%d)", x, y))
			assertEqual(map1:temperatureAt(x, y), map2:temperatureAt(x, y),
				string.format("temp mismatch at (%d,%d)", x, y))
		end
	end
end)

test("Generator: different seeds produce different maps", function()
	local map1 = BiomeGenerator.new(1):generate(32, 32)
	local map2 = BiomeGenerator.new(2):generate(32, 32)

	local diffs = 0
	for y = 1, 32 do
		for x = 1, 32 do
			if map1:biomeAt(x, y) ~= map2:biomeAt(x, y) then
				diffs = diffs + 1
			end
		end
	end
	assertTrue(diffs > 0, "different seeds produced identical maps")
end)

test("WorldMap: width() and height() return correct values", function()
	local map = BiomeGenerator.new(99):generate(64, 48)
	assertEqual(map:width(), 64)
	assertEqual(map:height(), 48)
end)

test("WorldMap: biomeAt returns valid biome names", function()
	local map = BiomeGenerator.new(55):generate(16, 16)
	local allBiomes = Biome.all()
	for y = 1, 16 do
		for x = 1, 16 do
			local b = map:biomeAt(x, y)
			local found = false
			for _, name in allBiomes do
				if name == b then found = true break end
			end
			assertTrue(found, string.format("unknown biome %s at (%d,%d)", b, x, y))
		end
	end
end)

test("WorldMap: temperatures are in reasonable range", function()
	local map = BiomeGenerator.new(33):generate(32, 32)
	for y = 1, 32 do
		for x = 1, 32 do
			local t = map:temperatureAt(x, y)
			assertInRange(t, -50, 150, string.format("temp at (%d,%d)", x, y))
		end
	end
end)

test("WorldMap: moisture values are in [0, 1]", function()
	local map = BiomeGenerator.new(44):generate(32, 32)
	for y = 1, 32 do
		for x = 1, 32 do
			local m = map:moistureAt(x, y)
			assertInRange(m, 0, 1, string.format("moisture at (%d,%d)", x, y))
		end
	end
end)

test("WorldMap: elevation values are in [0, 1]", function()
	local map = BiomeGenerator.new(55):generate(32, 32)
	for y = 1, 32 do
		for x = 1, 32 do
			local e = map:elevationAt(x, y)
			assertInRange(e, 0, 1, string.format("elevation at (%d,%d)", x, y))
		end
	end
end)

test("WorldMap: resourcesAt returns valid resource list", function()
	local map = BiomeGenerator.new(66):generate(8, 8)
	for y = 1, 8 do
		for x = 1, 8 do
			local res = map:resourcesAt(x, y)
			assertTrue(#res > 0, string.format("no resources at (%d,%d)", x, y))
		end
	end
end)

test("WorldMap: bounds checking rejects out-of-range x", function()
	local map = BiomeGenerator.new(1):generate(10, 10)
	local ok = pcall(function()
		map:biomeAt(0, 5)
	end)
	assertTrue(not ok, "expected error for x=0")

	ok = pcall(function()
		map:biomeAt(11, 5)
	end)
	assertTrue(not ok, "expected error for x=11")
end)

test("WorldMap: bounds checking rejects out-of-range y", function()
	local map = BiomeGenerator.new(1):generate(10, 10)
	local ok = pcall(function()
		map:biomeAt(5, 0)
	end)
	assertTrue(not ok, "expected error for y=0")

	ok = pcall(function()
		map:biomeAt(5, 11)
	end)
	assertTrue(not ok, "expected error for y=11")
end)

test("Generator: produces diverse biomes across map", function()
	local map = BiomeGenerator.new(42):generate(64, 64)
	local seen: { [string]: boolean } = {}
	for y = 1, 64 do
		for x = 1, 64 do
			seen[map:biomeAt(x, y)] = true
		end
	end
	local count = 0
	for _ in seen do count = count + 1 end
	assertTrue(count >= 3, string.format("only %d distinct biomes, expected >= 3", count))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------

print(string.format("\n=== Results: %d/%d passed, %d failed ===\n", passed, total, failed))
if failed > 0 then
	print("❌ SOME TESTS FAILED")
else
	print("✅ ALL TESTS PASSED")
end
