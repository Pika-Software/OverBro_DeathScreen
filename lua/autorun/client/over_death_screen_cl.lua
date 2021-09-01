-- 𝒜𝓉𝓉𝑒𝓃𝓉𝒾𝑜𝓃 𝒸𝓇𝒾𝓃𝑔𝑒
local tag = "OverBroDeathScreen"
local tyanka = Material("ui/tyan", "smooth")
local dof = Material("pp/dof")
local w, h, imageSize = 0, 0
local first_run = false
local time = 0.5

local enable = CreateClientConVar("overbro_death_screen", "1", true, true, "Enable OverBro death screen"):GetBool()
local screenShake = CreateClientConVar("overbro_screen_shake", "1", true, true, "Enable screen shake on OverBro death screen", 0, 1):GetBool()
local nofirsttime = CreateClientConVar("overbro_nofirst_time", "0", true, true, "Enable infinity first time", 0, 1):GetBool()

cvars.AddChangeCallback("overbro_death_screen", function(name, old, new)
    enable = tobool(new)
end, "overbro_ds")

cvars.AddChangeCallback("overbro_screen_shake", function(name, old, new)
    screenShake = tobool(new)
end, "overbro_ds")

cvars.AddChangeCallback("overbro_nofirst_time", function(name, old, new)
    nofirsttime = tobool(new)
end, "overbro_ds")

local Sounds = {
    ["first_run"] = "sound/overbro_death_screen/first_run.ogg",
    ["pre_loop"] = "sound/overbro_death_screen/pre_loop.ogg",
    ["loop"] = "sound/overbro_death_screen/loop.ogg",
}

local playing = playing or nil
local function StopPlaying()
    if IsValid(playing) then
        playing:Stop()
    end
end

local function PlayOgg(name, callback)
    local fl = Sounds[name]
    if fl then
        StopPlaying()

        sound.PlayFile(fl, "noplay", function(station)
            if IsValid(station) then
                playing = station
                station:Play()
                if callback then
                    callback(station)
                end
            end
        end)
    end
end

local function playLoop(name, func)
    PlayOgg(name, function(station)
        timer.Create(tag, station:GetLength(), 1, function()
            playLoop(name)
            if func then
                func(station)
            end
        end)
    end)
end

local function playPreLoop()
    PlayOgg("pre_loop", function(station)
        timer.Create(tag, station:GetLength() - 0.2, 1, function()
            playLoop("loop", function(st)
                if IsValid(st) then
                    st:SetTime(1)
                end
            end)
        end)
    end)
end

local SetColor = surface.SetDrawColor
local DrawRect = surface.DrawRect
local SetMaterial = surface.SetMaterial
local DrawTexturedRect = surface.DrawTexturedRect

gameevent.Listen("entity_killed")
hook.Add("entity_killed", "PlayerDeath", function(data)
    if enable and data.entindex_killed then
        local ply = Entity(data.entindex_killed)
        if IsValid(ply) and ply == LocalPlayer() then
            w, h, imageSize = ScrW(), ScrH(), ScreenScale(256)
    
            local oldMult = 0
            local delay = 0
            local mult = 0
            local fps = 0

            hook.Add("DrawOverlay", tag, function()
                if !enable then
                    hook.Remove("DrawOverlay", tag)
                    timer.Stop(tag)
                    StopPlaying()
                end

                if first_run then
                    local curtime = CurTime()
                    if delay < curtime and mult <= 1 then 
                        fps = math.min(60, 1/FrameTime())
                        local need = time/fps
                        mult = math.min(1, oldMult + ((mult + need)-oldMult)/time)
                        oldMult = mult 
                        delay = curtime + need
                    end

                    local x, y = w*mult, h*mult
                    SetColor(color_white)
                    DrawRect((w-x)/2, h-y, x, y)
                    SetMaterial(tyanka)
                    local size = imageSize*mult
                    DrawTexturedRect((w - size)/2, h-size*2, size, size*2)
                elseif screenShake and IsValid(playing) then
                    local bass, fft = 0, {}
                    playing:FFT(fft, 6 )
            
                    for i = 1, 250 do
                        if fft[i] then bass = math.max(bass, fft[i]*170) or 0 end
                    end

                    if bass > 50 then
                        util.ScreenShake(Vector(), bass/10, 1/FrameTime(), 10, 0)
                    end
                end
            end)
            
            local pre = false
            if !first_run then
                PlayOgg("first_run", function(station)
                    pre = false
                    timer.Create(tag, station:GetLength(), 1, function()
                        if !pre then
                            playPreLoop()
                            pre = true
                        else
                            playLoop("loop")
                        end
                        first_run = true
                    end)
                end)
            else
                playPreLoop()
            end
        end
    end
end)

gameevent.Listen("player_spawn")
hook.Add("player_spawn", "PlayerSpawn", function(data)
    if enable and data.userid then
        local ply = Player(data.userid)
        if IsValid(ply) and ply == LocalPlayer() then
            hook.Remove("DrawOverlay", tag)
            timer.Stop(tag)
            StopPlaying()
            if nofirsttime then
                first_run = false
            end
        end
    end
end)