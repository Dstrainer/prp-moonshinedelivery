-- Client.lua
local lib        = exports.ox_lib          -- for lib.notify
local hasJob     = false
local dropCoords, bottleCount, jobBlip
local carriedBox -- object id when carrying the box

-- Spawn/despawn pickup NPC & target
Citizen.CreateThread(function()
  local ped, netId, inWindow = nil, nil, false

  while true do
    local hr = GetClockHours()
    inWindow = (Config.PickupHours.start < Config.PickupHours.finish)
      and (hr >= Config.PickupHours.start and hr < Config.PickupHours.finish)
      or (hr >= Config.PickupHours.start or hr < Config.PickupHours.finish)

    if inWindow and not ped then
      -- spawn dealer ped & use rep-talkNPC for interaction
      RequestModel(Config.PickupPedModel); while not HasModelLoaded(Config.PickupPedModel) do Wait(10) end
      ped = CreatePed(4, Config.PickupPedModel, Config.PickupPedCoords.xyz, false, true)
      FreezeEntityPosition(ped, true); SetBlockingOfNonTemporaryEvents(ped, true)

    exports['rep-talkNPC']:CreateNPC({
        npc         = ped,
        coords      = Config.PickupPedCoords,
        name        = "Moonshine Dealer",
        animScenario= "WORLD_HUMAN_DRINKING",
        tag         = "moonshine",
        color       = "#7f6000"
        }, {
          [1] = {
            label   = "Buy Moonshine",
            action  = function()
              TriggerEvent('moonshine:client:PickupBox')
            end
          }
        })
    elseif not inWindow and ped then
      exports['rep-talkNPC']:RemoveNPC("moonshine")
      DeleteEntity(ped)
      ped, netId = nil, nil
    end

    Wait(60_000)
  end
end)

-- On job assigned
RegisterNetEvent('moonshine:client:JobAssigned', function(drop, bottles)
  hasJob      = true
  dropCoords  = drop
  bottleCount = bottles

  -- map blip
  jobBlip = AddBlipForCoord(drop.x, drop.y, drop.z)
  SetBlipSprite(jobBlip, 93); SetBlipColour(jobBlip, 1)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString("Moonshine Drop-off")
  EndTextCommandSetBlipName(jobBlip)

  -- mid-route police alert
  Citizen.SetTimeout(
    math.random(Config.MinAlertTime, Config.MaxAlertTime),
    function()
      if hasJob and math.random(100) <= Config.PoliceAlertChance then
        exports['ps-dispatch'][Config.SuspiciousExport]()  -- :contentReference[oaicite:11]{index=11}
        lib.notify({ description = "Police may have been alerted!", type = "error", position= 'top', duration=5000 })  -- :contentReference[oaicite:12]{index=12}
      end
    end
  )

  -- erratic-driving spill check
  Citizen.CreateThread(function()
    local lastSpeed = 0.0
    while hasJob do
      if IsPedInAnyVehicle(PlayerPedId(), false) then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        local spd = GetEntitySpeed(veh)
        if math.abs(spd - lastSpeed) > Config.ErraticSpeedThreshold then
          local spill = math.ceil(bottleCount * Config.SpillFraction)
          TriggerServerEvent('moonshine:server:Spill', spill)
          bottleCount = bottleCount - spill
        end
        lastSpeed = spd
      end
      Wait(500)
    end
  end)

  -- arrival & drop-off NPC
  Citizen.CreateThread(function()
    while hasJob do
      if #(GetEntityCoords(PlayerPedId()) - vector3(dropCoords.xyz)) < Config.DeliveryRadius then
        -- spawn buyer ped
        RequestModel(`a_m_y_business_01`); while not HasModelLoaded(`a_m_y_business_01`) do Wait(10) end
        local buyer = CreatePed(4, `a_m_y_business_01`, dropCoords.xyz, dropCoords.w, false, true)
        FreezeEntityPosition(buyer, true); SetBlockingOfNonTemporaryEvents(buyer, true)

        local buyerNetId = NetworkGetNetworkIdFromEntity(buyer)
        exports.ox_target:addEntity(buyerNetId, {
          options = {{
            icon     = "fa-solid fa-handshake",
            label    = "Deliver Moonshine",
            onSelect = function()
              -- illegal sale alert
              exports['ps-dispatch']:CustomAlert(Config.IllegalSaleAlert)  -- :contentReference[oaicite:13]{index=13}
              TriggerServerEvent('moonshine:server:CompleteJob')
              RemoveBlip(jobBlip)
              hasJob = false
            end
          }},
          distance = 2.5
        })  -- :contentReference[oaicite:14]{index=14}

        break
      end
      Wait(1_000)
    end
  end)
  RegisterNetEvent('moonshine:client:PickupMoonshine', function()
    -- 1a) Tell the server to StartJob (it will give items & set your drop-off)
    TriggerServerEvent('moonshine:server:StartJob')
  
    -- 1b) Spawn a box prop & attach to the player’s hand
    local ped = PlayerPedId()
    local x,y,z = table.unpack(GetEntityCoords(ped, true))
    local boxHash = GetHashKey("prop_box_wood02a")
    RequestModel(boxHash)
    while not HasModelLoaded(boxHash) do Wait(10) end
  
    carriedBox = CreateObject(boxHash, x, y, z + 0.2, true, true, true)
    AttachEntityToEntity(
      carriedBox, ped,
      GetPedBoneIndex(ped, 57005),  -- right hand
      0.12, 0.0, -0.02,             -- position offset
      0.0, 0.0, 0.0,                -- rotation
      false, false, false, false, 2, true
    )
  
    lib.notify({ description = "Picked up box of moonshine. Place it in your vehicle.", type = "info", position= 'top', duration=5000 })  -- :contentReference[oaicite:15]{index=15}
  end)
  
  -- 2) Watch for the player entering any vehicle. When they do,
  --    we “stow” the box (delete it) and notify them.
  Citizen.CreateThread(function()
    while true do
      Wait(500)
      if carriedBox and IsPedInAnyVehicle(PlayerPedId(), false) then
        DetachEntity(carriedBox, true, true)
        DeleteEntity(carriedBox)
        carriedBox = nil
        lib.notify({ description = "Box placed in vehicle. Delivery in progress.", type = "success",  position= 'top', duration=5000 })  -- :contentReference[oaicite:16]{index=16}
      end
    end
  end)
end)
