Utils = {}

-- Mensagem no canto superior esquerdo (estilo GTAO)
function Utils.ShowHelp(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Mensagem no canto superior esquerdo (estilo GTAO) com ícone
function Utils.ShowNotification(msg, blink, saveToBrief)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(blink or false, saveToBrief or false)
end

-- Mensagem no rodapé central da tela (estilo missão GTA)
function Utils.ShowMissionText(text, duration)
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(duration or 60000, true)
end

function Utils.ShowScaleformMessage(info)
    local scaleform = RequestScaleformMovie("MIDSIZED_MESSAGE")
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(0)
    end

    BeginScaleformMovieMethod(scaleform, "SHOW_COND_SHARD_MESSAGE")
    PushScaleformMovieMethodParameterString(info.title or "INFORMAÇÃO")
    PushScaleformMovieMethodParameterString(info.msg or "Mensagem padrão")
    EndScaleformMovieMethod()

    if info.audioName and info.audioRef then
        PlaySoundFrontend(-1, info.audioName, info.audioRef, 0)
    end

    local duration = info.sec or 3.0
    local endTime = GetGameTimer() + math.floor(duration * 1000)

    CreateThread(function()
        while GetGameTimer() < endTime do
            Wait(0)
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
        end
        SetScaleformMovieAsNoLongerNeeded(scaleform)
    end)
end

-- QBCORE
-- CLIENT
local QBCore = exports['qb-core']:GetCoreObject()

function Utils.Notify(msg, type, duration)
    QBCore.Functions.Notify(msg, type, duration)
end

--- SERVER
if not IsDuplicityVersion() then return end

function Utils.GetIdentifier(source)
    local player = QBCore.Functions.GetPlayer(source)
    return player.PlayerData.citizenid
end

function Utils.AddItem(source, item, count)
    local player = QBCore.Functions.GetPlayer(source)
    return player.Functions.AddItem(item, count)
end

function Utils.GetJobCount(source, job)
    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.name == job then
            amount = amount + 1
        end
    end
    return amount
end