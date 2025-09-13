local inventoryData = {}

-- Saves inventory data to a file.
function inventoryData.save(data, name)
    local path = getInventoryFilePath(name)
    local file = fs.open(path, "w")
    if not file then
        error("Failed to open file for writing: " .. path)
    end
    file.write(textutils.serialize(data))
    file.close()
end

-- Loads inventory data from a file.
function inventoryData.load(name)
    local path = getInventoryFilePath(name)
    if not fs.exists(path) then
        return nil -- Gracefully handle missing files
    end

    local file = fs.open(path, "r")
    if not file then
        error("Failed to open file for reading: " .. path)
    end
    local data = file.readAll()
    file.close()
    return textutils.unserialize(data)
end

return inventoryData