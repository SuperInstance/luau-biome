--!strict
--[[
	Biome type definitions — 10 unique biome types with properties,
	resources, and mathematical themes for educational game worlds.
]]

local Biome = {}
Biome.__index = Biome

export type BiomeProperties = {
	name: string,
	description: string,
	temperatureRange: { number, number }, -- {min, max} in °C
	moistureRange: { number, number }, -- {min, max} 0-1
	elevationRange: { number, number }, -- {min, max} 0-1
	resources: { string },
	resourceRarity: { [string]: number },
	mathematicalTheme: string,
	symmetryGroup: string,
}

export type BiomeType = BiomeProperties & {
	tempRange: (self: BiomeType) -> { number, number },
	resourcesList: (self: BiomeType) -> { string },
	rarityOf: (self: BiomeType, resource: string) -> number,
}

local BIOMES: { [string]: BiomeProperties } = {
	Meadow = {
		name = "Meadow",
		description = "Rolling grasslands with wildflowers and gentle streams",
		temperatureRange = { 15, 30 },
		moistureRange = { 0.4, 0.7 },
		elevationRange = { 0.1, 0.35 },
		resources = { "Wildflowers", "Herbs", "Honey", "Clay" },
		resourceRarity = {
			Wildflowers = 0.8,
			Herbs = 0.6,
			Honey = 0.3,
			Clay = 0.5,
		},
		mathematicalTheme = "Fibonacci sequences in flower petal arrangements",
		symmetryGroup = "C5 (5-fold rotational symmetry of flowers)",
	},
	Forest = {
		name = "Forest",
		description = "Dense woodland with towering trees and hidden clearings",
		temperatureRange = { 10, 25 },
		moistureRange = { 0.6, 0.9 },
		elevationRange = { 0.15, 0.4 },
		resources = { "Wood", "Berries", "Mushrooms", "Sap" },
		resourceRarity = {
			Wood = 0.9,
			Berries = 0.7,
			Mushrooms = 0.5,
			Sap = 0.4,
		},
		mathematicalTheme = "Fractal branching patterns in trees and rivers",
		symmetryGroup = "D1 (bilateral symmetry of leaves)",
	},
	Desert = {
		name = "Desert",
		description = "Scorching sand dunes with hidden oases and ancient artifacts",
		temperatureRange = { 35, 55 },
		moistureRange = { 0.0, 0.15 },
		elevationRange = { 0.05, 0.3 },
		resources = { "Sand", "Cactus", "Gold", "Fossils" },
		resourceRarity = {
			Sand = 0.95,
			Cactus = 0.6,
			Gold = 0.15,
			Fossils = 0.25,
		},
		mathematicalTheme = "Geometric tessellations in Islamic tile patterns",
		symmetryGroup = "P6m (hexagonal symmetry of sand crystals)",
	},
	Tundra = {
		name = "Tundra",
		description = "Frozen plains with permafrost and resilient life forms",
		temperatureRange = { -30, 0 },
		moistureRange = { 0.1, 0.4 },
		elevationRange = { 0.2, 0.5 },
		resources = { "Ice", "Moss", "Fur", "Crystals" },
		resourceRarity = {
			Ice = 0.9,
			Moss = 0.7,
			Fur = 0.4,
			Crystals = 0.2,
		},
		mathematicalTheme = "Hexagonal symmetry in snowflake formation",
		symmetryGroup = "D6 (6-fold dihedral symmetry)",
	},
	Ocean = {
		name = "Ocean",
		description = "Vast waters with coral reefs and deep sea trenches",
		temperatureRange = { 5, 28 },
		moistureRange = { 0.8, 1.0 },
		elevationRange = { 0.0, 0.1 },
		resources = { "Fish", "Pearls", "Coral", "Kelp" },
		resourceRarity = {
			Fish = 0.85,
			Pearls = 0.1,
			Coral = 0.5,
			Kelp = 0.7,
		},
		mathematicalTheme = "Wave equations and sinusoidal motion",
		symmetryGroup = "Continuous translational symmetry",
	},
	Volcano = {
		name = "Volcano",
		description = "Molten landscapes of fire and obsidian formations",
		temperatureRange = { 50, 120 },
		moistureRange = { 0.0, 0.1 },
		elevationRange = { 0.6, 1.0 },
		resources = { "Obsidian", "Sulfur", "MagmaCrystal", "Ash" },
		resourceRarity = {
			Obsidian = 0.6,
			Sulfur = 0.5,
			MagmaCrystal = 0.15,
			Ash = 0.8,
		},
		mathematicalTheme = "Exponential growth and decay in cooling rates",
		symmetryGroup = "C1 (no symmetry — chaotic volcanic forms)",
	},
	CrystalCaves = {
		name = "CrystalCaves",
		description = "Underground caverns of luminous crystals and geometric formations",
		temperatureRange = { 8, 18 },
		moistureRange = { 0.3, 0.6 },
		elevationRange = { 0.0, 0.15 },
		resources = { "Quartz", "Amethyst", "Diamond", "Geode" },
		resourceRarity = {
			Quartz = 0.7,
			Amethyst = 0.4,
			Diamond = 0.05,
			Geode = 0.3,
		},
		mathematicalTheme = "Polyhedra and Platonic solids in crystal structures",
		symmetryGroup = "Oh (octahedral symmetry group)",
	},
	FloatingIslands = {
		name = "FloatingIslands",
		description = "Sky-bound landmasses connected by bridges of light",
		temperatureRange = { 10, 22 },
		moistureRange = { 0.2, 0.5 },
		elevationRange = { 0.8, 1.0 },
		resources = { "SkyStone", "Featherwood", "CloudEssence", "StarDust" },
		resourceRarity = {
			SkyStone = 0.65,
			Featherwood = 0.45,
			CloudEssence = 0.25,
			StarDust = 0.1,
		},
		mathematicalTheme = "Non-Euclidean geometry and impossible shapes",
		symmetryGroup = "D∞ (continuous rotational symmetry)",
	},
	MushroomGrove = {
		name = "MushroomGrove",
		description = "Enchanted forest of bioluminescent fungi and spore clouds",
		temperatureRange = { 18, 30 },
		moistureRange = { 0.7, 0.95 },
		elevationRange = { 0.1, 0.3 },
		resources = { "Spores", "GlowCap", "Mycelium", "FairyRing" },
		resourceRarity = {
			Spores = 0.85,
			GlowCap = 0.5,
			Mycelium = 0.6,
			FairyRing = 0.2,
		},
		mathematicalTheme = "Network theory and graph connectivity in mycelial networks",
		symmetryGroup = "D1 (bilateral symmetry of mushroom caps)",
	},
	AncientRuins = {
		name = "AncientRuins",
		description = "Crumbled temples covered in mathematical inscriptions",
		temperatureRange = { 15, 35 },
		moistureRange = { 0.15, 0.45 },
		elevationRange = { 0.3, 0.55 },
		resources = { "StoneTablet", "GoldenRatio", "CipherKey", "Blueprint" },
		resourceRarity = {
			StoneTablet = 0.7,
			GoldenRatio = 0.3,
			CipherKey = 0.15,
			Blueprint = 0.25,
		},
		mathematicalTheme = "Golden ratio, phi, and sacred geometry proportions",
		symmetryGroup = "D4 (4-fold dihedral symmetry of temple layouts)",
	},
}

--[[
	Get a biome properties table by name.
]]
function Biome.fromName(name: string): BiomeProperties?
	return BIOMES[name]
end

--[[
	Get all biome names.
]]
function Biome.all(): { string }
	local names = {}
	for name, _ in BIOMES do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--[[
	Get all biome property tables.
]]
function Biome.allProperties(): { BiomeProperties }
	local result = {}
	for _, props in BIOMES do
		table.insert(result, props)
	end
	table.sort(result, function(a, b)
		return a.name < b.name
	end)
	return result
end

--[[
	Get the temperature range for a biome.
]]
function Biome.tempRange(biome: BiomeProperties): { number, number }
	return biome.temperatureRange
end

--[[
	Get the resources list for a biome.
]]
function Biome.resourcesList(biome: BiomeProperties): { string }
	return biome.resources
end

--[[
	Get the rarity of a specific resource.
]]
function Biome.rarityOf(biome: BiomeProperties, resource: string): number
	return biome.resourceRarity[resource] or 0
end

--[[
	The raw BIOMES table (keyed by name).
]]
Biome.BIOMES = BIOMES

return Biome
