function save(table,name)
    local file = fs.open(fs.getDir(shell.getRunningProgram()) .. "/inventoryData/" .. name,"w")
    file.write(textutils.serialize(table))
    file.close()
end

function load(name)
    local file = fs.open(fs.getDir(shell.getRunningProgram()) .. "/inventoryData/" .. name,"r")
    local data = file.readAll()
    file.close()
    return textutils.unserialize(data)
end

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
    allInventories = getAllInventories()
    
    for k, v in pairs(allInventories) do
        if append then
            data = load(v .. "_items.txt")
        else
            data = {inventoryName = v, items = {}}
        end

        inventory = peripheral.wrap(v)
        for slot, item in pairs(inventory.list()) do
            if data["items"][item.name] == nil then
                data["items"][item.name] = {}
            end

            data["items"][item.name][slot] = true
        end

        save(data, v .. "_items.txt")
    end
end

function findInputAndTrashChests()
    modem = peripheral.find("modem")
    allPeripherals = modem.getNamesRemote()
    allTrappedChests = {}

    for index, peripheralName in pairs(allPeripherals) do
        peripheralType = peripheral.getType(peripheralName)
        if peripheralType == "minecraft:trapped_chest" then
            table.insert(allTrappedChests, peripheralName)
        end
    end

    if string.sub(allTrappedChests[1], string.len(allTrappedChests[1]), string.len(allTrappedChests[1])) > string.sub(allTrappedChests[2], string.len(allTrappedChests[2]), string.len(allTrappedChests[2])) then
        trashChest = peripheral.wrap(allTrappedChests[1])
        inputChest = peripheral.wrap(allTrappedChests[2])
    else
        inputChest = peripheral.wrap(allTrappedChests[1])
        trashChest = peripheral.wrap(allTrappedChests[2])
    end

    return inputChest, trashChest
end

function findItemPlace(itemName)
    allFiles = fs.list(fs.getDir(shell.getRunningProgram()) .. "/inventoryData")

    for k,v in pairs(allFiles) do
        data = load(v)
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