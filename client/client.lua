-- Client.lua
local hasJob, dropCoords, bottleCount, jobBlip = false

-- Spawn/despawn pickup NPC & target
Citizen.CreateThread(function()
  local ped, netId, inWindow = nil, nil, false

  while true do
    local hr = GetClockHours()
    inWindow = (Config.PickupHours.start < Config.PickupHours.finish)
      and (hr >= Config.PickupHours.start and hr < Config.PickupHours.finish)
      or (hr >= Config.PickupHours.start or hr < Config.PickupHours.finish)

    if inWindow and not ped then
      -- spawn dealer ped
      RequestModel(Config.PickupPedModel); while not HasModelLoaded(Config.PickupPedModel) do Wait(10) end
      ped = CreatePed(4, Config.PickupPedModel, Config.PickupPedCoords.xyz, false, true)
      FreezeEntityPosition(ped, true); SetBlockingOfNonTemporaryEvents(ped, true)

      netId = NetworkGetNetworkIdFromEntity(ped)
      exports.ox_target:addEntity(netId, {
        options = {{
          icon     = "fa-solid fa-wine-bottle",
          label    = "Buy Moonshine",
          onSelect = function()
            TriggerServerEvent('moonshine:server:StartJob')
          end
        }},
        distance = 2.5
      })  -- :contentReference[oaicite:10]{index=10}

    elseif not inWindow and ped then
      exports.ox_target:removeEntity(netId, "Buy Moonshine")
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
        lib.notify({ description = "Police may have been alerted!", type = "error" })  -- :contentReference[oaicite:12]{index=12}
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
            label    = "Hand Over Moonshine",
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
end)
