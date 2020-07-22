--====================================================================================
-- #Author: Jonathan D @ Gannon
--====================================================================================
 
-- Configuration
local KeyToucheCloseEvent = {
  { code = 172, event = 'ArrowUp' },
  { code = 173, event = 'ArrowDown' },
  { code = 174, event = 'ArrowLeft' },
  { code = 175, event = 'ArrowRight' },
  { code = 176, event = 'Enter' },
  { code = 177, event = 'Backspace' },
}
local KeyOpenClose = 999 -- F2
local KeyTakeCall = 38 -- E
local menuIsOpen = false
local contacts = {}
local messages = {}
local myPhoneNumber = ''
local isDead = false
local USE_RTC = false
local useMouse = false
local ignoreFocus = false
local takePhoto = false
local hasFocus = false

local PhoneInCall = {}
local currentPlaySound = false
local soundDistanceMax = 8.0

local currentCost = 0.0
local currentCash = 1000
local isNearPB = false
local isCalling = false
-- local currentAction = nil
-- local isInMarker, letSleep, currentZone = false, false
-- local hasAlreadyEnteredMarker = false

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


--====================================================================================
--  Check si le joueurs poséde un téléphone
--  Callback true or false
--====================================================================================
function hasPhone (cb)
  cb(true)
end
--====================================================================================
--  Que faire si le joueurs veut ouvrir sont téléphone n'est qu'il en a pas ?
--====================================================================================
function ShowNoPhoneWarning ()
end

ESX = nil
Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end
end)

--[[
  Ouverture du téphone lié a un item
  Un solution ESC basé sur la solution donnée par HalCroves
  https://forum.fivem.net/t/tutorial-for-gcphone-with-call-and-job-message-other/177904
--]]

function hasPhone (cb)
  if (ESX == nil) then return cb(0) end
  ESX.TriggerServerCallback('gcphone:getItemAmount', function(qtty)
    cb(qtty > 0)
  end, 'phone')
end
function ShowNoPhoneWarning () 
  if (ESX == nil) then return end
  ESX.ShowNotification("You dont have any ~r~Handphone~s~")
end

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
        -- print(currentAction)
        if IsControlJustReleased(0, 38) then
          -- if currentAction then
            if currentCash > 0 then
              -- if currentAction == 'atPhoneBooth' then
                hasPhone(function (hasPhone)
                  if hasPhone == false then
                    openPhoneBoothMenu()
                  else
                    print('ada hape')
                    ESX.ShowNotification("You have a ~r~Handphone~s~, Use your fuckin phone")
                  end
                end)
              -- end
              -- currentAction = nil
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



--====================================================================================
--  
--====================================================================================
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if takePhoto ~= true then
      if IsControlJustPressed(1, KeyOpenClose) then
        hasPhone(function (hasPhone)
          if hasPhone == true then
            TooglePhone()
          else
            ShowNoPhoneWarning()
          end
        end)
      end
      if menuIsOpen == true then
        for _, value in ipairs(KeyToucheCloseEvent) do
          if IsControlJustPressed(1, value.code) then
            SendNUIMessage({keyUp = value.event})
          end
        end
        if useMouse == true and hasFocus == ignoreFocus then
          local nuiFocus = not hasFocus
          SetNuiFocus(nuiFocus, nuiFocus)
          hasFocus = nuiFocus
        elseif useMouse == false and hasFocus == true then
          SetNuiFocus(false, false)
          hasFocus = false
        end
      else
        if hasFocus == true then
          SetNuiFocus(false, false)
          hasFocus = false
        end
      end
    end
  end
end)

RegisterCommand("openphone", function(source, args, rawCommand)
        hasPhone(function (hasPhone)
          if hasPhone == true then
            TooglePhone()
          else
            ShowNoPhoneWarning()
          end
        end)
        if menuIsOpen == true then
          for _, value in ipairs(KeyToucheCloseEvent) do
            if IsControlJustPressed(1, value.code) then
              SendNUIMessage({keyUp = value.event})
            end
          end
          if useMouse == true and hasFocus == ignoreFocus then
            local nuiFocus = not hasFocus
            SetNuiFocus(nuiFocus, nuiFocus)
            hasFocus = nuiFocus
          elseif useMouse == false and hasFocus == true then
            SetNuiFocus(false, false)
            hasFocus = false
          end
        else
          if hasFocus == true then
            SetNuiFocus(false, false)
            hasFocus = false
          end
        end
end, false)

--====================================================================================
--  Active ou Deactive une application (appName => config.json)
--====================================================================================
RegisterNetEvent('gcPhone:setEnableApp')
AddEventHandler('gcPhone:setEnableApp', function(appName, enable)
  SendNUIMessage({event = 'setEnableApp', appName = appName, enable = enable })
end)

--====================================================================================
--  Gestion des appels fixe
--====================================================================================
function startFixeCall (fixeNumber)
  local number = ''
  DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 10)
  while (UpdateOnscreenKeyboard() == 0) do
    DisableAllControlActions(0);
    Wait(0);
  end
  if (GetOnscreenKeyboardResult()) then
    number =  GetOnscreenKeyboardResult()
  end
  if number ~= '' then
    TriggerEvent('gcphone:autoCall', number, { useNumber = fixeNumber })
    PhonePlayCall(true)
  end
end

function TakeAppel (infoCall)
  TriggerEvent('gcphone:autoAcceptCall', infoCall)
end

RegisterNetEvent("gcPhone:notifyFixePhoneChange")
AddEventHandler("gcPhone:notifyFixePhoneChange", function(_PhoneInCall)
  PhoneInCall = _PhoneInCall
end)

--[[
  Affiche les imformations quant le joueurs est proche d'un fixe
--]]
function showFixePhoneHelper (coords)
  for number, data in pairs(FixePhone) do
    local dist = GetDistanceBetweenCoords(
      data.coords.x, data.coords.y, data.coords.z,
      coords.x, coords.y, coords.z, 1)
    if dist <= 2.0 then
      SetTextComponentFormat("STRING")
      AddTextComponentString("~g~" .. data.name .. ' ~o~' .. number .. '~n~~INPUT_PICKUP~~w~ Utiliser')
      DisplayHelpTextFromStringLabel(0, 0, 0, -1)
      if IsControlJustPressed(1, KeyTakeCall) then
        startFixeCall(number)
      end
      break
    end
  end
end
 

Citizen.CreateThread(function ()
  local mod = 0
  while true do 
    local playerPed   = PlayerPedId()
    local coords      = GetEntityCoords(playerPed)
    local inRangeToActivePhone = false
    local inRangedist = 0
    for i, _ in pairs(PhoneInCall) do 
        local dist = GetDistanceBetweenCoords(
          PhoneInCall[i].coords.x, PhoneInCall[i].coords.y, PhoneInCall[i].coords.z,
          coords.x, coords.y, coords.z, 1)
        if (dist <= soundDistanceMax) then
          DrawMarker(1, PhoneInCall[i].coords.x, PhoneInCall[i].coords.y, PhoneInCall[i].coords.z,
              0,0,0, 0,0,0, 0.1,0.1,0.1, 0,255,0,255, 0,0,0,0,0,0,0)
          inRangeToActivePhone = true
          inRangedist = dist
          if (dist <= 1.5) then 
            SetTextComponentFormat("STRING")
            AddTextComponentString("~INPUT_PICKUP~ Décrocher")
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            if IsControlJustPressed(1, KeyTakeCall) then
              PhonePlayCall(true)
              TakeAppel(PhoneInCall[i])
              PhoneInCall = {}
              StopSoundJS('ring2.ogg')
            end
          end
          break
        end
    end
    if inRangeToActivePhone == false then
      showFixePhoneHelper(coords)
    end
    if inRangeToActivePhone == true and currentPlaySound == false then
      PlaySoundJS('ring2.ogg', 0.2 + (inRangedist - soundDistanceMax) / -soundDistanceMax * 0.8 )
      currentPlaySound = true
    elseif inRangeToActivePhone == true then
      mod = mod + 1
      if (mod == 15) then
        mod = 0
        SetSoundVolumeJS('ring2.ogg', 0.2 + (inRangedist - soundDistanceMax) / -soundDistanceMax * 0.8 )
      end
    elseif inRangeToActivePhone == false and currentPlaySound == true then
      currentPlaySound = false
      StopSoundJS('ring2.ogg')
    end
    Citizen.Wait(0)
  end
end)


function PlaySoundJS (sound, volume)
  SendNUIMessage({ event = 'playSound', sound = sound, volume = volume })
end

function SetSoundVolumeJS (sound, volume)
  SendNUIMessage({ event = 'setSoundVolume', sound = sound, volume = volume})
end

function StopSoundJS (sound)
  SendNUIMessage({ event = 'stopSound', sound = sound})
end



RegisterNetEvent("gcPhone:forceOpenPhone")
AddEventHandler("gcPhone:forceOpenPhone", function(_myPhoneNumber)
  if menuIsOpen == false then
    TooglePhone()
  end
end)
 
--====================================================================================
--  Events
--====================================================================================
RegisterNetEvent("gcPhone:myPhoneNumber")
AddEventHandler("gcPhone:myPhoneNumber", function(_myPhoneNumber)
  myPhoneNumber = _myPhoneNumber
  SendNUIMessage({event = 'updateMyPhoneNumber', myPhoneNumber = myPhoneNumber})
end)

RegisterNetEvent("gcPhone:contactList")
AddEventHandler("gcPhone:contactList", function(_contacts)
  SendNUIMessage({event = 'updateContacts', contacts = _contacts})
  contacts = _contacts
end)

RegisterNetEvent("gcPhone:allMessage")
AddEventHandler("gcPhone:allMessage", function(allmessages)
  SendNUIMessage({event = 'updateMessages', messages = allmessages})
  messages = allmessages
end)

RegisterNetEvent("gcPhone:getBourse")
AddEventHandler("gcPhone:getBourse", function(bourse)
  SendNUIMessage({event = 'updateBourse', bourse = bourse})
end)

RegisterNetEvent("gcPhone:receiveMessage")
AddEventHandler("gcPhone:receiveMessage", function(message)
  -- SendNUIMessage({event = 'updateMessages', messages = messages})
  SendNUIMessage({event = 'newMessage', message = message})
  table.insert(messages, message)
  if message.owner == 0 then
    hasPhone(function (hasPhone)
      if hasPhone == true then
        local text = '~o~New Message!'
        if ShowNumberNotification == true then
          text = '~o~New Message From ~y~'.. message.transmitter
          for _,contact in pairs(contacts) do
            if contact.number == message.transmitter then
              text = '~o~New Message From ~g~'.. contact.display
              break
            end
          end
        end
        SetNotificationTextEntry("STRING")
        AddTextComponentString(text)
        DrawNotification(false, false)
        PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
        Citizen.Wait(300)
        PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
        Citizen.Wait(300)
        PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
      end
    end)
  end
end)

--====================================================================================
--  Function client | Contacts
--====================================================================================
function addContact(display, num) 
    TriggerServerEvent('gcPhone:addContact', display, num)
end

function deleteContact(num) 
    TriggerServerEvent('gcPhone:deleteContact', num)
end
--====================================================================================
--  Function client | Messages
--====================================================================================
function sendMessage(num, message) 
  TriggerServerEvent('gcPhone:sendMessage', num, message)
end

function deleteMessage(msgId)
  TriggerServerEvent('gcPhone:deleteMessage', msgId)
  for k, v in ipairs(messages) do 
    if v.id == msgId then
      table.remove(messages, k)
      SendNUIMessage({event = 'updateMessages', messages = messages})
      return
    end
  end
end

function deleteMessageContact(num)
  TriggerServerEvent('gcPhone:deleteMessageNumber', num)
end

function deleteAllMessage()
  TriggerServerEvent('gcPhone:deleteAllMessage')
end

function setReadMessageNumber(num)
  TriggerServerEvent('gcPhone:setReadMessageNumber', num)
  for k, v in ipairs(messages) do 
    if v.transmitter == num then
      v.isRead = 1
    end
  end
end

function requestAllMessages()
  TriggerServerEvent('gcPhone:requestAllMessages')
end

function requestAllContact()
  TriggerServerEvent('gcPhone:requestAllContact')
end



--====================================================================================
--  Function client | Appels
--====================================================================================
local aminCall = false
local inCall = false

RegisterNetEvent("gcPhone:waitingCall")
AddEventHandler("gcPhone:waitingCall", function(infoCall, initiator)
  SendNUIMessage({event = 'waitingCall', infoCall = infoCall, initiator = initiator})
  if initiator == true then
    PhonePlayCall()
    if menuIsOpen == false then
      TooglePhone()
    end
  end
end)

RegisterNetEvent("gcPhone:acceptCall")
AddEventHandler("gcPhone:acceptCall", function(infoCall, initiator)
  if inCall == false and USE_RTC == false then
    inCall = true
    NetworkSetVoiceChannel(infoCall.id + 1)
    NetworkSetTalkerProximity(0.0)
  end
  if menuIsOpen == false then 
    TooglePhone()
  end
  PhonePlayCall()
  SendNUIMessage({event = 'acceptCall', infoCall = infoCall, initiator = initiator})
end)

RegisterNetEvent("gcPhone:rejectCall")
AddEventHandler("gcPhone:rejectCall", function(infoCall)
  if inCall == true then
    inCall = false
    Citizen.InvokeNative(0xE036A705F989E049)
    NetworkSetTalkerProximity(2.5)
  end
  PhonePlayText()
  SendNUIMessage({event = 'rejectCall', infoCall = infoCall})
end)


RegisterNetEvent("gcPhone:historiqueCall")
AddEventHandler("gcPhone:historiqueCall", function(historique)
  SendNUIMessage({event = 'historiqueCall', historique = historique})
end)


function startCall (phone_number, rtcOffer, extraData)
  TriggerServerEvent('gcPhone:startCall', phone_number, rtcOffer, extraData)
end

function acceptCall (infoCall, rtcAnswer)
  TriggerServerEvent('gcPhone:acceptCall', infoCall, rtcAnswer)
end

function rejectCall(infoCall)
  TriggerServerEvent('gcPhone:rejectCall', infoCall)
end

function ignoreCall(infoCall)
  TriggerServerEvent('gcPhone:ignoreCall', infoCall)
end

function requestHistoriqueCall() 
  TriggerServerEvent('gcPhone:getHistoriqueCall')
end

function appelsDeleteHistorique (num)
  TriggerServerEvent('gcPhone:appelsDeleteHistorique', num)
end

function appelsDeleteAllHistorique ()
  TriggerServerEvent('gcPhone:appelsDeleteAllHistorique')
end
  

--====================================================================================
--  Event NUI - Appels
--====================================================================================

RegisterNUICallback('startCall', function (data, cb)
  startCall(data.numero, data.rtcOffer, data.extraData)
  cb()
end)

RegisterNUICallback('acceptCall', function (data, cb)
  acceptCall(data.infoCall, data.rtcAnswer)
  cb()
end)
RegisterNUICallback('rejectCall', function (data, cb)
  rejectCall(data.infoCall)
  cb()
end)

RegisterNUICallback('ignoreCall', function (data, cb)
  ignoreCall(data.infoCall)
  cb()
end)

RegisterNUICallback('notififyUseRTC', function (use, cb)
  USE_RTC = use
  if USE_RTC == true and inCall == true then
    inCall = false
    Citizen.InvokeNative(0xE036A705F989E049)
    NetworkSetTalkerProximity(2.5)
  end
  cb()
end)


RegisterNUICallback('onCandidates', function (data, cb)
  TriggerServerEvent('gcPhone:candidates', data.id, data.candidates)
  cb()
end)

RegisterNetEvent("gcPhone:candidates")
AddEventHandler("gcPhone:candidates", function(candidates)
  SendNUIMessage({event = 'candidatesAvailable', candidates = candidates})
end)



RegisterNetEvent('gcphone:autoCall')
AddEventHandler('gcphone:autoCall', function(number, extraData)
  if number ~= nil then
    SendNUIMessage({ event = "autoStartCall", number = number, extraData = extraData})
  end
end)

RegisterNetEvent('gcphone:autoCallNumber')
AddEventHandler('gcphone:autoCallNumber', function(data)
  TriggerEvent('gcphone:autoCall', data.number)
end)

RegisterNetEvent('gcphone:autoAcceptCall')
AddEventHandler('gcphone:autoAcceptCall', function(infoCall)
  SendNUIMessage({ event = "autoAcceptCall", infoCall = infoCall})
end)


--====================================================================================
--  Gestion des evenements NUI
--==================================================================================== 
RegisterNUICallback('log', function(data, cb)
  print(data)
  cb()
end)
RegisterNUICallback('focus', function(data, cb)
  cb()
end)
RegisterNUICallback('blur', function(data, cb)
  cb()
end)
RegisterNUICallback('reponseText', function(data, cb)
  local limit = data.limit or 255
  local text = data.text or ''
  
  DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", text, "", "", "", limit)
  while (UpdateOnscreenKeyboard() == 0) do
      DisableAllControlActions(0);
      Wait(0);
  end
  if (GetOnscreenKeyboardResult()) then
      text = GetOnscreenKeyboardResult()
  end
  cb(json.encode({text = text}))
end)
--====================================================================================
--  Event - Messages
--====================================================================================
RegisterNUICallback('getMessages', function(data, cb)
  cb(json.encode(messages))
end)
RegisterNUICallback('sendMessage', function(data, cb)
  if data.message == '%pos%' then
    local myPos = GetEntityCoords(PlayerPedId())
    data.message = 'GPS: ' .. myPos.x .. ', ' .. myPos.y
  end
  TriggerServerEvent('gcPhone:sendMessage', data.phoneNumber, data.message)
end)
RegisterNUICallback('deleteMessage', function(data, cb)
  deleteMessage(data.id)
  cb()
end)
RegisterNUICallback('deleteMessageNumber', function (data, cb)
  deleteMessageContact(data.number)
  cb()
end)
RegisterNUICallback('deleteAllMessage', function (data, cb)
  deleteAllMessage()
  cb()
end)
RegisterNUICallback('setReadMessageNumber', function (data, cb)
  setReadMessageNumber(data.number)
  cb()
end)
--====================================================================================
--  Event - Contacts
--====================================================================================
RegisterNUICallback('addContact', function(data, cb) 
  TriggerServerEvent('gcPhone:addContact', data.display, data.phoneNumber)
end)
RegisterNUICallback('updateContact', function(data, cb)
  TriggerServerEvent('gcPhone:updateContact', data.id, data.display, data.phoneNumber)
end)
RegisterNUICallback('deleteContact', function(data, cb)
  TriggerServerEvent('gcPhone:deleteContact', data.id)
end)
RegisterNUICallback('getContacts', function(data, cb)
  cb(json.encode(contacts))
end)
RegisterNUICallback('setGPS', function(data, cb)
  SetNewWaypoint(tonumber(data.x), tonumber(data.y))
  cb()
end)

-- Add security for event (leuit#0100)
RegisterNUICallback('callEvent', function(data, cb)
  local eventName = data.eventName or ''
  if string.match(eventName, 'gcphone') then
    if data.data ~= nil then 
      TriggerEvent(data.eventName, data.data)
    else
      TriggerEvent(data.eventName)
    end
  else
    print('Event not allowed')
  end
  cb()
end)
RegisterNUICallback('useMouse', function(um, cb)
  useMouse = um
end)
RegisterNUICallback('deleteALL', function(data, cb)
  TriggerServerEvent('gcPhone:deleteALL')
  cb()
end)



function TooglePhone() 
  menuIsOpen = not menuIsOpen
  SendNUIMessage({show = menuIsOpen})
  if menuIsOpen == true then 
    PhonePlayIn()
  else
    PhonePlayOut()
  end
end
RegisterNUICallback('faketakePhoto', function(data, cb)
  menuIsOpen = false
  SendNUIMessage({show = false})
  cb()
  TriggerEvent('camera:open')
end)

RegisterNUICallback('closePhone', function(data, cb)
  menuIsOpen = false
  SendNUIMessage({show = false})
  PhonePlayOut()
  cb()
end)

----------------------------------
---------- GESTION APPEL ---------
----------------------------------
RegisterNUICallback('appelsDeleteHistorique', function (data, cb)
  appelsDeleteHistorique(data.numero)
  cb()
end)
RegisterNUICallback('appelsDeleteAllHistorique', function (data, cb)
  appelsDeleteAllHistorique(data.infoCall)
  cb()
end)


----------------------------------
---------- GESTION VIA WEBRTC ----
----------------------------------
AddEventHandler('onClientResourceStart', function(res)
  DoScreenFadeIn(300)
  if res == "gcphone" then
      TriggerServerEvent('gcPhone:allUpdate')
  end
end)


RegisterNUICallback('setIgnoreFocus', function (data, cb)
  ignoreFocus = data.ignoreFocus
  cb()
end)


RegisterNUICallback('takePhoto', function(data, cb)
	CreateMobilePhone(1)
  CellCamActivate(true, true)
  takePhoto = true
  Citizen.Wait(0)
  if hasFocus == true then
    SetNuiFocus(false, false)
    hasFocus = false
  end
	while takePhoto do
    Citizen.Wait(0)

		if IsControlJustPressed(1, 27) then -- Toogle Mode
			frontCam = not frontCam
			CellFrontCamActivate(frontCam)
    elseif IsControlJustPressed(1, 177) then -- CANCEL
      DestroyMobilePhone()
      CellCamActivate(false, false)
      cb(json.encode({ url = nil }))
      takePhoto = false
      break
    elseif IsControlJustPressed(1, 176) then -- TAKE.. PIC
			exports['screenshot-basic']:requestScreenshotUpload(data.url, data.field, function(data)
        local resp = json.decode(data)
        DestroyMobilePhone()
        CellCamActivate(false, false)
        cb(json.encode({ url = resp.files[1].url }))   
      end)
      takePhoto = false
		end
		HideHudComponentThisFrame(7)
		HideHudComponentThisFrame(8)
		HideHudComponentThisFrame(9)
		HideHudComponentThisFrame(6)
		HideHudComponentThisFrame(19)
    HideHudAndRadarThisFrame()
  end
  Citizen.Wait(1000)
  PhonePlayAnim('text', false, true)
end)