-- Server.lua
local activeJobs      = {}
local playerCooldowns = {}

-- Start the moonshine run
RegisterNetEvent('moonshine:server:StartJob', function()
  local src = source
  local now = os.time()

  -- cooldown check
  if playerCooldowns[src] and now < playerCooldowns[src] then
    local rem = math.ceil((playerCooldowns[src] - now) / 60)
    TriggerClientEvent('ox_lib:notify', src, { description = "Wait "..rem.." more minute(s).", type = "error", position= 'top', duration=5000 })  -- :contentReference[oaicite:0]{index=0}
    return
  end

  -- police count
  local policeCount = 0
  for _, ply in pairs(exports.qbx_core:GetQBPlayers()) do
    if ply.PlayerData.job.name == 'police' then
      policeCount = policeCount + 1
    end
  end  -- :contentReference[oaicite:1]{index=1}

  if policeCount < Config.MinPolice then
    TriggerClientEvent('ox_lib:notify', src, { description = "Not enough police on duty.", type = "error", position= 'top', duration=5000 })  -- :contentReference[oaicite:2]{index=2}
    return
  end

  -- assign bottles via ox_inventory
  local bottles = math.random(Config.MinBottles, Config.MaxBottles)
  exports.ox_inventory:AddItem(src, Config.MoonshineItem, bottles)  -- :contentReference[oaicite:3]{index=3}

  -- pick drop location
  local drop = Config.DropOffLocations[math.random(#Config.DropOffLocations)]
  activeJobs[src] = { drop = drop, bottles = bottles }

  TriggerClientEvent('moonshine:client:JobAssigned', src, drop, bottles)
end)

-- Handle spills
RegisterNetEvent('moonshine:server:Spill', function(amount)
  local src = source
  local job = activeJobs[src]
  if not job then return end

  local spill = math.min(amount, job.bottles)
  if spill > 0 then
    exports.ox_inventory:RemoveItem(src, Config.MoonshineItem, spill)  -- :contentReference[oaicite:4]{index=4}
    job.bottles = job.bottles - spill
    TriggerClientEvent('ox_lib:notify', src, { description = spill.." bottles spilled!", type = "error", position= 'top', duration=5000 })  -- :contentReference[oaicite:5]{index=5}
  end
end)

-- Complete the run
RegisterNetEvent('moonshine:server:CompleteJob', function()
  local src = source
  local job = activeJobs[src]
  if not job then return end

  -- remove remaining bottles
  exports.ox_inventory:RemoveItem(src, Config.MoonshineItem, job.bottles)  -- :contentReference[oaicite:6]{index=6}

  -- recalc police & payout
  local policeCount = 0
  for _, ply in pairs(exports.qbx_core:GetQBPlayers()) do
    if ply.PlayerData.job.name == 'police' then
      policeCount = policeCount + 1
    end
  end  -- :contentReference[oaicite:7]{index=7}

  local payout = math.floor(job.bottles * Config.BasePrice * (1 + policeCount * Config.PolicePriceMultiplier))
  exports.ox_inventory:AddItem(src, Config.MoneyItem, payout)  -- :contentReference[oaicite:8]{index=8}

  TriggerClientEvent('ox_lib:notify', src, {
    description = ("Delivered %d jars for $%d black money."):format(job.bottles, payout),
    type        = "success"
  })  -- :contentReference[oaicite:9]{index=9}

  -- set cooldown
  local cd = math.random(Config.MinCooldown, Config.MaxCooldown)
  playerCooldowns[src] = os.time() + cd
  activeJobs[src] = nil
end)

-- Clean up if a player disconnects
AddEventHandler('playerDropped', function()
  activeJobs[source] = nil
end)
