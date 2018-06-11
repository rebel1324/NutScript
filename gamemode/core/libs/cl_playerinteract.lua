nut.playerInteract = nut.playerInteract or {}
nut.playerInteract.funcs = {}

-- Current entity focused by player interaction
nut.playerInteract.currentEnt = nil

-- Time when interaction menu should open
local interactPressTime = 0
local cachedPitch = 0
local isInteracting = false
local interfaceScale = 0
local selectedFunction = nil

function nut.playerInteract.addFunc(name, data)
    nut.playerInteract.funcs[name] = data
end

function nut.playerInteract.interact(entity, time)
    nut.playerInteract.currentEnt = entity

    interactPressTime = CurTime() + (time or 1)
    cachedPitch = LocalPlayer():EyeAngles().p
    isInteracting = true
end

function nut.playerInteract.clear()
    isInteracting = false
    cachedPitch = 0
    interactPressTime = 0
end

hook.Add("KeyPress", "nut.playerInteract", function(client, key)
    if key ~= IN_USE then return end

    local entity = client:GetEyeTrace().Entity
    if (entity:IsPlayer()) then
        nut.playerInteract.interact(entity, nut.config.get("playerInteractSpeed", 1))
    end
end)

hook.Add("KeyRelease", "nut.playerInteract", function(client, key)
    if (key == IN_USE and isInteracting) then
        nut.playerInteract.clear()
    end
end)

local function isLoading()
    return interactPressTime > CurTime()
end

local scrW = ScrW()
local scrH = ScrH()
hook.Add("HUDPaint", "nut.playerInteract", function()
    if (!isInteracting and interfaceScale < 0) then return end

    local client = LocalPlayer()
    local target = nut.playerInteract.currentEnt

    if (IsValid(target) and target:GetPos():DistToSqr(client:GetPos()) > 30000) then
        nut.playerInteract.clear()
    end

    local curTime = CurTime()
    local posX = scrW / 2
    local posY = scrH / 2

    interfaceScale = Lerp(FrameTime() * 8, interfaceScale, (isInteracting and interactPressTime < curTime) and 1 or -0.1)

    if (isLoading()) then
        local loadingMaxW = 128
        local progress = 1 - (interactPressTime - curTime)
        local curLoadingW = loadingMaxW * progress
        local loadingCentreX = ScrW() / 2
        local loadingCentreY = ScrH() / 2 + 86
        local loadingH = 10

        nut.util.drawBlurAt(loadingCentreX - (loadingMaxW / 2), loadingCentreY, loadingMaxW, loadingH)

        surface.SetDrawColor(Color(0, 0, 0, 150))
        surface.DrawRect(loadingCentreX - (loadingMaxW / 2), loadingCentreY, loadingMaxW, loadingH, 1)

        surface.SetDrawColor(255, 255, 255, 120)
        surface.DrawOutlinedRect(loadingCentreX - (loadingMaxW / 2) + 1, loadingCentreY + 1, loadingMaxW - 2, loadingH - 2)

        surface.SetDrawColor(color_white)
        surface.DrawRect(loadingCentreX - (curLoadingW / 2) + 2, loadingCentreY + 2, ( loadingMaxW - 4 ) * progress, loadingH - 4, 1)      
    end

    if (interfaceScale < 0) then return end

    local pitchDifference = (cachedPitch - EyeAngles().p) * 6

    local funcCount = 0
    for _, funcData in SortedPairs(nut.playerInteract.funcs) do
        if (!funcData.canSee(target)) then continue end

        local name = funcData.name or L( funcData.nameLocalized )
        surface.SetFont( "nutGenericLightFont" )
        local textW, _ = surface.GetTextSize( name )

        local barW, barH = textW + 16, 32
        local yAlignment = barH * funcCount
        local barX, barY = posX - (barW / 2) * interfaceScale, posY - (barH / 2) + yAlignment * interfaceScale + pitchDifference

        local isSelected = math.abs(yAlignment + pitchDifference) < 32

        if (isSelected and interfaceScale > 0.75) then
            nut.util.drawBlurAt(barX, barY, barW, barH)

            surface.SetDrawColor(55, 55, 55, 120)
            surface.DrawRect(barX, barY, barW, barH)
            surface.SetDrawColor(255, 255, 255, 120)
            surface.DrawOutlinedRect(barX + 1, barY + 1, barW - 2, barH - 2)

            selectedFunction = funcData
        end

        draw.SimpleText(name, "nutGenericLightFont", barX + (barW / 2) + 2, barY + (barH / 2.1) + 2, Color(0, 0, 0, interfaceScale * 128), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(name, "nutGenericLightFont", barX + (barW / 2), barY + (barH / 2.1), Color(255, 255, 255, interfaceScale * 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        funcCount = funcCount + 1
    end
end)

hook.Add("PlayerBindPress", "nut.playerInteract", function(_, bind)
    if (isInteracting and interactPressTime < CurTime() and selectedFunction ~= nil and bind == "+attack") then
        selectedFunction.callback(nut.playerInteract.currentEnt)

        nut.playerInteract.clear()

        return true
    end
end)