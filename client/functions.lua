local fov_max = 40.0
local fov_min = 80.0
local zoomspeed = 100.0
local fov = (fov_max+fov_min)*0.5
local toggle = false;

prop = nil
secondaryprop = nil
ron = 50.0

function zoom(cam,scrollType)
    if scrollType == "ScrollDown" then
        fov = math.max(fov - zoomspeed, fov_min)
    end
    
    if scrollType == "Scrollup" then
        fov = math.min(fov + zoomspeed, fov_max)
    end

    local current_fov = GetCamFov(cam)
    if math.abs(fov-current_fov) < 0.1 then
        fov = current_fov
    end
    SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    ron = current_fov + (fov - current_fov)*0.05
end
 
function rotationToDirection(rotation)
    local z = degToRad(rotation.z)
    local x = degToRad(rotation.x)
    local num = math.abs(math.cos(x))

    return vector3((-math.sin(z) * num),math.cos(z) * num,math.sin(x))
end
  
function w2s(position)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(position.x, position.y, position.z)
    if not onScreen then
        return nil
    end
    return vector3((_x - 0.5) * 2,(_y - 0.5) * 2,0.0)
end

function processCoordinates(x, y)
    local screenX, screenY = GetActiveScreenResolution()
    local relativeX = 1 - (x / screenX) * 1.0 * 2
    local relativeY = 1 - (y / screenY) * 1.0 * 2

    if relativeX > 0.0 then
        relativeX = -relativeX;
    else
        relativeX = math.abs(relativeX)
    end

    if relativeY > 0.0 then
        relativeY = -relativeY
    else
        relativeY = math.abs(relativeY)
    end

    return { x = relativeX, y = relativeY }
end

function s2w(camPos, relX, relY,cam)
    local camRot = GetCamRot(cam,2)
    local camForward = rotationToDirection(camRot)
    local rotUp = ( camRot + vector3(10.0,0.0,0.0) )
    local rotDown = ( camRot + vector3(-10.0,0.0,0.0) )
    local rotLeft = ( camRot + vector3(0.0,0.0,-10.0) )
    local rotRight = ( camRot + vector3(0.0,0.0,10.0) )

    local camRight = (rotationToDirection(rotRight) - rotationToDirection(rotLeft))
    local camUp = (rotationToDirection(rotUp)- rotationToDirection(rotDown))

    local rollRad = -degToRad(camRot.y)
    local camRightRoll = ((camRight* math.cos(rollRad))- (camUp* math.sin(rollRad)))
    local camUpRoll = ((camRight* math.sin(rollRad))+ (camUp* math.cos(rollRad)))

    local point3D = (((camPos+ (camForward* 10.0))+camRightRoll)+camUpRoll)

    local point2D = w2s(point3D)

    if point2D == nil then
        return (camPos +  (camForward* 10.0))
    end

    local point3DZero = (camPos+ (camForward* 10.0))
    local point2DZero = w2s(point3DZero)

    if point2DZero == nil then
        return (camPos+ (camForward* 10.0))
    end

    local eps = 0.001
    if math.abs(point2D.x - point2DZero.x) < eps or math.abs(point2D.y - point2DZero.y) < eps then
        return (camPos + (camForward* 10.0))
    end

    local scaleX = (relX - point2DZero.x) / (point2D.x - point2DZero.x)
    local scaleY = (relY - point2DZero.y) / (point2D.y - point2DZero.y)
    local point3Dret = (((camPos+ (camForward* 10.0))+ (camRightRoll* scaleX))+ (camUpRoll* scaleY))

    return point3Dret
end

function degToRad(deg)
    return (deg * math.pi) / 180.0
end
  
function screenToWorld(flags, cam)
    local x, y = GetNuiCursorPosition()

    local absoluteX = x
    local absoluteY = y

    local camPos = GetGameplayCamCoord()
    camPos = GetCamCoord(cam)
    local processedCoords = processCoordinates(absoluteX, absoluteY)
    local target = s2w(camPos, processedCoords.x, processedCoords.y,cam)

    local dir = (target-camPos)
    local from = (camPos+(dir* 0.05))
    local to = (camPos+(dir* 300))

    local ray = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignore, 0)
    local a, b, c, d, e = GetShapeTestResult(ray)
    return b, c, e, to
end
  
function GetEntityMouseOn(cam)
    local hit,endCoords,entityHit,_ = screenToWorld(2,cam)
    return hit,endCoords,entityHit
end

function closeVehicleShop()
    DoScreenFadeOut(500)
    Wait(500)
    if newVehicle and DoesEntityExist(newVehicle) then
        DeleteEntity(newVehicle)
        newVehicle = nil
        spawnVehicle = false
    end
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true, false)
    SetNuiFocus(false, false)
    SendNUIMessage({action = "close"})
    SetEntityCoords(PlayerPedId(), Config.Location.x, Config.Location.y, Config.Location.z)
    SetEntityHeading(PlayerPedId(), Config.Location.w or 0.0)
    TriggerEvent("change:time", false)
    RenderScriptCams(false, false, 0, true, true)
    DestroyAllCams(true)
    Wait(500)
    DoScreenFadeIn(1000)
    Wait(1000)
end

function closeVehicleShopAfterBuy()
    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    Wait(500)
    if newVehicle and DoesEntityExist(newVehicle) then
        DeleteEntity(newVehicle)
        newVehicle = nil
        spawnVehicle = false
    end
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true, false)
    SetEntityCoords(PlayerPedId(), Config.LocationAfterBuy.x, Config.LocationAfterBuy.y, Config.LocationAfterBuy.z)
    SetEntityHeading(PlayerPedId(), Config.LocationAfterBuy.w or 0.0)
    TriggerEvent("change:time", false)
    TriggerEvent("vehicles:client:anim")
    SendNUIMessage({action = "vehicleBought"})
    toggle = true
    CreateThread(disable)
    RenderScriptCams(false, false, 0, true, true)
    DestroyAllCams(true)
    Wait(500)
    DoScreenFadeIn(1000)
    Wait(4000)
    toggle = false
    close()
end

function closeVehicleShopTestDrive()
    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    Wait(500)
    if newVehicle and DoesEntityExist(newVehicle) then
        DeleteEntity(newVehicle)
        newVehicle = nil
        spawnVehicle = false
    end
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true, false)
    SetEntityCoords(PlayerPedId(), Config.TestDriveFinishLocation.x, Config.TestDriveFinishLocation.y, Config.TestDriveFinishLocation.z)
    SetEntityHeading(PlayerPedId(), Config.TestDriveFinishLocation.w or 0.0)
    TriggerEvent("change:time", false)
    RenderScriptCams(false, false, 0, true, true)
    DestroyAllCams(true)
    Wait(500)
    DoScreenFadeIn(1000)
end

function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

RegisterNetEvent('vehicles:client:anim')
AddEventHandler('vehicles:client:anim', function()
    local player = PlayerPedId()
    local ad = "missheistdockssetup1clipboard@base"
                
    local prop_name = 'prop_notepad_01'
    local secondaryprop_name = 'prop_pencil_01'
    
    if DoesEntityExist(player) and not IsEntityDead(player) then 
        loadAnimDict(ad)
        if IsEntityPlayingAnim( player, ad, "base", 3 ) then 
            TaskPlayAnim( player, ad, "exit", 8.0, 1.0, -1, 49, 0, 0, 0, 0 )
            Wait(100)
            ClearPedSecondaryTask(player)
            DetachEntity(prop, 1, 1)
            DeleteObject(prop)
            DetachEntity(secondaryprop, 1, 1)
            DeleteObject(secondaryprop)
        else
            local x,y,z = table.unpack(GetEntityCoords(player))
            prop = CreateObject(GetHashKey(prop_name), x, y, z+0.2,  true,  true, true)
            secondaryprop = CreateObject(GetHashKey(secondaryprop_name), x, y, z+0.2,  true,  true, true)
            AttachEntityToEntity(prop, player, GetPedBoneIndex(player, 18905), 0.1, 0.02, 0.05, 10.0, 0.0, 0.0, true, true, false, true, 1, true)
            AttachEntityToEntity(secondaryprop, player, GetPedBoneIndex(player, 58866), 0.12, 0.0, 0.001, -150.0, 0.0, 0.0, true, true, false, true, 1, true)
            TaskPlayAnim(player, ad, "base", 8.0, 1.0, -1, 49, 0, 0, 0, 0 )
        end 
    end
end)

function close()
    TaskPlayAnim(PlayerPedId(), "missheistdockssetup1clipboard@base", "exit", 8.0, 1.0, -1, 49, 0, 0, 0, 0 )
    Wait(100)
    ClearPedSecondaryTask(PlayerPedId())
    DetachEntity(prop, 1, 1)
    DeleteObject(prop)
    DetachEntity(secondaryprop, 1, 1)
    DeleteObject(secondaryprop)
    prop = nil
    secondaryprop = nil
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

function disable()
    while toggle do 
        Wait(0)
        DisableControlAction(0, 30, true) -- disable left/right
        DisableControlAction(0, 31, true) -- disable forward/back
        DisableControlAction(0, 36, true) -- INPUT_DUCK
        DisableControlAction(0, 21, true) -- disable sprint
    end
end