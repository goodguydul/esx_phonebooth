
local currentCost = 0.0
local currentCash = 1000
local isNearPB = false
local isCalling = false

local phones = {
  [1158960338] = true,
  [1511539537] = true,
  [1281992692] = true,
  [-429560270] = true,
  [-1559354806] = true,
  [-78626473] = true,
  [295857659] = true,
  [-2103798695] = true,
  [-870868698] = true,
  [-1364697528] = true,
  [-1126237515] = true,
  [506770882] = true
}

local DisableKeys = {0, 22, 23, 24, 29, 30, 31, 37, 44, 56, 82, 140, 166, 167, 168, 170, 288, 289, 311, 323}


-- ======================================================= PHONE BOOTH / WARTEL SCRIPT -by: zulvio ======================================================================
-- 3D text
function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.4, 0.4)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end

-- cari phonebooth terdekat
function FindNearestPB()
  local coords = GetEntityCoords(PlayerPedId())
  local pBooth = {}
  local handle, object = FindFirstObject()
  local success

  repeat
    if phones[GetEntityModel(object)] then
      table.insert(pBooth, object)
    end

    success, object = FindNextObject(handle, object)
  until not success

  EndFindObject(handle)

  local pbObj = 0
  local pbDistance = 1000

  for _,x in pairs(pBooth) do
    local dstcheck = GetDistanceBetweenCoords(coords, GetEntityCoords(x))

    if dstcheck < pbDistance then
      pbDistance = dstcheck
      pbObj = x
    end
  end

  return pbObj, pbDistance
end

-- pre thread
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(250)

    local pbObj, pbDistance = FindNearestPB()

    if pbDistance < 1.0 then
      isNearPB = pbObj
      local playerData = ESX.GetPlayerData()
      for i=1, #playerData.accounts, 1 do
        if playerData.accounts[i].name == 'money' then
          currentCash = playerData.accounts[i].money
          break
        end
      end
    else
      isNearPB = false
      ESX.UI.Menu.CloseAll()
      Citizen.Wait(math.ceil(pbDistance * 20))
    end

  end
end)

-- main thread
Citizen.CreateThread(function()
  while true do
    local ped = PlayerPedId()

    if not isCalling and ((isNearPB and GetEntityHealth(isNearPB) > 0)) then
      local pbCoords = GetEntityCoords(isNearPB)

      if IsPedInAnyVehicle(ped) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
        DrawText3Ds(pbCoords.x, pbCoords.y, pbCoords.z + 1.2, "Exit Vehicle To Use Phone Booth")
      else
        DrawText3Ds(pbCoords.x, pbCoords.y, pbCoords.z + 1.5,"Press ~g~ E ~w~ To Use Phone Booth")

        if IsControlJustReleased(0, 38) then

            if currentCash > 0 then

                hasPhone(function (hasPhone)
                  if hasPhone == false then
                    openPhoneBoothMenu()
                  else
                    print('ada hape')
                    ESX.ShowNotification("You have a ~r~Handphone~s~, Use your fuckin phone")
                  end
                end)
            else
              DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.5, "Not Enough Cash")
            end
          -- end
        end
      end
    else
      Citizen.Wait(250)
    end
    Citizen.Wait(0)
  end
end)


function openPhoneBoothMenu()
    ESX.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "phone_booth_menu",
        {
            title = "Select to Call",
            align = "top-left",
            elements = {
                {label = "Police", value = "911"},
                {label = "Ambulance", value = "311"},
                {label = "Mechanic", value = "mechanic"},
                {label = "Call Number", value = "othercall"},
                {label = "Send SMS Number", value = "othersms"},
            }
        },
        function(data2, menu2)
            local option = data2.current.value
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local caller = GetPlayerName(source)

            if option == "911" then
                ESX.UI.Menu.CloseAll()

                TriggerEvent("gcphone:autoCall", option, {useNumber = "Phone Booth"})
                isCalling = true
                TriggerEvent('countPulse',isNearPB,playerPed)
                PhonePlayCall(true)

            elseif option == "311" then

                ESX.UI.Menu.CloseAll()
                TriggerEvent("gcphone:autoCall", option, {useNumber = "Phone Booth"})
                isCalling = true
                TriggerEvent('countPulse',isNearPB,playerPed)
                PhonePlayCall(true)

            elseif option == "mechanic" then

                ESX.UI.Menu.CloseAll()
                DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 64)
                while (UpdateOnscreenKeyboard() == 0) do
                    DisableAllControlActions(0)
                    Wait(0)
                end
                if (GetOnscreenKeyboardResult()) then
                    message = GetOnscreenKeyboardResult()
                    message =
                        "[MESSAGE FROM PHONEBOOTH] : " .. message .. " - Location : " .. coords.x .. ", " .. coords.y
                    sendMessage(option, message)
                    ESX.ShowNotification("Your Phone Cost : ~g~ $100 ~s~")
                    TriggerServerEvent('payPulse', 100)
                end

            elseif option == "othercall" then

                local number = ""
                ESX.UI.Menu.CloseAll()
                DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 10)
                while (UpdateOnscreenKeyboard() == 0) do
                    DisableAllControlActions(0)
                    Wait(0)
                end
                if (GetOnscreenKeyboardResult()) then
                    number = GetOnscreenKeyboardResult()
                end

                if number ~= "" then
                    TriggerEvent("gcphone:autoCall", number, {useNumber = "Phone Booth : " .. caller})
                    isCalling = true
                    TriggerEvent('countPulse',isNearPB,playerPed)
                    PhonePlayCall(true)
                end

            elseif option == "othersms" then

                local number = ""

                ESX.UI.Menu.CloseAll()

                DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 10)
                while (UpdateOnscreenKeyboard() == 0) do
                    DisableAllControlActions(0)
                    Wait(0)
                end
                if (GetOnscreenKeyboardResult()) then
                    number = GetOnscreenKeyboardResult()
                end

                if number ~= "" then
                  DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 64)
                  while (UpdateOnscreenKeyboard() == 0) do
                      DisableAllControlActions(0)
                      Wait(0)
                  end
                  if (GetOnscreenKeyboardResult()) then
                      message = GetOnscreenKeyboardResult()
                      message =
                          "[MESSAGE FROM PHONEBOOTH] : " .. message .. " - Location : " .. coords.x .. ", " .. coords.y
                      sendMessage(number, message)
                      ESX.ShowNotification("Your Phone Cost : ~g~ $100 ~s~")
                      TriggerServerEvent('payPulse', 100)
                  end
                end

            end
        end)
end

-- main itung pulsa
AddEventHandler('countPulse', function(pbObj, ped)
  Citizen.Wait(100)
  TriggerEvent('startCountPulse', pbObj)

  while isCalling do
    for _, controlIndex in pairs(DisableKeys) do
      DisableControlAction(0, controlIndex)
    end

    if pbObj then
      local stringCoords = GetEntityCoords(pbObj)
      local extraString = ""

      extraString = "Pulse Cost : ~g~$" .. Round(currentCost, 1)
      DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.5, "Press ~g~Right Mouse Button~w~ To Cancel")
      DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, extraString)
      
    end
    if currentCash <= currentCost then

      DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, "Not Enough Cash")

      isCalling = false
    end

    if IsControlJustReleased(0, 25) then
      isCalling = false
      ESX.ShowNotification("Your Phone Cost : ~g~ $".. currentCost .. "~s~")

      TooglePhone()
    end
    Citizen.Wait(0)
  end
  ClearPedTasks(ped)
end)

-- mulai itung pulsa + potong duit dari inventori
AddEventHandler('startCountPulse', function(pbObj)

  while isCalling do
    Citizen.Wait(1000)

    local extraCost = 1
    currentCost = currentCost + extraCost
  end

  print(pbObj)

  if pbObj then
    TriggerServerEvent('payPulse', currentCost)
  end

  currentCost = 0.0
end)


--==================================================================================== script ini customize dari script legacyFuel, untuk script bagian server, cek trigger "payPulse" di server.lua ====================================================================