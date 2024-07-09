ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local open = false
local mainMenu = RageUI.CreateMenu("Motel", "Interaction", nil, nil, "root_cause5", "img_red")
local sub_menu1 = RageUI.CreateSubMenu(mainMenu, "Motel", "Interaction")
mainMenu.Display.Header = true
mainMenu.Closed = function()
    open = false
    FreezeEntityPosition(PlayerPedId(), false)
end

local liste = {}

local function getListeSonner()
    ESX.TriggerServerCallback("xHotel:getListeSonner", function(result) 
        liste = result
    end)
end

RegisterNetEvent("xHotel:notifsonner")
AddEventHandler("xHotel:notifsonner", function(result) liste = result end)

RegisterNetEvent("xHotel:enterIn")
AddEventHandler("xHotel:enterIn", function(id, posIn)
    FreezeEntityPosition(PlayerPedId(), false)
    TriggerServerEvent("xHotel:setBucket", tonumber(id))
    DoScreenFadeOut(200)
    Wait(200)
    ESX.Game.Teleport(PlayerPedId(), posIn, function()end)
    Wait(1000)
    DoScreenFadeIn(200)
    getHotel()
    getPlayerBucket()
end)

function OwnerMenu(id)
    if open then
        open = false
        RageUI.Visible(mainMenu, false)
    else
        open = true
        RageUI.Visible(mainMenu, true)
        Citizen.CreateThread(function()
            while open do
                Wait(0)
                RageUI.IsVisible(mainMenu, function()
                    RageUI.Button("Ajouter un colocataire", nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            local playerTarget, dst = ESX.Game.GetClosestPlayer()
                            if playerTarget ~= -1 and dst <= 1.5 then
                                TriggerServerEvent("xHotel:addColocataire", GetPlayerServerId(playerTarget), id)
                            else
                                ESX.ShowNotification("(~r~Erreur~s~)\nAucun joueur à proximité.")
                            end
                        end
                    })
                    RageUI.Button("Listes des personnes qui ont sonné", nil, {RightLabel = "→"}, true, {onSelected = function() getListeSonner() end}, sub_menu1)
                    RageUI.Line()
                    RageUI.Button("Rendre la chambre", nil, {RightBadge = RageUI.BadgeStyle.Tick}, true, {
                        onSelected = function()
                            TriggerServerEvent("xHotel:rendre", id)
                        end
                    })
                end)
                RageUI.IsVisible(sub_menu1, function()
                    if #liste > 0 then
                        for _,v in pairs(liste) do
                            if v.id == id then
                                RageUI.Button("~r~→~s~ Faire entrer", nil, {RightLabel = ("~r~%s"):format(v.nom)}, true, {
                                    onSelected = function()
                                        TriggerServerEvent("xHotel:enter", v.source, v.id, GetEntityCoords(PlayerPedId()))
                                        Wait(1000)
                                        getListeSonner(id)
                                    end
                                })
                            end
                        end
                    else
                        RageUI.Separator("")
                        RageUI.Separator("~r~Personne n'a sonné à la porte.")
                        RageUI.Separator("")
                    end
                end)
            end
        end)
    end
end

-- Ajouter un événement de capture de touche pour ouvrir le menu OwnerMenu avec la touche F9
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(1, 56) then -- 56 correspond à la touche F9
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            ESX.TriggerServerCallback("xHotel:getPlayerHotelId", function(hotelId)
                if hotelId then
                    OwnerMenu(hotelId)
                else
                    ESX.ShowNotification("Vous n'êtes pas dans un hôtel.")
                end
            end)
        end
    end
end)
