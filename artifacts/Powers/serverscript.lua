-- ============================================================
--   BLOOD & LIGHTNING POWERS - SERVER SCRIPT (CORREGIDO + RAYO)
--   Coloca esto en: ServerScriptService > Script
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local Debris            = game:GetService("Debris")

-- ─── CARPETA Y REMOTES ───────────────────────────────────────
local RemoteFolder = Instance.new("Folder")
RemoteFolder.Name   = "BloodPowerEvents"
RemoteFolder.Parent = ReplicatedStorage

local function makeRemote(name)
    local r = Instance.new("RemoteEvent")
    r.Name   = name
    r.Parent = RemoteFolder
    return r
end

local RE_BloodBall      = makeRemote("BloodBall")
local RE_BloodCorpuscle = makeRemote("BloodCorpuscle")
local RE_BloodWhip      = makeRemote("BloodWhip")
local RE_Souls1000      = makeRemote("Souls1000")
local RE_Effect         = makeRemote("EffectToAll")
local RE_Stun           = makeRemote("StunTarget")
local RE_Unlock1000     = makeRemote("Unlock1000Souls")
local RE_Anim           = makeRemote("PlayAnim")
local RE_Bracelet       = makeRemote("SpawnBracelet")
-- Rayo
local RE_LightningBolt  = makeRemote("LightningBolt")
local RE_ThunderChain   = makeRemote("ThunderChain")
local RE_ElectricStorm  = makeRemote("ElectricStorm")
local RE_SupremeDisch   = makeRemote("SupremeDisch")
local RE_UnlockSupreme  = makeRemote("UnlockSupreme")

-- ─── COOLDOWNS ───────────────────────────────────────────────
local cooldowns = {}
local stunned   = {}
local whipActive        = {}
local souls1000Unlocked = {}
local supremeUnlocked   = {}

local COOLDOWN = {
    BloodBall      = 4,
    BloodCorpuscle = 8,
    BloodWhip      = 12,
    Souls1000      = 20,
    LightningBolt  = 3,
    ThunderChain   = 7,
    ElectricStorm  = 14,
    SupremeDisch   = 22,
}

-- ─── IDs DE VFX ──────────────────────────────────────────────
local VFX = {
    BB_Fireball        = 113831670560719,
    BB_EnergyBall      = 82367301818626,
    BB_MagicProjectile = 131948820606303,
    BB_ImpactExplosion = 71947288327190,
    BB_ChargeUp        = 122502397357855,
    GL_BloodSpike      = 139916424589528,
    GL_SummonRising    = 134398499898167,
    GL_EarthShatter    = 92035105491671,
    GL_GroundSpike     = 73355950303304,
    WH_EnergyChain     = 111623916390946,
    WH_BeamTrail       = 82367301818626,
    -- Rayo (usa texturas de partículas por defecto de Roblox si los IDs son 0)
    LT_Spark           = 6472702474,
    LT_Electric        = 7486629709,
    LT_Explosion       = 6472702474,
}

-- ─── UTILIDADES ──────────────────────────────────────────────
local function isOnCooldown(player, skill)
    local key = tostring(player.UserId) .. "_" .. skill
    local t   = cooldowns[key]
    if t and (tick() - t) < COOLDOWN[skill] then return true end
    cooldowns[key] = tick()
    return false
end

local function checkStunned(player)
    local endTime = stunned[player]
    if endTime and tick() < endTime then return true end
    stunned[player] = nil
    return false
end

local function getNearestEnemy(caster, radius)
    local hrp = caster.Character and caster.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, dist = nil, radius
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= caster and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            if eh then
                local d = (eh.Position - hrp.Position).Magnitude
                if d < dist then dist = d; closest = p end
            end
        end
    end
    return closest
end

local function getEnemiesInRadius(caster, radius)
    local hrp = caster.Character and caster.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    local result = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= caster and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            if eh and (eh.Position - hrp.Position).Magnitude <= radius then
                table.insert(result, p)
            end
        end
    end
    return result
end

local function dealDamage(target, amount)
    if not target or not target.Character then return false end
    local hum = target.Character:FindFirstChild("Humanoid")
    if hum and hum.Health > 0 then hum:TakeDamage(amount); return true end
    return false
end

local function applyKnockback(target, direction, force)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dir    = direction.Unit
    local capped = Vector3.new(dir.X, math.clamp(dir.Y, -0.3, 0.5), dir.Z).Unit
    local bp     = Instance.new("BodyVelocity")
    bp.Velocity  = capped * force
    bp.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bp.Parent    = hrp
    Debris:AddItem(bp, 0.35)
end

local function spawnBloodParticle(position, color, size, duration)
    local p = Instance.new("Part")
    p.Size       = Vector3.new(size, size, size)
    p.Position   = position
    p.BrickColor = color or BrickColor.new("Bright red")
    p.Material   = Enum.Material.Neon
    p.Shape      = Enum.PartType.Ball
    p.Anchored   = true
    p.CanCollide = false
    p.CastShadow = false
    p.Parent     = Workspace
    Debris:AddItem(p, duration or 1)
    return p
end

-- Crea un segmento de rayo visual (cilindro neón apuntando de A a B)
local function makeZapSegment(posA, posB, color, width, lifetime)
    local dir = posB - posA
    local len = dir.Magnitude
    if len < 0.1 then return end
    local mid = (posA + posB) * 0.5
    local s   = Instance.new("Part")
    s.Size     = Vector3.new(width, width, len)
    s.CFrame   = CFrame.new(mid, posB)
    s.Material = Enum.Material.Neon
    s.Color    = color or Color3.fromRGB(180, 240, 255)
    s.Anchored = true; s.CanCollide = false; s.CastShadow = false
    s.Parent   = Workspace
    -- Luz en el segmento
    local pl = Instance.new("PointLight"); pl.Color=color or Color3.fromRGB(100,200,255)
    pl.Brightness=8; pl.Range=14; pl.Parent=s
    Debris:AddItem(s, lifetime or 0.18)
    TweenService:Create(s, TweenInfo.new(lifetime or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency=1}):Play()
    return s
end

-- Dibuja un rayo zigzag entre dos puntos (épico AAAA calidad)
local function drawLightningBetween(posA, posB, color, segments, width, lifetime, jitter)
    segments = segments or 12
    jitter   = jitter   or 2.0
    width    = width    or 0.12
    lifetime = lifetime or 0.22
    local dir     = posB - posA
    local step    = dir / segments
    local points  = {posA}
    for i = 1, segments - 1 do
        local base = posA + step * i
        local perp1 = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5)
        local off   = perp1.Unit * (math.random() * jitter)
        table.insert(points, base + off)
    end
    table.insert(points, posB)
    -- Múltiples pasadas para efecto de rayo ramificado
    for i = 1, #points - 1 do
        makeZapSegment(points[i], points[i+1], color, width, lifetime)
        -- Rama secundaria aleatoria en ~30% de segmentos
        if math.random() < 0.3 and i < #points - 1 then
            local branchEnd = points[i+1] + Vector3.new(
                (math.random()-0.5)*jitter*1.5,
                (math.random()-0.5)*jitter*1.5,
                (math.random()-0.5)*jitter*1.5
            )
            makeZapSegment(points[i+1], branchEnd,
                color or Color3.fromRGB(100,220,255), width*0.6, lifetime*0.7)
        end
    end
end

-- ─── MANILLA DE SANGRE AL SPAWN ──────────────────────────────
local playerBraceletParts = {}
local playerLeftArm       = {}

local function equipBloodBracelet(player)
    local char = player.Character or player.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    local leftArm = char:FindFirstChild("Left Arm")
        or char:FindFirstChild("LeftHand")
        or char:FindFirstChild("LeftLowerArm")
    if not leftArm then return end

    -- Limpiar previa
    for _, v in ipairs(leftArm:GetChildren()) do
        if v.Name=="BloodBracelet" or v.Name=="BraceletOrb" or v.Name=="BraceletGlow" then
            v:Destroy()
        end
    end

    local isR6   = (leftArm.Name == "Left Arm")
    local wristY = isR6 and -0.82 or -0.25
    local allBraceletParts = {}

    -- Aro principal: 16 perlas
    local RING_COUNT  = 16
    local RING_RADIUS = 0.52
    for i = 1, RING_COUNT do
        local angle = (i / RING_COUNT) * math.pi * 2
        local orb   = Instance.new("Part")
        orb.Name       = "BloodBracelet"
        orb.Size       = Vector3.new(0.13, 0.13, 0.13)
        orb.Shape      = Enum.PartType.Ball
        orb.BrickColor = (i%2==0) and BrickColor.new("Bright red") or BrickColor.new("Crimson")
        orb.Material   = Enum.Material.Neon
        orb.Transparency = 0; orb.CanCollide = false; orb.CastShadow = false
        orb.CFrame     = leftArm.CFrame * CFrame.new(RING_RADIUS*math.cos(angle), wristY, RING_RADIUS*math.sin(angle))
        orb.Parent     = leftArm
        local pl = Instance.new("PointLight")
        pl.Color=Color3.fromRGB(255,0,0); pl.Brightness=0.6; pl.Range=1.5; pl.Parent=orb
        table.insert(allBraceletParts, {part=orb, baseAngle=angle, radius=RING_RADIUS, yOff=wristY, speed=1.4})
    end
    -- Orbs externos: 10
    local OUTER_COUNT=10; local OUTER_RADIUS=0.65
    for i=1,OUTER_COUNT do
        local ba=(i/OUTER_COUNT)*math.pi*2
        local orb=Instance.new("Part"); orb.Name="BraceletOrb"
        local isLarge=(i%2==0)
        orb.Size=isLarge and Vector3.new(0.24,0.24,0.24) or Vector3.new(0.16,0.16,0.16)
        orb.Shape=Enum.PartType.Ball; orb.BrickColor=isLarge and BrickColor.new("Crimson") or BrickColor.new("Bright red")
        orb.Material=Enum.Material.Neon; orb.Transparency=0; orb.CanCollide=false; orb.CastShadow=false
        orb.CFrame=leftArm.CFrame*CFrame.new(OUTER_RADIUS*math.cos(ba),wristY,OUTER_RADIUS*math.sin(ba)); orb.Parent=leftArm
        local pl2=Instance.new("PointLight"); pl2.Color=Color3.fromRGB(255,0,0); pl2.Brightness=isLarge and 1.0 or 0.6; pl2.Range=isLarge and 2.5 or 1.8; pl2.Parent=orb
        local drip=Instance.new("ParticleEmitter")
        drip.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(60,0,0))}
        drip.LightEmission=1; drip.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,0)}
        drip.Speed=NumberRange.new(0.3,1.8); drip.Rate=10; drip.Lifetime=NumberRange.new(0.3,0.7); drip.Parent=orb
        table.insert(allBraceletParts, {part=orb, baseAngle=ba, radius=OUTER_RADIUS, yOff=wristY, speed=2.2})
    end
    -- Orbs interiores: 6
    local INNER_COUNT=6; local INNER_RADIUS=0.30
    for i=1,INNER_COUNT do
        local ba=(i/INNER_COUNT)*math.pi*2+math.pi/INNER_COUNT
        local micro=Instance.new("Part"); micro.Name="BraceletOrb"
        micro.Size=Vector3.new(0.10,0.10,0.10); micro.Shape=Enum.PartType.Ball
        micro.BrickColor=BrickColor.new("Dark red"); micro.Material=Enum.Material.Neon
        micro.Transparency=0.1; micro.CanCollide=false; micro.CastShadow=false
        micro.CFrame=leftArm.CFrame*CFrame.new(INNER_RADIUS*math.cos(ba),wristY,INNER_RADIUS*math.sin(ba)); micro.Parent=leftArm
        table.insert(allBraceletParts, {part=micro, baseAngle=ba, radius=INNER_RADIUS, yOff=wristY, speed=-1.8})
    end

    playerBraceletParts[player] = allBraceletParts
    playerLeftArm[player]       = leftArm

    -- Loop de rotación
    local rotConn
    rotConn = RunService.Heartbeat:Connect(function()
        if not leftArm or not leftArm.Parent then rotConn:Disconnect(); return end
        local t = tick()
        for _, data in ipairs(allBraceletParts) do
            local p = data.part
            if p and p.Parent then
                local angle = data.baseAngle + t * data.speed
                p.CFrame = leftArm.CFrame * CFrame.new(data.radius*math.cos(angle), data.yOff, data.radius*math.sin(angle))
            end
        end
    end)

    -- Luz de aura
    if not leftArm:FindFirstChildOfClass("PointLight") then
        local gl = Instance.new("PointLight")
        gl.Name="BraceletGlow"; gl.Color=Color3.fromRGB(255,0,0); gl.Brightness=1.2; gl.Range=3; gl.Parent=leftArm
    end
end

local function collapseBraceletRing(player, duration)
    local parts = playerBraceletParts[player]; if not parts then return end
    local ringParts = {}
    for _, data in ipairs(parts) do
        if data.part and data.part.Parent and data.part.Name=="BloodBracelet" then
            table.insert(ringParts, data.part)
        end
    end
    if #ringParts==0 then return end
    local step = duration / #ringParts
    for i, part in ipairs(ringParts) do
        task.delay((i-1)*step, function()
            if part and part.Parent then
                if not part:GetAttribute("OrigSizeX") then part:SetAttribute("OrigSizeX", part.Size.X) end
                TweenService:Create(part,TweenInfo.new(step*0.8,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=Vector3.new(0.01,0.01,0.01),Transparency=1}):Play()
            end
        end)
    end
end

local function restoreBraceletRing(player, fadeInTime)
    fadeInTime = fadeInTime or 0.3
    local parts = playerBraceletParts[player]; if not parts then return end
    for _, data in ipairs(parts) do
        local part = data.part
        if part and part.Parent and part.Name=="BloodBracelet" then
            local origSize = part:GetAttribute("OrigSizeX") or 0.13
            TweenService:Create(part,TweenInfo.new(fadeInTime,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(origSize,origSize,origSize),Transparency=0}):Play()
        end
    end
end

-- Equipar al spawn
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.delay(1, function() equipBloodBracelet(player) end)
    end)
end)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        task.delay(0.5, function() equipBloodBracelet(player) end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  PODER 1: BOLA DE SANGRE
-- ═══════════════════════════════════════════════════════════════
RE_BloodBall.OnServerEvent:Connect(function(player)
    if isOnCooldown(player, "BloodBall") then return end
    if checkStunned(player) then return end
    local char = player.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    RE_Anim:FireAllClients(player, "BloodBall_Pose")
    RE_Effect:FireAllClients("BloodBall_Cast", player)
    collapseBraceletRing(player, 0.5)

    task.delay(0.62, function()
        if not char or not hrp or not hrp.Parent then return end
        local leftArm = char:FindFirstChild("Left Arm")
            or char:FindFirstChild("LeftHand")
            or char:FindFirstChild("LeftLowerArm")
        local spawnPos = leftArm
            and (leftArm.Position + Vector3.new(0,-0.7,0))
            or  (hrp.Position + hrp.CFrame.LookVector * 2 + Vector3.new(0,0.5,0))

        -- Flash de luz en la manilla
        if leftArm then
            for _, v in ipairs(leftArm:GetChildren()) do
                local pl = v:FindFirstChildOfClass("PointLight")
                if pl then
                    local ob = pl.Brightness; pl.Brightness = ob*5
                    task.delay(0.12, function() if pl and pl.Parent then pl.Brightness=ob end end)
                end
            end
        end

        -- Crear bola
        local ball = Instance.new("Part")
        ball.Name="BloodBall"; ball.Size=Vector3.new(0.3,0.3,0.3); ball.Shape=Enum.PartType.Ball
        ball.Position=spawnPos; ball.Color=Color3.fromRGB(220,0,0); ball.Material=Enum.Material.Neon
        ball.Anchored=false; ball.CanCollide=false; ball.CastShadow=false; ball.Parent=Workspace

        TweenService:Create(ball,TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(3,3,3)}):Play()

        local pl=Instance.new("PointLight"); pl.Color=Color3.fromRGB(255,20,0); pl.Brightness=14; pl.Range=28; pl.Parent=ball

        local trail=Instance.new("ParticleEmitter")
        trail.Texture="rbxassetid://"..VFX.BB_Fireball
        trail.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,40,0)),ColorSequenceKeypoint.new(0.4,Color3.fromRGB(200,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(40,0,0))}
        trail.LightEmission=1; trail.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.9),NumberSequenceKeypoint.new(1,0)}
        trail.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}
        trail.Speed=NumberRange.new(0,3); trail.Rate=200; trail.Lifetime=NumberRange.new(0.4,0.9)
        trail.RotSpeed=NumberRange.new(-360,360); trail.VelocityInheritance=0.3; trail.Parent=ball

        local spark=Instance.new("ParticleEmitter")
        spark.Texture="rbxassetid://"..VFX.BB_EnergyBall
        spark.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,100,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(200,0,0))}
        spark.LightEmission=1; spark.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(1,0)}
        spark.Speed=NumberRange.new(4,10); spark.Rate=80; spark.Lifetime=NumberRange.new(0.2,0.5)
        spark.SpreadAngle=Vector2.new(25,25); spark.Parent=ball

        -- Lanzar
        local bv=Instance.new("BodyVelocity"); bv.Velocity=hrp.CFrame.LookVector*90
        bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=ball

        -- Detectar impacto
        local startTime=tick(); local hitConn
        hitConn=ball.Touched:Connect(function(hit)
            if tick()-startTime < 0.1 then return end
            if hit:IsDescendantOf(char) then return end
            local hp=Players:GetPlayerFromCharacter(hit.Parent)
            if hp==player then return end
            if not hitConn then return end
            hitConn:Disconnect(); hitConn=nil

            local explosionPos=ball.Position
            ball:Destroy()

            -- VFX de impacto
            local impactPart=Instance.new("Part"); impactPart.Size=Vector3.new(0.3,0.3,0.3)
            impactPart.Position=explosionPos; impactPart.Anchored=true; impactPart.CanCollide=false
            impactPart.Transparency=1; impactPart.CastShadow=false; impactPart.Parent=Workspace
            local impactPE=Instance.new("ParticleEmitter")
            impactPE.Texture="rbxassetid://"..VFX.BB_ImpactExplosion
            impactPE.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,60,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(80,0,0))}
            impactPE.LightEmission=1; impactPE.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,2.0),NumberSequenceKeypoint.new(1,0)}
            impactPE.Speed=NumberRange.new(10,28); impactPE.Rate=0; impactPE.Lifetime=NumberRange.new(0.5,1.0)
            impactPE.SpreadAngle=Vector2.new(90,90); impactPE.RotSpeed=NumberRange.new(-360,360); impactPE.Parent=impactPart
            impactPE:Emit(70); Debris:AddItem(impactPart,2)

            RE_Effect:FireAllClients("BloodBall_Explode", explosionPos)

            -- Daño en área
            for _, p in ipairs(Players:GetPlayers()) do
                if p~=player and p.Character then
                    local eh=p.Character:FindFirstChild("HumanoidRootPart")
                    if eh and (eh.Position-explosionPos).Magnitude<10 then
                        dealDamage(p,35)
                        applyKnockback(p,(eh.Position-explosionPos).Unit+Vector3.new(0,0.5,0),60)
                        RE_Stun:FireClient(p,1.2)
                    end
                end
            end

            -- Lluvia de sangre
            for i=1,40 do
                local angle=math.random()*math.pi*2
                local elevation=math.random()*math.pi-math.pi/2
                local radius=math.random(2,14)
                local spSize=math.random()*0.8+0.2
                local sp=spawnBloodParticle(
                    explosionPos+Vector3.new(0,math.random(-1,1),0),
                    BrickColor.new(i%3==0 and "Crimson" or "Bright red"), spSize, 2.2
                )
                local flyDir=Vector3.new(
                    math.cos(angle)*math.cos(elevation)*radius,
                    math.abs(math.sin(elevation))*radius*1.5+math.random(1,5),
                    math.sin(angle)*math.cos(elevation)*radius
                )
                TweenService:Create(sp,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                    Position=explosionPos+flyDir, Size=Vector3.new(0.08,0.08,0.08), Transparency=1
                }):Play()
            end

            -- Manchas de sangre en suelo
            for i=1,8 do
                local angle=(i/8)*math.pi*2; local r=math.random(1,6)
                local stain=Instance.new("Part")
                stain.Size=Vector3.new(math.random(1,3),0.05,math.random(1,3))
                stain.Position=explosionPos+Vector3.new(math.cos(angle)*r,-1,math.sin(angle)*r)
                stain.BrickColor=BrickColor.new("Maroon"); stain.Material=Enum.Material.SmoothPlastic
                stain.Anchored=true; stain.CanCollide=false; stain.CastShadow=false; stain.Parent=Workspace
                TweenService:Create(stain,TweenInfo.new(3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1}):Play()
                Debris:AddItem(stain,3.5)
            end
        end)

        Debris:AddItem(ball, 6)
        restoreBraceletRing(player, 0.35)
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  PODER 2: GLÓBULOS / ESPINAS
-- ═══════════════════════════════════════════════════════════════
RE_BloodCorpuscle.OnServerEvent:Connect(function(player)
    if isOnCooldown(player, "BloodCorpuscle") then return end
    if checkStunned(player) then return end
    local char = player.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local origin = hrp.Position

    RE_Anim:FireAllClients(player, "BloodCorpuscle_Pose")
    RE_Effect:FireAllClients("BloodCorpuscle_Start", player)

    local globulos    = {}
    local RING_COUNT  = 12
    local INNER_R     = 4
    local OUTER_R     = 8

    for ring=1,2 do
        local r = (ring==1) and INNER_R or OUTER_R
        for i=1,RING_COUNT do
            local angle=(i/RING_COUNT)*math.pi*2
            local offset=Vector3.new(math.cos(angle)*r,-2,math.sin(angle)*r)
            local spawnPos=origin+offset

            local glob=Instance.new("Part"); glob.Name="BloodGlob"; glob.Size=Vector3.new(0.6,0.6,0.6)
            glob.Shape=Enum.PartType.Ball; glob.Position=spawnPos; glob.Color=Color3.fromRGB(220,0,0)
            glob.Material=Enum.Material.Neon; glob.Anchored=true; glob.CanCollide=false; glob.CastShadow=false; glob.Parent=Workspace

            local risingPE=Instance.new("ParticleEmitter"); risingPE.Texture="rbxassetid://"..VFX.GL_SummonRising
            risingPE.Color=ColorSequence.new(Color3.fromRGB(180,0,0)); risingPE.LightEmission=0.8
            risingPE.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.35),NumberSequenceKeypoint.new(1,0)}
            risingPE.Speed=NumberRange.new(2,6); risingPE.Rate=20; risingPE.Lifetime=NumberRange.new(0.3,0.7); risingPE.Parent=glob

            local spikePE=Instance.new("ParticleEmitter"); spikePE.Texture="rbxassetid://"..VFX.GL_BloodSpike
            spikePE.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(80,0,0))}
            spikePE.LightEmission=0.9; spikePE.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0)}
            spikePE.Speed=NumberRange.new(1,3); spikePE.Rate=12; spikePE.Lifetime=NumberRange.new(0.2,0.5)
            spikePE.SpreadAngle=Vector2.new(30,30); spikePE.Parent=glob

            table.insert(globulos, {part=glob, angle=angle, ring=r})

            task.delay((ring-1)*0.3+(i/RING_COUNT)*0.4, function()
                if not glob or not glob.Parent then return end
                TweenService:Create(glob,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
                    Position=spawnPos+Vector3.new(0,2.5,0), Size=Vector3.new(0.8,0.8,0.8)
                }):Play()
            end)
        end
    end

    task.delay(1.2, function()
        RE_Effect:FireAllClients("BloodCorpuscle_Transform", player)

        -- Earth shatter VFX
        local shatterPart=Instance.new("Part"); shatterPart.Size=Vector3.new(0.3,0.3,0.3)
        shatterPart.Position=origin+Vector3.new(0,0.5,0); shatterPart.Anchored=true
        shatterPart.CanCollide=false; shatterPart.Transparency=1; shatterPart.CastShadow=false; shatterPart.Parent=Workspace
        local shatterPE=Instance.new("ParticleEmitter"); shatterPE.Texture="rbxassetid://"..VFX.GL_EarthShatter
        shatterPE.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(200,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(60,0,0))}
        shatterPE.LightEmission=0.8; shatterPE.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,1.2),NumberSequenceKeypoint.new(1,0)}
        shatterPE.Speed=NumberRange.new(8,18); shatterPE.Rate=0; shatterPE.Lifetime=NumberRange.new(0.6,1.2)
        shatterPE.SpreadAngle=Vector2.new(60,60); shatterPE.RotSpeed=NumberRange.new(-180,180); shatterPE.Parent=shatterPart
        shatterPE:Emit(40); Debris:AddItem(shatterPart,2)

        for _, data in ipairs(globulos) do
            local part=data.part
            if part and part.Parent then
                part.Color=Color3.fromRGB(100,0,0)
                TweenService:Create(part,TweenInfo.new(0.8,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{
                    Size=Vector3.new(0.4,3.5,0.4), Color=Color3.fromRGB(80,0,0)
                }):Play()
                task.delay(0.3,function()
                    if part and part.Parent then
                        part.Material=Enum.Material.Glass
                        local gpe=Instance.new("ParticleEmitter"); gpe.Texture="rbxassetid://"..VFX.GL_GroundSpike
                        gpe.Color=ColorSequence.new(Color3.fromRGB(160,0,0)); gpe.LightEmission=0.7
                        gpe.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(1,0)}
                        gpe.Speed=NumberRange.new(2,5); gpe.Rate=8; gpe.Lifetime=NumberRange.new(0.3,0.6); gpe.Parent=part
                    end
                end)
            end
        end
    end)

    task.delay(1.9, function() collapseBraceletRing(player, 0.5) end)

    task.delay(2.5, function()
        local target=getNearestEnemy(player,35)
        for i, data in ipairs(globulos) do
            local part=data.part
            if part and part.Parent then
                task.delay((i/#globulos)*0.6, function()
                    if not part or not part.Parent then return end
                    part.Anchored=false
                    local targetPos=Vector3.new(origin.X,origin.Y+2,origin.Z)
                    if target and target.Character then
                        local th=target.Character:FindFirstChild("HumanoidRootPart")
                        if th then targetPos=th.Position+Vector3.new(math.random(-2,2),math.random(-1,2),math.random(-2,2)) end
                    end
                    local bv=Instance.new("BodyVelocity"); bv.Velocity=(targetPos-part.Position).Unit*65
                    bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=part
                    local hitConn; hitConn=part.Touched:Connect(function(hit)
                        local hp=Players:GetPlayerFromCharacter(hit.Parent)
                        if hp and hp~=player then
                            hitConn:Disconnect(); dealDamage(hp,8)
                            RE_Effect:FireAllClients("Spine_Hit", part.Position)
                        end
                        if hit.Parent~=char then part:Destroy() end
                    end)
                    Debris:AddItem(part,3)
                end)
            end
        end
        if target then
            task.delay(0.8,function()
                dealDamage(target,45)
                if target.Character then
                    local th=target.Character:FindFirstChild("HumanoidRootPart")
                    if th then applyKnockback(target,Vector3.new(0,1,0),30) end
                end
            end)
        end
        restoreBraceletRing(player, 0.35)
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  PODER 3: LÁTIGO DE SANGRE
-- ═══════════════════════════════════════════════════════════════
RE_BloodWhip.OnServerEvent:Connect(function(player)
    if isOnCooldown(player, "BloodWhip") then return end
    if checkStunned(player) then return end
    local char=player.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local target=getNearestEnemy(player,40); if not target then return end
    local targetChar=target.Character; if not targetChar then return end
    local targetHrp=targetChar:FindFirstChild("HumanoidRootPart"); if not targetHrp then return end

    whipActive[player]=target
    RE_Anim:FireAllClients(player,"BloodWhip_Pose")
    RE_Effect:FireAllClients("BloodWhip_Cast",player,target)
    collapseBraceletRing(player,0.4)
    stunned[target]=tick()+8; RE_Stun:FireClient(target,8)

    local WHIP_SEGS=14; local FORM_TIME=0.55; local whipDuration=8; local startTime=tick()

    local segParts={}; local segAtts={}
    for i=0,WHIP_SEGS do
        local sp=Instance.new("Part"); sp.Size=Vector3.new(0.05,0.05,0.05)
        sp.Anchored=true; sp.CanCollide=false; sp.CastShadow=false; sp.Transparency=1; sp.Parent=Workspace
        local sa=Instance.new("Attachment",sp)
        segParts[i]=sp; segAtts[i]=sa
    end

    local beams={}
    for i=0,WHIP_SEGS-1 do
        local tProg=i/WHIP_SEGS
        local b=Instance.new("Beam")
        b.Attachment0=segAtts[i]; b.Attachment1=segAtts[i+1]
        b.Width0=0.32*(1-tProg*0.70); b.Width1=0.32*(1-(tProg+1/WHIP_SEGS)*0.70)
        b.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,30,0)),
            ColorSequenceKeypoint.new(0.35,Color3.fromRGB(200,0,0)),
            ColorSequenceKeypoint.new(0.70,Color3.fromRGB(120,0,0)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(50,0,0)),
        }
        b.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.0),NumberSequenceKeypoint.new(0.8,0.1),NumberSequenceKeypoint.new(1,0.55)}
        b.LightEmission=0.9; b.LightInfluence=0.1; b.FaceCamera=true; b.Segments=6
        b.CurveSize0=0; b.CurveSize1=0
        b.Texture="rbxassetid://"..VFX.WH_EnergyChain
        b.TextureLength=1.2; b.TextureMode=Enum.TextureMode.Wrap
        b.Parent=segParts[i]; beams[i]=b
    end

    local handLight=Instance.new("PointLight"); handLight.Color=Color3.fromRGB(255,30,0)
    handLight.Brightness=6; handLight.Range=12; handLight.Parent=segParts[0]

    local handDrip=Instance.new("ParticleEmitter"); handDrip.Texture="rbxassetid://"..VFX.WH_BeamTrail
    handDrip.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,10,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(60,0,0))}
    handDrip.LightEmission=0.9; handDrip.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.18),NumberSequenceKeypoint.new(1,0)}
    handDrip.Speed=NumberRange.new(1,4); handDrip.Rate=35; handDrip.Lifetime=NumberRange.new(0.2,0.45)
    handDrip.SpreadAngle=Vector2.new(20,20); handDrip.Parent=segParts[0]

    local tipSpark=Instance.new("ParticleEmitter")
    tipSpark.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,60,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(180,0,0))}
    tipSpark.LightEmission=1; tipSpark.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.22),NumberSequenceKeypoint.new(1,0)}
    tipSpark.Speed=NumberRange.new(2,5); tipSpark.Rate=0; tipSpark.Lifetime=NumberRange.new(0.15,0.35)
    tipSpark.SpreadAngle=Vector2.new(60,60); tipSpark.Parent=segParts[WHIP_SEGS]

    local function destroyWhip()
        for i=0,WHIP_SEGS do
            if segParts[i] and segParts[i].Parent then segParts[i]:Destroy() end
        end
    end

    local whipConn
    whipConn=RunService.Heartbeat:Connect(function()
        local elapsed=tick()-startTime
        if elapsed>whipDuration then
            whipConn:Disconnect(); destroyWhip()
            whipActive[player]=nil; stunned[target]=nil
            restoreBraceletRing(player,0.4)
            if not souls1000Unlocked[player] then
                souls1000Unlocked[player]=true; RE_Unlock1000:FireClient(player)
            end
            return
        end
        local ph=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local th=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not ph or not th then
            whipConn:Disconnect(); destroyWhip()
            whipActive[player]=nil; restoreBraceletRing(player,0.4)
            return
        end
        local lArm=player.Character:FindFirstChild("LeftHand") or player.Character:FindFirstChild("Left Arm")
        local handPos
        if lArm then
            handPos=lArm.CFrame:PointToWorldSpace(Vector3.new(0,(lArm.Name=="Left Arm") and -0.9 or -0.4,0))
        else
            handPos=ph.CFrame:PointToWorldSpace(Vector3.new(-1.5,-0.5,0))
        end
        local targetPos=th.Position+Vector3.new(0,0.5,0)
        local whipVec=targetPos-handPos; local dist=whipVec.Magnitude; local dir=whipVec.Unit
        local upRef=math.abs(dir.Y)>0.85 and Vector3.new(1,0,0) or Vector3.new(0,1,0)
        local sideDir=dir:Cross(upRef).Unit
        local waveSpeed=5.5; local waveFreq=1.8; local maxAmp=1.7; local t_now=tick()
        local extFactor=math.min(elapsed/FORM_TIME,1)
        if extFactor>=1 and tipSpark.Rate==0 then tipSpark.Rate=30 end
        for i=0,WHIP_SEGS do
            local prog=i/WHIP_SEGS
            if prog>extFactor then
                segParts[i].CFrame=CFrame.new(handPos)
            else
                local basePos=handPos+dir*(dist*prog)
                local amp=maxAmp*math.pow(1-prog,1.15)*extFactor
                local phase=prog*waveFreq*math.pi*2-t_now*waveSpeed
                local lateralOff=math.sin(phase)*amp
                local vertOff=math.sin(phase*0.65+math.pi*0.5)*amp*0.28
                segParts[i].CFrame=CFrame.new(basePos+sideDir*lateralOff+Vector3.new(0,vertOff,0))
            end
        end
        if extFactor>=1 and math.floor(elapsed*2)%2==0 then dealDamage(target,1) end
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  PODER 4: 1000 ALMAS
-- ═══════════════════════════════════════════════════════════════
RE_Souls1000.OnServerEvent:Connect(function(player)
    if not souls1000Unlocked[player] then return end
    if isOnCooldown(player,"Souls1000") then return end
    local char=player.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local target=getNearestEnemy(player,50)

    RE_Anim:FireAllClients(player,"Souls1000_Pose")
    RE_Effect:FireAllClients("Souls1000_Start",player)

    local allCrystals={}
    for wave=1,8 do
        task.delay(wave*0.2,function()
            local waveRadius=3+wave*2.5; local count=8+wave*3
            for i=1,count do
                local angle=(i/count)*math.pi*2+wave*0.3
                local offset=Vector3.new(
                    math.cos(angle)*waveRadius+math.random(-2,2), -3,
                    math.sin(angle)*waveRadius+math.random(-2,2)
                )
                local basePos=hrp.Position+offset
                local blood=Instance.new("Part"); blood.Name="SoulBlood"; blood.Size=Vector3.new(0.5,0.5,0.5)
                blood.Shape=Enum.PartType.Ball; blood.Position=basePos; blood.Color=Color3.fromRGB(200,0,0)
                blood.Material=Enum.Material.Neon; blood.Anchored=true; blood.CanCollide=false; blood.CastShadow=false; blood.Parent=Workspace
                local emit=Instance.new("ParticleEmitter")
                emit.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(200,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,0,0))}
                emit.LightEmission=0.9; emit.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(1,0)}
                emit.Speed=NumberRange.new(3,8); emit.Rate=60; emit.Lifetime=NumberRange.new(0.5,1); emit.Parent=blood
                local pl=Instance.new("PointLight"); pl.Color=Color3.fromRGB(200,0,0); pl.Brightness=3; pl.Range=6; pl.Parent=blood
                TweenService:Create(blood,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
                    Position=basePos+Vector3.new(0,4+math.random()*3,0), Size=Vector3.new(0.8,0.8,0.8)
                }):Play()
                table.insert(allCrystals,blood)
            end
        end)
    end

    task.delay(2.2,function()
        RE_Effect:FireAllClients("Souls1000_CrystalForm",player)
        for i,part in ipairs(allCrystals) do
            if part and part.Parent then
                task.delay(i*0.015,function()
                    if not part or not part.Parent then return end
                    TweenService:Create(part,TweenInfo.new(0.5,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{
                        Size=Vector3.new(0.6,2.0,0.6), Color=Color3.fromRGB(180,0,0)
                    }):Play()
                    task.delay(0.25,function()
                        if part and part.Parent then
                            part.Material=Enum.Material.Glass; part.BrickColor=BrickColor.new("Crimson")
                        end
                    end)
                end)
            end
        end
    end)

    task.delay(2.9,function() collapseBraceletRing(player,0.5) end)

    task.delay(3.5,function()
        local targetHrp=target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        RE_Effect:FireAllClients("Souls1000_Launch",player,target)
        for i,crystal in ipairs(allCrystals) do
            if crystal and crystal.Parent then
                task.delay(i*0.02,function()
                    if not crystal or not crystal.Parent then return end
                    crystal.Anchored=false; crystal.CanCollide=true
                    local dest=targetHrp
                        and targetHrp.Position+Vector3.new(math.random(-4,4),math.random(-2,3),math.random(-4,4))
                        or  hrp.Position+hrp.CFrame.LookVector*30
                    local bv=Instance.new("BodyVelocity")
                    local dir=(dest-crystal.Position).Unit
                    bv.Velocity=dir*75+Vector3.new(0,15,0); bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=crystal
                    local hitConn; hitConn=crystal.Touched:Connect(function(hit)
                        local hp=Players:GetPlayerFromCharacter(hit.Parent)
                        if hp and hp~=player then
                            hitConn:Disconnect(); dealDamage(hp,12)
                            RE_Effect:FireAllClients("Crystal_Hit",crystal.Position)
                        end
                        task.delay(0.05,function() if crystal and crystal.Parent then crystal:Destroy() end end)
                    end)
                    Debris:AddItem(crystal,5)
                end)
            end
        end
        if target then
            task.delay(0.5,function()
                local th=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if th then
                    dealDamage(target,100)
                    applyKnockback(target,(th.Position-hrp.Position).Unit+Vector3.new(0,0.4,0),75)
                    RE_Effect:FireAllClients("Souls1000_FinalBlow",th.Position)
                    RE_Stun:FireClient(target,3)
                end
            end)
        end
        task.delay(4,function() souls1000Unlocked[player]=nil end)
        restoreBraceletRing(player,0.4)
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  PODER RAYO 1: RAYO DEVASTADOR — bala eléctrica supersónica
-- ═══════════════════════════════════════════════════════════════
RE_LightningBolt.OnServerEvent:Connect(function(player)
    if isOnCooldown(player,"LightningBolt") then return end
    if checkStunned(player) then return end
    local char=player.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    RE_Anim:FireAllClients(player,"LightningBolt_Pose")
    RE_Effect:FireAllClients("LightningBolt_Cast",player)

    -- Breve carga visual en la mano
    local rArm=char:FindFirstChild("Right Arm") or char:FindFirstChild("RightLowerArm") or char:FindFirstChild("RightHand")
    if rArm then
        local chargePart=Instance.new("Part"); chargePart.Size=Vector3.new(0.4,0.4,0.4)
        chargePart.CFrame=rArm.CFrame; chargePart.Anchored=true; chargePart.CanCollide=false
        chargePart.Color=Color3.fromRGB(200,240,255); chargePart.Material=Enum.Material.Neon
        chargePart.CastShadow=false; chargePart.Parent=Workspace
        local cpl=Instance.new("PointLight"); cpl.Color=Color3.fromRGB(100,200,255); cpl.Brightness=20; cpl.Range=30; cpl.Parent=chargePart
        local cpe=Instance.new("ParticleEmitter")
        cpe.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(80,180,255))}
        cpe.LightEmission=1; cpe.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)}
        cpe.Speed=NumberRange.new(3,10); cpe.Rate=100; cpe.Lifetime=NumberRange.new(0.1,0.3)
        cpe.SpreadAngle=Vector2.new(30,30); cpe.RotSpeed=NumberRange.new(-360,360); cpe.Parent=chargePart
        -- Seguir el brazo
        local fc; fc=RunService.Heartbeat:Connect(function()
            if chargePart and chargePart.Parent and rArm and rArm.Parent then
                chargePart.CFrame=rArm.CFrame
            else fc:Disconnect() end
        end)
        task.delay(0.20,function() fc:Disconnect(); if chargePart and chargePart.Parent then chargePart:Destroy() end end)
    end

    task.delay(0.22,function()
        if not char or not hrp or not hrp.Parent then return end
        local spawnPos=hrp.Position+hrp.CFrame.LookVector*2+Vector3.new(0,0.5,0)

        -- Proyectil principal: esfera eléctrica
        local bolt=Instance.new("Part"); bolt.Name="LightningBolt"; bolt.Size=Vector3.new(0.6,0.6,0.6)
        bolt.Shape=Enum.PartType.Ball; bolt.Position=spawnPos
        bolt.Color=Color3.fromRGB(180,240,255); bolt.Material=Enum.Material.Neon
        bolt.Anchored=false; bolt.CanCollide=false; bolt.CastShadow=false; bolt.Parent=Workspace

        TweenService:Create(bolt,TweenInfo.new(0.08,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(2.2,2.2,2.2)}):Play()

        local pl=Instance.new("PointLight"); pl.Color=Color3.fromRGB(150,220,255); pl.Brightness=20; pl.Range=35; pl.Parent=bolt

        -- Estela eléctrica densa
        local trail=Instance.new("ParticleEmitter")
        trail.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(0.3,Color3.fromRGB(150,230,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(30,80,200))}
        trail.LightEmission=1; trail.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(1,0)}
        trail.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.0),NumberSequenceKeypoint.new(1,1)}
        trail.Speed=NumberRange.new(0,4); trail.Rate=300; trail.Lifetime=NumberRange.new(0.12,0.35)
        trail.RotSpeed=NumberRange.new(-720,720); trail.VelocityInheritance=0.2; trail.Parent=bolt

        -- Arcos laterales de rayo zigzag cada frame
        local zapConn; local lastZapPos=spawnPos
        zapConn=RunService.Heartbeat:Connect(function()
            if not bolt or not bolt.Parent then zapConn:Disconnect(); return end
            local dist=(bolt.Position-lastZapPos).Magnitude
            if dist>2.5 then
                -- Dibujar mini-rayo entre la última posición y la actual
                local midOff=bolt.Position+Vector3.new((math.random()-0.5)*1.5,(math.random()-0.5)*1.5,(math.random()-0.5)*1.5)
                makeZapSegment(lastZapPos,midOff,Color3.fromRGB(200,255,255),0.08,0.12)
                makeZapSegment(midOff,bolt.Position,Color3.fromRGB(255,255,255),0.08,0.12)
                lastZapPos=bolt.Position
            end
        end)

        -- Velocidad extrema (140 studs/s — más rápido que la bola de sangre)
        local bv=Instance.new("BodyVelocity"); bv.Velocity=hrp.CFrame.LookVector*140
        bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=bolt

        local hitDone=false; local startTime=tick(); local hitConn
        hitConn=bolt.Touched:Connect(function(hit)
            if hitDone then return end
            if tick()-startTime<0.08 then return end
            if hit:IsDescendantOf(char) then return end
            local hp=Players:GetPlayerFromCharacter(hit.Parent)
            if hp==player then return end
            hitDone=true; if hitConn then hitConn:Disconnect(); hitConn=nil end
            zapConn:Disconnect()

            local hitPos=bolt.Position
            bolt:Destroy()

            RE_Effect:FireAllClients("LightningBolt_Hit",hitPos)

            -- Ondas de choque eléctricas concéntricas
            for ring=1,6 do
                task.delay(ring*0.04,function()
                    local w=Instance.new("Part"); w.Shape=Enum.PartType.Cylinder
                    w.Size=Vector3.new(0.08,ring*0.8,ring*0.8)
                    w.CFrame=CFrame.new(hitPos)*CFrame.Angles(0,0,math.pi/2)
                    w.Color=ring%2==0 and Color3.fromRGB(255,255,255) or Color3.fromRGB(80,200,255)
                    w.Material=Enum.Material.Neon; w.Anchored=true; w.CanCollide=false; w.CastShadow=false; w.Transparency=0.2; w.Parent=Workspace
                    local wpl=Instance.new("PointLight"); wpl.Color=Color3.fromRGB(100,200,255); wpl.Brightness=10; wpl.Range=20; wpl.Parent=w
                    TweenService:Create(w,TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                        Size=Vector3.new(0.03,22*ring,22*ring), Transparency=1
                    }):Play()
                    Debris:AddItem(w,0.7)
                end)
            end

            -- Rayos zigzag desde el punto de impacto hacia afuera (AAAA)
            for i=1,8 do
                local angle=(i/8)*math.pi*2
                local endP=hitPos+Vector3.new(math.cos(angle)*12,(math.random()-0.5)*6,math.sin(angle)*12)
                task.delay(math.random()*0.1,function()
                    drawLightningBetween(hitPos,endP,Color3.fromRGB(180,240,255),10,0.10,0.22,2.5)
                end)
            end

            -- Luz explosiva
            local lightPart=Instance.new("Part"); lightPart.Size=Vector3.new(0.1,0.1,0.1)
            lightPart.Position=hitPos; lightPart.Anchored=true; lightPart.CanCollide=false
            lightPart.Transparency=1; lightPart.CastShadow=false; lightPart.Parent=Workspace
            local bigLight=Instance.new("PointLight"); bigLight.Color=Color3.fromRGB(200,240,255)
            bigLight.Brightness=35; bigLight.Range=50; bigLight.Parent=lightPart
            TweenService:Create(bigLight,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Brightness=0}):Play()
            Debris:AddItem(lightPart,0.6)

            -- Daño en área + electrocución
            for _, p in ipairs(Players:GetPlayers()) do
                if p~=player and p.Character then
                    local eh=p.Character:FindFirstChild("HumanoidRootPart")
                    if eh then
                        local dist2=(eh.Position-hitPos).Magnitude
                        if dist2<8 then
                            dealDamage(p,45); applyKnockback(p,(eh.Position-hitPos).Unit+Vector3.new(0,0.8,0),80)
                            RE_Stun:FireClient(p,0.8)
                            stunned[p]=tick()+0.8
                        elseif dist2<16 then
                            -- Electrocución por salpicadura
                            dealDamage(p,15)
                            local chainEnd=eh.Position+Vector3.new((math.random()-0.5)*4,0,(math.random()-0.5)*4)
                            drawLightningBetween(hitPos,chainEnd,Color3.fromRGB(100,200,255),6,0.08,0.20,1.5)
                        end
                    end
                end
            end
        end)

        Debris:AddItem(bolt,5)
        task.delay(5,function() zapConn:Disconnect() end)
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  PODER RAYO 2: CADENA DE TRUENO — cadena eléctrica en área
-- ═══════════════════════════════════════════════════════════════
RE_ThunderChain.OnServerEvent:Connect(function(player)
    if isOnCooldown(player,"ThunderChain") then return end
    if checkStunned(player) then return end
    local char=player.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    RE_Anim:FireAllClients(player,"ThunderChain_Pose")
    RE_Effect:FireAllClients("ThunderChain_Cast",player)

    -- Crear 8 orbs eléctricos que orbitan al caster antes de ser lanzados
    local orbs={}
    local ORBIT_RADIUS=3.5; local ORBIT_COUNT=8

    for i=1,ORBIT_COUNT do
        local baseAngle=(i/ORBIT_COUNT)*math.pi*2
        local orb=Instance.new("Part"); orb.Name="ThunderOrb"
        orb.Size=Vector3.new(0.6,0.6,0.6); orb.Shape=Enum.PartType.Ball
        orb.Color=Color3.fromRGB(180,240,255); orb.Material=Enum.Material.Neon
        orb.Anchored=true; orb.CanCollide=false; orb.CastShadow=false; orb.Parent=Workspace
        orb.CFrame=hrp.CFrame*CFrame.new(ORBIT_RADIUS*math.cos(baseAngle),0.5,ORBIT_RADIUS*math.sin(baseAngle))

        local pl=Instance.new("PointLight"); pl.Color=Color3.fromRGB(100,200,255); pl.Brightness=8; pl.Range=12; pl.Parent=orb

        local pe=Instance.new("ParticleEmitter")
        pe.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(50,150,255))}
        pe.LightEmission=1; pe.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.22),NumberSequenceKeypoint.new(1,0)}
        pe.Speed=NumberRange.new(2,6); pe.Rate=50; pe.Lifetime=NumberRange.new(0.1,0.3); pe.SpreadAngle=Vector2.new(60,60); pe.Parent=orb

        table.insert(orbs,{part=orb,baseAngle=baseAngle})
    end

    -- Conectar orbs con rayos entre ellos
    local zapTimer=0
    local orbitConn; local orbitStart=tick()

    orbitConn=RunService.Heartbeat:Connect(function(dt)
        zapTimer=zapTimer+dt
        local elapsed=tick()-orbitStart
        if elapsed>1.5 then orbitConn:Disconnect(); return end
        if not hrp or not hrp.Parent then orbitConn:Disconnect(); return end
        local t=tick()
        for idx, data in ipairs(orbs) do
            local p=data.part
            if p and p.Parent then
                local angle=data.baseAngle+t*3.5
                p.CFrame=hrp.CFrame*CFrame.new(ORBIT_RADIUS*math.cos(angle),0.5,ORBIT_RADIUS*math.sin(angle))
                -- Zap entre orbs adyacentes
                local next=orbs[idx%#orbs+1]
                if next and next.part and next.part.Parent and zapTimer>0.06 then
                    drawLightningBetween(p.Position,next.part.Position,Color3.fromRGB(120,220,255),4,0.06,0.08,0.8)
                end
            end
        end
        if zapTimer>0.06 then zapTimer=0 end
    end)

    -- Lanzar hacia enemigos tras 1.5s
    task.delay(1.5,function()
        local enemies=getEnemiesInRadius(player,40)

        for i, data in ipairs(orbs) do
            local part=data.part
            if part and part.Parent then
                task.delay((i-1)*0.12,function()
                    if not part or not part.Parent then return end
                    part.Anchored=false

                    -- Buscar un enemigo para cada orb
                    local target=enemies[((i-1)%#enemies)+1] if #enemies==0 then target=nil end
                    local dest
                    if target and target.Character then
                        local th=target.Character:FindFirstChild("HumanoidRootPart")
                        if th then dest=th.Position+Vector3.new(math.random(-1,1),0.5,math.random(-1,1)) end
                    end
                    if not dest then dest=hrp.Position+hrp.CFrame.LookVector*20+Vector3.new((math.random()-0.5)*10,0,(math.random()-0.5)*10) end

                    -- Zigzag: el orb viaja dejando rayo detrás
                    local prevPos=part.Position
                    local travelConn; local tStart=tick()
                    travelConn=RunService.Heartbeat:Connect(function()
                        if not part or not part.Parent then travelConn:Disconnect(); return end
                        local elapsed2=tick()-tStart
                        if elapsed2>1.2 then travelConn:Disconnect(); return end
                        local dist3=(part.Position-prevPos).Magnitude
                        if dist3>1.8 then
                            drawLightningBetween(prevPos,part.Position,Color3.fromRGB(150,230,255),4,0.07,0.15,1.2)
                            prevPos=part.Position
                        end
                    end)

                    local bv=Instance.new("BodyVelocity"); bv.Velocity=(dest-part.Position).Unit*80
                    bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=part

                    local hitConn2; hitConn2=part.Touched:Connect(function(hit)
                        local hp=Players:GetPlayerFromCharacter(hit.Parent)
                        if hp and hp~=player then
                            if hitConn2 then hitConn2:Disconnect(); hitConn2=nil end
                            travelConn:Disconnect()
                            dealDamage(hp,22); applyKnockback(hp,(hp.Character.HumanoidRootPart.Position-part.Position).Unit+Vector3.new(0,0.5,0),40)
                            RE_Stun:FireClient(hp,0.6); stunned[hp]=tick()+0.6
                            -- Cadena a enemigos cerca del impacto (chain lightning)
                            for _,np in ipairs(Players:GetPlayers()) do
                                if np~=player and np~=hp and np.Character then
                                    local neh=np.Character:FindFirstChild("HumanoidRootPart")
                                    if neh and (neh.Position-part.Position).Magnitude<12 then
                                        drawLightningBetween(part.Position,neh.Position,Color3.fromRGB(100,200,255),6,0.10,0.28,2.0)
                                        dealDamage(np,10)
                                    end
                                end
                            end
                            RE_Effect:FireAllClients("ThunderChain_Hit",part.Position)
                            part:Destroy()
                        elseif hit.Parent~=char then
                            travelConn:Disconnect()
                            RE_Effect:FireAllClients("ThunderChain_Hit",part.Position)
                            part:Destroy()
                        end
                    end)
                    Debris:AddItem(part,4)
                end)
            end
        end

        -- Desbloquear Descarga Suprema tras usar Cadena 3 veces (simplificado: tras usar Látigo + Cadena)
        if souls1000Unlocked[player] and not supremeUnlocked[player] then
            supremeUnlocked[player]=true; RE_UnlockSupreme:FireClient(player)
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  PODER RAYO 3: TORMENTA ELÉCTRICA — lluvia de rayos del cielo
-- ═══════════════════════════════════════════════════════════════
RE_ElectricStorm.OnServerEvent:Connect(function(player)
    if isOnCooldown(player,"ElectricStorm") then return end
    if checkStunned(player) then return end
    local char=player.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    RE_Anim:FireAllClients(player,"ElectricStorm_Pose")
    RE_Effect:FireAllClients("ElectricStorm_Cast",player)

    local STORM_RADIUS=20; local STORM_DURATION=6; local STRIKE_INTERVAL=0.45
    local stormStart=tick()

    -- Aura tormentosa alrededor del caster
    local stormAura=Instance.new("Part"); stormAura.Name="StormAura"
    stormAura.Size=Vector3.new(STORM_RADIUS*2,0.2,STORM_RADIUS*2); stormAura.Shape=Enum.PartType.Cylinder
    stormAura.CFrame=hrp.CFrame*CFrame.Angles(0,0,math.pi/2); stormAura.Color=Color3.fromRGB(60,120,200)
    stormAura.Material=Enum.Material.Neon; stormAura.Anchored=true; stormAura.CanCollide=false
    stormAura.CastShadow=false; stormAura.Transparency=0.55; stormAura.Parent=Workspace
    local auraLight=Instance.new("PointLight"); auraLight.Color=Color3.fromRGB(80,160,255)
    auraLight.Brightness=4; auraLight.Range=STORM_RADIUS*2; auraLight.Parent=stormAura

    -- Loop principal de la tormenta
    local stormConn
    stormConn=RunService.Heartbeat:Connect(function()
        local elapsed=tick()-stormStart
        if elapsed>STORM_DURATION then
            stormConn:Disconnect()
            if stormAura and stormAura.Parent then
                TweenService:Create(stormAura,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=1}):Play()
                Debris:AddItem(stormAura,0.6)
            end
            return
        end
        -- Seguir al caster
        if hrp and hrp.Parent then
            stormAura.CFrame=CFrame.new(hrp.Position.X,hrp.Position.Y-1,hrp.Position.Z)*CFrame.Angles(0,0,math.pi/2)
        end
        -- Pulso de aura
        local pulse=0.45+math.sin(elapsed*6)*0.15
        TweenService:Create(stormAura,TweenInfo.new(0.06),{Transparency=pulse}):Play()
    end)

    -- Generar rayos periódicamente
    local strikeConn
    local lastStrike=tick()
    strikeConn=RunService.Heartbeat:Connect(function()
        local elapsed=tick()-stormStart
        if elapsed>STORM_DURATION then strikeConn:Disconnect(); return end
        if tick()-lastStrike < STRIKE_INTERVAL then return end
        lastStrike=tick()
        if not hrp or not hrp.Parent then return end

        -- Posición aleatoria en el radio (apunta a enemigos si hay uno cerca)
        local strikePos
        local nearEnemy=getNearestEnemy(player,STORM_RADIUS)
        if nearEnemy and nearEnemy.Character then
            local eh=nearEnemy.Character:FindFirstChild("HumanoidRootPart")
            if eh then
                strikePos=eh.Position+Vector3.new(math.random(-3,3),0,math.random(-3,3))
            end
        end
        if not strikePos then
            local angle=math.random()*math.pi*2; local r=math.random(2,STORM_RADIUS)
            strikePos=Vector3.new(hrp.Position.X+math.cos(angle)*r,hrp.Position.Y,hrp.Position.Z+math.sin(angle)*r)
        end

        local skyPos=strikePos+Vector3.new(0,60,0)

        -- Rayo del cielo: grueso y brillante
        drawLightningBetween(skyPos,strikePos,Color3.fromRGB(220,255,255),14,0.35,0.30,4.5)
        -- Segunda pasada más fina
        task.delay(0.03,function()
            drawLightningBetween(skyPos,strikePos,Color3.fromRGB(255,255,255),6,0.16,0.18,3.5)
        end)
        -- Ramificaciones laterales
        for branch=1,4 do
            local branchAngle=math.random()*math.pi*2
            local branchEnd=strikePos+Vector3.new(math.cos(branchAngle)*6,(math.random()-0.5)*4,math.sin(branchAngle)*6)
            local branchMid=skyPos+Vector3.new((math.random()-0.5)*5,(math.random()-0.5)*10,(math.random()-0.5)*5)
            task.delay(math.random()*0.05,function()
                drawLightningBetween(branchMid,branchEnd,Color3.fromRGB(100,200,255),6,0.09,0.22,3.0)
            end)
        end

        -- Luz de impacto
        local strikePart=Instance.new("Part"); strikePart.Size=Vector3.new(0.1,0.1,0.1)
        strikePart.Position=strikePos; strikePart.Anchored=true; strikePart.CanCollide=false
        strikePart.Transparency=1; strikePart.CastShadow=false; strikePart.Parent=Workspace
        local strikeLight=Instance.new("PointLight"); strikeLight.Color=Color3.fromRGB(180,240,255)
        strikeLight.Brightness=25; strikeLight.Range=30; strikeLight.Parent=strikePart
        TweenService:Create(strikeLight,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Brightness=0,Range=0}):Play()
        Debris:AddItem(strikePart,0.4)

        RE_Effect:FireAllClients("ElectricStorm_Strike",strikePos)

        -- Daño a enemigos en radio del impacto
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local eh=p.Character:FindFirstChild("HumanoidRootPart")
                if eh and (eh.Position-strikePos).Magnitude<5 then
                    dealDamage(p,18); applyKnockback(p,Vector3.new(0,1,0)*0.7+(eh.Position-strikePos).Unit*0.3,35)
                    RE_Stun:FireClient(p,0.5); stunned[p]=tick()+0.5
                end
            end
        end

        -- Cráter eléctrico en el suelo
        local crater=Instance.new("Part")
        crater.Size=Vector3.new(math.random(2,5),0.08,math.random(2,5)); crater.Shape=Enum.PartType.Cylinder
        crater.CFrame=CFrame.new(strikePos.X,strikePos.Y-0.5,strikePos.Z)*CFrame.Angles(0,0,math.pi/2)
        crater.Color=Color3.fromRGB(80,160,220); crater.Material=Enum.Material.Neon
        crater.Anchored=true; crater.CanCollide=false; crater.CastShadow=false; crater.Transparency=0.3; crater.Parent=Workspace
        TweenService:Create(crater,TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1}):Play()
        Debris:AddItem(crater,2.2)
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  PODER RAYO 4: DESCARGA SUPREMA — canal absoluto de energía
-- ═══════════════════════════════════════════════════════════════
RE_SupremeDisch.OnServerEvent:Connect(function(player)
    if not supremeUnlocked[player] then return end
    if isOnCooldown(player,"SupremeDisch") then return end
    local char=player.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local target=getNearestEnemy(player,60)

    RE_Anim:FireAllClients(player,"SupremeDisch_Pose")
    RE_Effect:FireAllClients("SupremeDisch_Cast",player)

    -- Stun al objetivo durante todo el canal
    if target then stunned[target]=tick()+4.5; RE_Stun:FireClient(target,4.5) end

    -- Fase 1: carga masiva de energía (0-2s)
    -- 360 arcos de rayo girando alrededor del caster
    local chargeConn; local chargeStart=tick()
    chargeConn=RunService.Heartbeat:Connect(function()
        if tick()-chargeStart>2.0 then chargeConn:Disconnect(); return end
        if not hrp or not hrp.Parent then chargeConn:Disconnect(); return end
        local t=tick()
        for i=1,6 do
            local baseAngle=(i/6)*math.pi*2+t*8
            local arcEnd=hrp.Position+Vector3.new(
                math.cos(baseAngle)*18, math.sin(t*4+i)*10, math.sin(baseAngle)*18
            )
            drawLightningBetween(hrp.Position,arcEnd,Color3.fromRGB(180,240,255),4,0.08,0.10,2.5)
        end
    end)

    -- Fase 2: descarga al objetivo (2-4s)
    task.delay(2.0,function()
        if not target or not target.Character then return end
        local targetHrp=target.Character:FindFirstChild("HumanoidRootPart"); if not targetHrp then return end

        local dischargeConn; local dischargeStart=tick(); local lastDmgTick=tick(); local lastZapTick=tick()
        dischargeConn=RunService.Heartbeat:Connect(function()
            local elapsed=tick()-dischargeStart
            if elapsed>2.5 then dischargeConn:Disconnect(); return end
            if not hrp or not hrp.Parent or not targetHrp or not targetHrp.Parent then
                dischargeConn:Disconnect(); return
            end
            -- Rayos continuos de la mano al objetivo
            if tick()-lastZapTick>0.04 then
                lastZapTick=tick()
                local rArm2=char:FindFirstChild("Right Arm") or char:FindFirstChild("RightLowerArm") or char:FindFirstChild("RightHand")
                local handP=rArm2 and rArm2.Position or hrp.Position+hrp.CFrame.LookVector*1.5
                drawLightningBetween(handP,targetHrp.Position,Color3.fromRGB(255,255,255),8,0.20,0.08,4.0)
                task.delay(0.02,function()
                    if hrp and hrp.Parent and targetHrp and targetHrp.Parent then
                        drawLightningBetween(handP,targetHrp.Position,Color3.fromRGB(120,220,255),4,0.10,0.06,3.0)
                    end
                end)
                -- Arcos secundarios hacia el entorno
                local secAngle=tick()*15
                local secEnd=targetHrp.Position+Vector3.new(math.cos(secAngle)*8,(math.random()-0.5)*5,math.sin(secAngle)*8)
                drawLightningBetween(targetHrp.Position,secEnd,Color3.fromRGB(80,180,255),4,0.07,0.09,2.5)
            end
            -- Daño continuo brutal
            if tick()-lastDmgTick>0.25 then
                lastDmgTick=tick(); dealDamage(target,15)
                applyKnockback(target,(targetHrp.Position-hrp.Position).Unit*0.2+Vector3.new(0,0.3,0),8)
            end
        end)

        -- Golpe final masivo
        task.delay(2.5,function()
            if targetHrp and targetHrp.Parent then
                local finalPos=targetHrp.Position
                dealDamage(target,150)
                applyKnockback(target,(targetHrp.Position-hrp.Position).Unit+Vector3.new(0,0.6,0),120)
                RE_Stun:FireClient(target,3); stunned[target]=tick()+3

                -- Explosión eléctrica final
                for ring=1,8 do
                    task.delay(ring*0.05,function()
                        local w=Instance.new("Part"); w.Shape=Enum.PartType.Cylinder
                        w.Size=Vector3.new(0.10,ring*1.0,ring*1.0)
                        w.CFrame=CFrame.new(finalPos)*CFrame.Angles(0,0,math.pi/2)
                        w.Color=ring%2==0 and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,200,255)
                        w.Material=Enum.Material.Neon; w.Anchored=true; w.CanCollide=false; w.CastShadow=false; w.Transparency=0.1; w.Parent=Workspace
                        local wpl2=Instance.new("PointLight"); wpl2.Color=Color3.fromRGB(100,220,255); wpl2.Brightness=15; wpl2.Range=30; wpl2.Parent=w
                        TweenService:Create(w,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                            Size=Vector3.new(0.03,35*ring,35*ring),Transparency=1
                        }):Play()
                        Debris:AddItem(w,0.9)
                    end)
                end

                -- 24 rayos en todas las direcciones desde la explosión
                for i=1,24 do
                    local angle=(i/24)*math.pi*2
                    local rayEnd=finalPos+Vector3.new(math.cos(angle)*20,(math.random()-0.5)*8,math.sin(angle)*20)
                    task.delay(math.random()*0.15,function()
                        drawLightningBetween(finalPos,rayEnd,Color3.fromRGB(200,240,255),8,0.14,0.35,5.0)
                    end)
                end

                -- Dañar a todos los enemigos cercanos con la onda
                for _, p in ipairs(Players:GetPlayers()) do
                    if p~=player and p~=target and p.Character then
                        local eh=p.Character:FindFirstChild("HumanoidRootPart")
                        if eh and (eh.Position-finalPos).Magnitude<20 then
                            dealDamage(p,50); applyKnockback(p,(eh.Position-finalPos).Unit+Vector3.new(0,0.5,0),60)
                            RE_Stun:FireClient(p,2); stunned[p]=tick()+2
                            drawLightningBetween(finalPos,eh.Position,Color3.fromRGB(180,230,255),6,0.12,0.30,3.5)
                        end
                    end
                end

                RE_Effect:FireAllClients("SupremeDisch_Explode",finalPos)
            end

            -- Reset
            task.delay(3,function() supremeUnlocked[player]=nil end)
        end)
    end)
end)

-- ─── LIMPIAR AL SALIR ─────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
    local uid=tostring(player.UserId)
    for _,skill in ipairs({"BloodBall","BloodCorpuscle","BloodWhip","Souls1000","LightningBolt","ThunderChain","ElectricStorm","SupremeDisch"}) do
        cooldowns[uid.."_"..skill]=nil
    end
    stunned[player]=nil; whipActive[player]=nil
    souls1000Unlocked[player]=nil; supremeUnlocked[player]=nil
    playerBraceletParts[player]=nil; playerLeftArm[player]=nil
end)

print("[Powers] ServerScript cargado correctamente ✓")
