# luau-biome

Deterministic biome generation for Roblox — 10 unique zones with mathematical structures and seeded worlds.

## Features

- **10 Biome Types**: Meadow, Forest, Desert, Tundra, Ocean, Volcano, CrystalCaves, FloatingIslands, MushroomGrove, AncientRuins
- **Deterministic**: Same seed always produces the same world map
- **Mathematical Themes**: Each biome teaches a math concept (Fibonacci, fractals, golden ratio, etc.)
- **Layered Noise**: Temperature, moisture, and elevation layers with Whittaker diagram biome selection
- **Zero Dependencies**: Pure Luau, no external packages needed
- **Type Annotated**: Full type annotations for Luau type checking

## Install

### Option 1: Wally (recommended)

Add to your `wally.toml`:

```toml
[dependencies]
luau-biome = "superinstance/luau-biome@0.1.0"
```

Then run:

```sh
wally install
```

### Option 2: Manual

Copy the `src/` folder into your Roblox project under `ReplicatedStorage/luau-biome`.

### Option 3: Rojo

Use the included `default.project.json` with Rojo to sync into Studio:

```sh
rojo serve
```

Then connect in Roblox Studio via the Rojo plugin.

## Usage

### Basic World Generation

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BiomeGenerator = require(ReplicatedStorage.luau-biome.BiomeGenerator)

local gen = BiomeGenerator.new(42) -- deterministic seed
local map = gen:generate(64, 64)

-- Query biomes
local biome = map:biomeAt(10, 20)
local temp = map:temperatureAt(10, 20)
local moisture = map:moistureAt(10, 20)
local elevation = map:elevationAt(10, 20)
local resources = map:resourcesAt(10, 20)

print(string.format("Biome: %s, Temp: %.1f°C", biome, temp))
print(string.format("Moisture: %.2f, Elevation: %.2f", moisture, elevation))
print("Resources: " .. table.concat(resources, ", "))
```

### Querying Biome Properties

```luau
local Biome = require(ReplicatedStorage.luau-biome.Biome)

-- Get all biome names
local allBiomes = Biome.all()
print("Biomes: " .. table.concat(allBiomes, ", "))

-- Look up a specific biome
local desert = Biome.fromName("Desert")
print(desert.description)
print("Temperature: " .. desert.temperatureRange[1] .. "-" .. desert.temperatureRange[2] .. "°C")
print("Math theme: " .. desert.mathematicalTheme)

-- Get resources and rarities
for _, res in desert.resources do
    print(string.format("  %s (%.0f%% rare)", res, desert.resourceRarity[res] * 100))
end
```

### Deterministic PRNG

```luau
local Xoshiro = require(ReplicatedStorage.luau-biome.Xoshiro)

local rng = Xoshiro.new(12345)
print(rng:next())     -- random float in [0, 1)
print(rng:nextInt(1, 6)) -- random integer, like a dice roll
```

## Biome Reference

| Biome | Temperature | Moisture | Elevation | Math Theme |
|-------|------------|----------|-----------|------------|
| Meadow | 15–30°C | 0.4–0.7 | 0.1–0.35 | Fibonacci sequences |
| Forest | 10–25°C | 0.6–0.9 | 0.15–0.4 | Fractal branching |
| Desert | 35–55°C | 0–0.15 | 0.05–0.3 | Geometric tessellations |
| Tundra | -30–0°C | 0.1–0.4 | 0.2–0.5 | Hexagonal symmetry |
| Ocean | 5–28°C | 0.8–1.0 | 0–0.1 | Wave equations |
| Volcano | 50–120°C | 0–0.1 | 0.6–1.0 | Exponential growth/decay |
| CrystalCaves | 8–18°C | 0.3–0.6 | 0–0.15 | Platonic solids |
| FloatingIslands | 10–22°C | 0.2–0.5 | 0.8–1.0 | Non-Euclidean geometry |
| MushroomGrove | 18–30°C | 0.7–0.95 | 0.1–0.3 | Network theory |
| AncientRuins | 15–35°C | 0.15–0.45 | 0.3–0.55 | Golden ratio |

## Architecture

```
Xoshiro.luau          → Deterministic PRNG (xoshiro256**)
Biome.luau            → Biome enum with properties
BiomeGenerator.luau   → Layered noise + Whittaker diagram
WorldMap.luau         → Generated world with query API
```

Generation pipeline:
1. Seed → Xoshiro PRNGs for each noise layer
2. Temperature = latitude-based baseline + value noise
3. Moisture = fractal noise (3 octaves)
4. Elevation = fractal noise (4 octaves)
5. Whittaker diagram maps (temp, moisture, elevation) → biome

## Testing

Tests are in `tests/run-tests.luau`. Run from Roblox Studio or integrate with your test framework.

25+ tests covering:
- Xoshiro determinism and range validation
- All 10 biome types with correct properties
- Same seed → same map, different seed → different map
- Temperature, moisture, elevation in valid ranges
- WorldMap bounds checking
- Biome diversity across generated maps

## License

MIT
