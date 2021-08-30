-- 𝒜𝓉𝓉𝑒𝓃𝓉𝒾𝑜𝓃 𝒸𝓇𝒾𝓃𝑔𝑒
local tag = "OverBroDeathScreen"
local tyanka = Material("ui/tyan", "smooth")
local w, h, imageSize = 0, 0
local time = 0.35

local function resolutionChanged()
    w, h, imageSize = ScrW(), ScrH(), ScreenScale(256)
end

local SetColor = surface.SetDrawColor
local DrawRect = surface.DrawRect
local SetMaterial = surface.SetMaterial
local DrawTexturedRect = surface.DrawTexturedRect
local white_col = color_white

local function Remove()
    hook.Remove("DrawOverlay", tag)
    if IsValid(OverBroDeathScreenSound) then
        OverBroDeathScreenSound:Stop()
    end
end

local function Create(ply)
    local oldMult = 0
    local delay = 0
    local mult = 0
    local fps = 0
    
    hook.Add("DrawOverlay", tag, function()
        if delay < CurTime() and mult <= 1 then 
            fps = math.min(60, 1/FrameTime())
            local need = time/fps
            mult = math.min(1, oldMult + ((mult + need)-oldMult)/time)
            oldMult = mult 
            delay = CurTime() + need
        end

        local x, y = w*mult, h*mult
        SetColor(white_col)
        DrawRect((w-x)/2, h-y, x, y)
        SetMaterial(tyanka)
        local size = imageSize*mult
        DrawTexturedRect((w - size)/2, h-size*2, size, size*2)
    end)

    if IsValid(OverBroDeathScreenSound) then
        OverBroDeathScreenSound:Stop()
    end

    sound.PlayFile("sound/ui/flex.ogg", "noplay", function(station)
        if IsValid(station) then
            station:Play()
            OverBroDeathScreenSound = station
        end
    end)
end

hook.Add("OnScreenSizeChanged", tag, function()
    resolutionChanged()
end)

gameevent.Listen("entity_killed")
hook.Add("entity_killed", "PlayerDeath", function(data)
    if data.entindex_killed then
        local ply = Entity(data.entindex_killed)
        if IsValid(ply) and ply == LocalPlayer() then
            resolutionChanged()
            Create(ply)
        end
    end
end)

gameevent.Listen("player_spawn")
hook.Add("player_spawn", "PlayerSpawn", function(data)
    if data.userid then
        local ply = Player(data.userid)
        if IsValid(ply) and ply == LocalPlayer() then
            Remove()
        end
    end
end)