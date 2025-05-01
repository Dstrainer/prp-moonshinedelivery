-- Config.lua
Config = {}

-- Pickup NPC (Grapeseed)
Config.PickupPedModel    = `a_m_m_farmer_01`
Config.PickupPedCoords   = vector4(-18.73, 6407.08, 30.79, 200.0)
Config.PickupHours       = { start = 20, finish = 4 }

-- Drop-off points
Config.DropOffLocations = {
  vector4(235.34, 316.12, 105.90,  90.0),
  vector4(150.12, 6600.55, 31.70, 180.0),
  vector4(-312.45, 6200.23, 31.49, 270.0),
}

-- Job rules
Config.MinPolice             = 0
Config.MinBottles            = 5
Config.MaxBottles            = 10
Config.BasePrice             = 100     -- per bottle
Config.PolicePriceMultiplier = 0.10    -- +10% per officer

-- Mid-route alert timing & chance
Config.MinAlertTime     = 30_000   -- ms
Config.MaxAlertTime     = 120_000  -- ms
Config.PoliceAlertChance = 30      -- percent

-- Driving spill
Config.ErraticSpeedThreshold = 15.0   -- m/s Δspeed
Config.SpillFraction         = 0.20   -- spill 20% of bottles

-- Delivery trigger
Config.DeliveryRadius   = 5.0   -- meters

-- Cooldown
Config.MinCooldown      = 600   -- seconds
Config.MaxCooldown      = 1800  -- seconds

-- Items
Config.MoonshineItem    = "moonshine-jar"
Config.MoneyItem        = "black_money"

-- ps-dispatch alert definitions
Config.SuspiciousExport = "SuspiciousActivity"
Config.IllegalSaleAlert = {
  dispatchCode = "10-27",
  message      = "Illegal alcohol sale in progress",
  description  = "Illegal Alcohol Sale",
  radius       = 0,
  sprite       = 93,
  color        = 1,
  scale        = 1.0,
  length       = 300,
  job          = { "police" },
}
