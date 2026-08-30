-- vMenu Discord nickname bridge
-- Keeps the Discord bot token server-side and only sends nicknames to clients.

local nicknames = {}
local refreshGeneration = 0

local function getConfig()
    local token = GetConvar('vmenu_discord_bot_token', '')
    local guildId = GetConvar('vmenu_discord_guild_id', '')
    return token, guildId
end

local function getDiscordId(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'discord:' then
            return identifier:sub(9)
        end
    end
    return nil
end

local function sendNickname(target, serverId, nickname)
    TriggerClientEvent('vMenu:SetDiscordNickname', target, tonumber(serverId), nickname or '')
end

local function syncAllToClient(target)
    for serverId, nickname in pairs(nicknames) do
        sendNickname(target, serverId, nickname)
    end
end

local function fetchNickname(src, generation)
    local token, guildId = getConfig()
    if token == '' or guildId == '' then
        return
    end

    local discordId = getDiscordId(src)
    if not discordId then
        nicknames[tostring(src)] = nil
        sendNickname(-1, src, '')
        return
    end

    local url = ('https://discord.com/api/v10/guilds/%s/members/%s'):format(guildId, discordId)
    PerformHttpRequest(url, function(statusCode, body)
        if generation and generation ~= refreshGeneration then return end

        local nickname = nil
        if statusCode == 200 and body and body ~= '' then
            local ok, member = pcall(json.decode, body)
            if ok and member and type(member.nick) == 'string' and member.nick ~= '' then
                nickname = member.nick
            end
        elseif statusCode == 401 or statusCode == 403 then
            print(('^1[vMenu Discord Names]^7 Discord API returned HTTP %s. Check the bot token and that the bot is in the configured guild.'):format(statusCode))
        end

        local key = tostring(src)
        if nickname then
            nicknames[key] = nickname
            sendNickname(-1, src, nickname)
        else
            nicknames[key] = nil
            sendNickname(-1, src, '')
        end
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. token,
        ['Content-Type'] = 'application/json'
    })
end

local function refreshAll()
    refreshGeneration = refreshGeneration + 1
    local generation = refreshGeneration
    for _, playerId in ipairs(GetPlayers()) do
        fetchNickname(tonumber(playerId), generation)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    local token, guildId = getConfig()
    if token == '' or guildId == '' then
        print('^3[vMenu Discord Names]^7 Not configured. Add vmenu_discord_bot_token and vmenu_discord_guild_id to server.cfg.')
        return
    end

    print('^2[vMenu Discord Names]^7 Discord nickname integration enabled.')
    SetTimeout(1500, refreshAll)
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(2000, function()
        if GetPlayerName(src) then
            fetchNickname(src, refreshGeneration)
            syncAllToClient(src)
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    nicknames[tostring(src)] = nil
    sendNickname(-1, src, '')
end)

RegisterNetEvent('vMenu:RequestDiscordNicknames', function()
    local src = source
    syncAllToClient(src)
end)

CreateThread(function()
    while true do
        Wait(300000)
        refreshAll()
    end
end)
