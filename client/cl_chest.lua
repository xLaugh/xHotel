ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "Somme", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500)
        blockinput = false
        return result
    else
        Citizen.Wait(500)
        blockinput = false
        return nil
    end
end

local open = false
local mainMenu = RageUI.CreateMenu("Coffre", "Interaction", nil, nil, "root_cause5", "img_red")
local inventaire = RageUI.CreateSubMenu(mainMenu, "Inventaire", "Interaction")
local coffre = RageUI.CreateSubMenu(mainMenu, "Coffre", "Interaction")
mainMenu.Display.Header = true
mainMenu.Closed = function()
    open = false
    FreezeEntityPosition(PlayerPedId(), false)
end

local inventory, stock = {}, {}

local function getInventory()
    ESX.TriggerServerCallback("xHotel:getInventory", function(result)
        inventory = result
    end)
end

local function getStock(id)
    ESX.TriggerServerCallback("xHotel:getStock", function(result)
        stock = result
    end, id)
end

local depositLock = false
local withdrawLock = false

function openChestMenu(id)
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
                    RageUI.Button("Déposer des objets", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() getInventory() end}, inventaire)
                    RageUI.Button("Retirer des objets", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() getStock(id) end}, coffre)
                end)
                RageUI.IsVisible(inventaire, function()
                    if #inventory > 0 then
                        for _,v in pairs(inventory) do
                            RageUI.Button(("~r~→~s~ %s"):format(v.label), nil, {RightLabel = ("~r~x%s~s~"):format(v.count)}, true, {
                                onSelected = function()
                                    if depositLock then
                                        ESX.ShowNotification("(~r~Erreur~s~)\nUne autre opération de dépôt est en cours.")
                                        return
                                    end
                                    local count = KeyboardInput("Combien souhaitez-vous déposer:", "", 5)
                                    if count ~= nil and count ~= "" then
                                        if tonumber(count) then
                                            count = tonumber(count)
                                            if count > v.count then
                                                ESX.ShowNotification("(~r~Erreur~s~)\nVous n'en avez pas suffisamment.")
                                            else
                                                depositLock = true
                                                TriggerServerEvent("xHotel:addItemChest", v.name, v.label, count, id)
                                                Wait(1000)
                                                getInventory()
                                                depositLock = false
                                            end
                                        else
                                            ESX.ShowNotification("(~r~Erreur~s~)\nQuantité invalide.")
                                        end
                                    else
                                        ESX.ShowNotification("(~r~Erreur~s~)\nQuantité invalide.")
                                    end
                                end
                            })
                        end
                    else
                        RageUI.Separator("")
                        RageUI.Separator("~r~Votre sac à dos est vide.")
                        RageUI.Separator("")
                    end
                end)
                RageUI.IsVisible(coffre, function()
                    for _,v in pairs(stock) do
                        if v.cb > 0 then
                            RageUI.Button(("~r~→~s~ %s"):format(v.label), nil, {RightLabel = ("~r~x%s~s~"):format(v.cb)}, true, {
                                onSelected = function()
                                    if withdrawLock then
                                        ESX.ShowNotification("(~r~Erreur~s~)\nUne autre opération de retrait est en cours.")
                                        return
                                    end
                                    local count = KeyboardInput("Combien souhaitez-vous prendre:", "", 5)
                                    if count ~= nil and count ~= "" then
                                        if tonumber(count) then
                                            count = tonumber(count)
                                            if count > v.cb then
                                                ESX.ShowNotification("(~r~Erreur~s~)\nIl n'y en a pas suffisamment dans le coffre.")
                                            else
                                                withdrawLock = true
                                                TriggerServerEvent("xHotel:removeItemChest", v.name, v.label, count, id)
                                                Wait(1000)
                                                getStock(id)
                                                withdrawLock = false
                                            end
                                        else
                                            ESX.ShowNotification("(~r~Erreur~s~)\nQuantité invalide.")
                                        end
                                    else
                                        ESX.ShowNotification("(~r~Erreur~s~)\nQuantité invalide.")
                                    end
                                end
                            })
                        end
                    end
                end)
            end
        end)
    end
end
