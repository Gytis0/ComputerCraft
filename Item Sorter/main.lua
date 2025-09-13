local inventoryData = require("inventoryData")

function getAllInventories()
    modem = peripheral.find("modem")
    allPeripherals = modem.getNamesRemote()
    allInventories = {}

    for index, peripheralName in pairs(allPeripherals) do
        peripheralType = peripheral.getType(peripheralName)
        if peripheralType == "minecraft:chest" or peripheralType == "minecraft:barrel" then
            table.insert(allInventories, peripheralName)
        end
    end

    return allInventories
end

function scanInventories(append)
    local allInventories = getAllInventories()

    for _, inventoryName in ipairs(allInventories) do
        local data

        if append then
            data = loadInventoryData(inventoryName .. "_items.txt") or {
                inventoryName = inventoryName,
                items = {}
            }
        else
            data = {
                inventoryName = inventoryName,
                items = {}
            }
        end

        local chest = peripheral.wrap(inventoryName)
        local items = chest.list()

        for slot, item in pairs(items) do
            if not data.items[item.name] then
                data.items[item.name] = {}
            end
            data.items[item.name][slot] = true
        end

        saveInventoryData(data, inventoryName .. "_items.txt")
    end
end

function findInputAndTrashChests()
    local modem = peripheral.find("modem")
    if not modem then
        error("No modem found!")
    end

    local allPeripherals = modem.getNamesRemote()
    local inputChests = {}
    local trashChests = {}

    for _, peripheralName in pairs(allPeripherals) do
        local peripheralType = peripheral.getType(peripheralName)

        if peripheralType == "minecraft:chest" or peripheralType == "minecraft:barrel" or peripheralType == "minecraft:trapped_chest" then
            local chest = peripheral.wrap(peripheralName)
            local items = chest.list()

            for slot, item in pairs(items) do
                if item.name == "minecraft:paper" and item.displayName then
                    local lowerName = string.lower(item.displayName)

                    if lowerName == "input" then
                        table.insert(inputChests, chest)
                        break
                    elseif lowerName == "trash" then
                        table.insert(trashChests, chest)
                        break
                    end
                end
            end
        end
    end

    return inputChests, trashChests
end


function findItemPlace(itemName)
    allFiles = fs.list(fs.getDir(shell.getRunningProgram()) .. "/inventoryData")

    for k,v in pairs(allFiles) do
        data = loadInventoryData(v)
        if data["items"][itemName] ~= nil then return data["inventoryName"], data["items"][itemName] end
    end

    return nil, nil
end

function sortItems()
    unsortedItems = inputChest.list()
    success = 0
    lastIndex = 0

    for slot, item in pairs(unsortedItems) do
        print("Sorting " .. item.name .. "...")
        inventoryName, slots = findItemPlace(item.name)

        -- If such item exists in the data files, try to sort it
        if inventoryName ~= nil then
            for index, boolean in pairs(slots) do
                success = inputChest.pushItems(inventoryName, slot, nil, index)
                lastIndex = index
                if success > 0 and inputChest.getItemDetail(slot) == nil then
                    break
                end
            end
            
            -- If we can't find space for an item, try slots that are close to the reserved slots
            -- To the right
            if success == 0 then
                inventory = peripheral.wrap(inventoryName)
                inventorySize = inventory.size()
                for i = lastIndex + 1, inventorySize do
                    success = inputChest.pushItems(inventoryName, slot, nil, i)
                    lastIndex = index
                    if success > 0 then
                        break
                    end
                end
            end

            -- To the left
            if success == 0 then
                for i = lastIndex - 1, 1, -1 do
                    success = inputChest.pushItems(inventoryName, slot, nil, i)
                    lastIndex = index
                    if success > 0 then
                        break
                    end
                end
            end

            -- If there's no space for the item, push it to the trash chest
            inputChest.pushItems(peripheral.getName(trashChest), slot, nil, nil)
        else -- If such item does not exist in the data, push it to the trash chest
            inputChest.pushItems(peripheral.getName(trashChest), slot, nil, nil)
        end
    end

    -- If after sorting there are still items to sort, and there is still space in trash chest, sort again
    if table.getn(inputChest.list()) > 0 and table.getn(trashChest.list()) < trashChest.size() then
        sortItems()
    end
end

------------------------------------------------------------
-- Only the first two trapped chests will be accounted for
-- Only chests and barrels will be counted as storage
-- Temporarily, only four redstone signals are accepted:
--      # Back: turn off
--      # Left: scan without append
--      # Right: scan with append
--      # Top: sort (while active)
--      # Bottom: reserved for modem
--      # Front: reserved for interface

inputChest, trashChest = findInputAndTrashChests()

while true do
    local event = os.pullEvent("redstone")

    if rs.getInput("back") then
        print("Ending program...")
        break
    elseif rs.getInput("left") then
        scan(false)
    elseif rs.getInput("right") then
        scan(true)
    elseif rs.getInput("bottom") then
        sortItems()
    end
end