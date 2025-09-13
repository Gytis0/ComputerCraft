local GITHUB_USER = "Gytis0"
local REPO_NAME   = "ComputerCraft"
local BRANCH      = "main"

-- Utility to download a folder recursively
local function downloadFolder(pathOnGitHub, pathOnComputer)
    local apiUrl = (
        "https://api.github.com/repos/%s/%s/contents/%s?ref=%s"
    ):format(GITHUB_USER, REPO_NAME, textutils.urlEncode(pathOnGitHub), BRANCH)

    local response = http.get(apiUrl)
    if not response then
        print("Failed to fetch folder: " .. pathOnGitHub)
        return false
    end

    local data = textutils.unserializeJSON(response.readAll())
    response.close()

    if not fs.exists(pathOnComputer) then
        fs.makeDir(pathOnComputer)
    end

    for _, item in ipairs(data) do
        local subGitPath = item.path
        local subLocalPath = fs.combine(pathOnComputer, item.name)

        if item.type == "file" then
            local isCfg = item.name:match("%.cfg$")

            -- If it's a .cfg and already exists, skip it
            if isCfg and fs.exists(subLocalPath) then
                print("Skipping existing config file: " .. subLocalPath)
            else
                print("Downloading: " .. subGitPath)
                local fileRes = http.get(item.download_url)
                if fileRes then
                    local contents = fileRes.readAll()
                    fileRes.close()

                    local file = fs.open(subLocalPath, "w")
                    file.write(contents)
                    file.close()
                else
                    print("Failed to download: " .. item.name)
                end
            end
        elseif item.type == "dir" then
            downloadFolder(subGitPath, subLocalPath)
        end
    end

    return true
end

-- Step 1: List all root folders (projects)
local function getProjectList()
    local url = ("https://api.github.com/repos/%s/%s/contents/?ref=%s")
        :format(GITHUB_USER, REPO_NAME, BRANCH)

    local res = http.get(url)
    if not res then
        print("Failed to fetch repo contents.")
        return nil
    end

    local data = textutils.unserializeJSON(res.readAll())
    res.close()

    local projects = {}
    for _, item in ipairs(data) do
        if item.type == "dir" then
            table.insert(projects, item.name)
        end
    end

    return projects
end

-- Step 2: Present menu to user
local function chooseProject(projects)
    print("Available Projects:")
    for i, name in ipairs(projects) do
        print(("[%d] %s"):format(i, name))
    end

    while true do
        write("Enter number to install: ")
        local input = read()
        local choice = tonumber(input)
        if choice and projects[choice] then
            return projects[choice]
        else
            print("Invalid selection.")
        end
    end
end

-- Main
local projects = getProjectList()
if not projects or #projects == 0 then
    print("No projects found.")
    return
end

local selected = chooseProject(projects)
print("Installing project: " .. selected)
local success = downloadFolder(selected, selected)

if success then
    print("Project installed to /" .. selected)
else
    print("Installation failed.")
end
