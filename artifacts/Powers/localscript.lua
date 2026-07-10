-- ============================================================
--   BLOOD & LIGHTNING POWERS - LOCAL SCRIPT (CORREGIDO + RAYO)
--   Coloca esto en: StarterPlayerScripts > LocalScript
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ─── ESPERAR REMOTES ─────────────────────────────────────────
local RemoteFolder      = ReplicatedStorage:WaitForChild("BloodPowerEvents", 20)
local RE_BloodBall      = RemoteFolder:WaitForChild("BloodBall")
local RE_BloodCorpuscle = RemoteFolder:WaitForChild("BloodCorpuscle")
local RE_BloodWhip      = RemoteFolder:WaitForChild("BloodWhip")
local RE_Souls1000      = RemoteFolder:WaitForChild("Souls1000")
local RE_Effect         = RemoteFolder:WaitForChild("EffectToAll")
local RE_Stun           = RemoteFolder:WaitForChild("StunTarget")
local RE_Unlock1000     = RemoteFolder:WaitForChild("Unlock1000Souls")
local RE_Anim           = RemoteFolder:WaitForChild("PlayAnim")
local RE_Bracelet       = RemoteFolder:WaitForChild("SpawnBracelet")
-- Rayos
local RE_LightningBolt  = RemoteFolder:WaitForChild("LightningBolt")
local RE_ThunderChain   = RemoteFolder:WaitForChild("ThunderChain")
local RE_ElectricStorm  = RemoteFolder:WaitForChild("ElectricStorm")
local RE_SupremeDisch   = RemoteFolder:WaitForChild("SupremeDisch")
local RE_UnlockSupreme  = RemoteFolder:WaitForChild("UnlockSupreme")

-- ─── ESTADO LOCAL ────────────────────────────────────────────
local isStunnedLocal  = false
local stunEndTime     = 0
local souls1000Button = nil
local supremeButton   = nil
local selectedPower   = "Blood"   -- "Blood" | "Lightning"

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

-- ═══════════════════════════════════════════════════════════════
--  GUI — DisplayOrder alto para estar SIEMPRE encima del UI base
-- ═══════════════════════════════════════════════════════════════
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("BloodPowerGui") then
    PlayerGui.BloodPowerGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "BloodPowerGui"
ScreenGui.ResetOnSpawn     = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder     = 20    -- por encima del Roblox CoreGui (default 0)
ScreenGui.IgnoreGuiInset   = true  -- cubre todo el viewport incluyendo la barra superior
ScreenGui.Parent           = PlayerGui

-- ═══════════════════════════════════════════════════════════════
--  CARRUSEL DE SELECCIÓN DE PODERES — FONDO NEGRO PURO
-- ═══════════════════════════════════════════════════════════════
local POWERS = {
    { name="Control de la Sangre", icon="🩸", accentColor=Color3.fromRGB(220,0,0),
      desc="Domina la sangre con 3 habilidades:\nBola de Sangre  ·  Glóbulos  ·  Látigo", locked=false, id="Blood"   },
    { name="Poder del Rayo",       icon="⚡", accentColor=Color3.fromRGB(255,220,0),
      desc="Controla el trueno con 3 habilidades:\nRayo  ·  Cadena  ·  Tormenta",          locked=false, id="Lightning" },
    { name="Poder del Agua",       icon="💧", accentColor=Color3.fromRGB(0,160,255),
      desc="Próximamente disponible",                                                        locked=true,  id="Water"   },
    { name="Poder del Diamante",   icon="💎", accentColor=Color3.fromRGB(120,230,255),
      desc="Próximamente disponible",                                                        locked=true,  id="Diamond" },
}
local currentPowerIndex = 1

-- ── OVERLAY NEGRO TOTAL (cubre todo antes de mostrar la tarjeta) ──
local carouselBG = Instance.new("Frame")
carouselBG.Name                 = "PowerCarousel"
carouselBG.Size                 = UDim2.new(1,0,1,0)
carouselBG.Position             = UDim2.new(0,0,0,0)
carouselBG.BackgroundColor3     = Color3.fromRGB(0,0,0)      -- NEGRO PURO
carouselBG.BackgroundTransparency = 1                         -- empieza invisible
carouselBG.BorderSizePixel      = 0
carouselBG.ZIndex               = 50
carouselBG.Parent               = ScreenGui

local carouselTitle = Instance.new("TextLabel")
carouselTitle.Size               = UDim2.new(0.82,0,0.09,0)
carouselTitle.Position           = UDim2.new(0.09,0,0.05,0)
carouselTitle.BackgroundTransparency = 1
carouselTitle.Text               = "⚔   ELIGE TU PODER   ⚔"
carouselTitle.TextScaled         = true
carouselTitle.Font               = Enum.Font.GothamBold
carouselTitle.TextColor3         = Color3.fromRGB(255,255,255)
carouselTitle.TextStrokeTransparency = 0.3
carouselTitle.TextStrokeColor3   = Color3.fromRGB(180,0,0)
carouselTitle.TextTransparency   = 1
carouselTitle.ZIndex             = 51
carouselTitle.Parent             = carouselBG

local carouselSub = Instance.new("TextLabel")
carouselSub.Size               = UDim2.new(0.7,0,0.05,0)
carouselSub.Position           = UDim2.new(0.15,0,0.145,0)
carouselSub.BackgroundTransparency = 1
carouselSub.Text               = "← Desliza o toca las flechas →"
carouselSub.TextScaled         = true
carouselSub.Font               = Enum.Font.Gotham
carouselSub.TextColor3         = Color3.fromRGB(180,150,120)
carouselSub.TextTransparency   = 1
carouselSub.ZIndex             = 51
carouselSub.Parent             = carouselBG

local powerCard = Instance.new("Frame")
powerCard.Name            = "PowerCard"
powerCard.AnchorPoint     = Vector2.new(0.5,0.5)
powerCard.Size            = UDim2.new(0,0,0,0)
powerCard.Position        = UDim2.new(0.5,0,0.52,0)
powerCard.BackgroundColor3 = Color3.fromRGB(10,5,15)
powerCard.BorderSizePixel = 0
powerCard.ZIndex          = 51
powerCard.Parent          = carouselBG
Instance.new("UICorner", powerCard).CornerRadius = UDim.new(0.07,0)
local cardStroke = Instance.new("UIStroke")
cardStroke.Color     = Color3.fromRGB(200,0,0)
cardStroke.Thickness = 2.5
cardStroke.Parent    = powerCard

local cardIcon = Instance.new("TextLabel")
cardIcon.Size               = UDim2.new(0.55,0,0.36,0)
cardIcon.Position           = UDim2.new(0.225,0,0.06,0)
cardIcon.BackgroundTransparency = 1
cardIcon.Text               = POWERS[1].icon
cardIcon.TextScaled         = true
cardIcon.Font               = Enum.Font.GothamBold
cardIcon.TextColor3         = Color3.fromRGB(255,255,255)
cardIcon.ZIndex             = 52
cardIcon.Parent             = powerCard

local cardName = Instance.new("TextLabel")
cardName.Size               = UDim2.new(0.9,0,0.16,0)
cardName.Position           = UDim2.new(0.05,0,0.43,0)
cardName.BackgroundTransparency = 1
cardName.Text               = POWERS[1].name
cardName.TextScaled         = true
cardName.Font               = Enum.Font.GothamBold
cardName.TextColor3         = Color3.fromRGB(255,255,255)
cardName.TextWrapped        = true
cardName.ZIndex             = 52
cardName.Parent             = powerCard

local cardDesc = Instance.new("TextLabel")
cardDesc.Size               = UDim2.new(0.85,0,0.15,0)
cardDesc.Position           = UDim2.new(0.075,0,0.60,0)
cardDesc.BackgroundTransparency = 1
cardDesc.Text               = POWERS[1].desc
cardDesc.TextScaled         = true
cardDesc.Font               = Enum.Font.Gotham
cardDesc.TextColor3         = Color3.fromRGB(200,175,175)
cardDesc.TextWrapped        = true
cardDesc.ZIndex             = 52
cardDesc.Parent             = powerCard

local devBadge = Instance.new("Frame")
devBadge.AnchorPoint      = Vector2.new(0.5,0)
devBadge.Size             = UDim2.new(0.70,0,0.12,0)
devBadge.Position         = UDim2.new(0.5,0,0.03,0)
devBadge.BackgroundColor3 = Color3.fromRGB(100,40,0)
devBadge.BorderSizePixel  = 0
devBadge.Visible          = false
devBadge.ZIndex           = 53
devBadge.Parent           = powerCard
Instance.new("UICorner", devBadge).CornerRadius = UDim.new(0.5,0)
local devTxt = Instance.new("TextLabel")
devTxt.Size               = UDim2.new(1,0,1,0)
devTxt.BackgroundTransparency = 1
devTxt.Text               = "🔒  EN DESARROLLO"
devTxt.TextScaled         = true
devTxt.Font               = Enum.Font.GothamBold
devTxt.TextColor3         = Color3.fromRGB(255,210,80)
devTxt.ZIndex             = 54
devTxt.Parent             = devBadge

local selectBtn = Instance.new("TextButton")
selectBtn.AnchorPoint     = Vector2.new(0.5,1)
selectBtn.Size            = UDim2.new(0.72,0,0.14,0)
selectBtn.Position        = UDim2.new(0.5,0,0.97,0)
selectBtn.BackgroundColor3 = Color3.fromRGB(140,0,0)
selectBtn.BorderSizePixel = 0
selectBtn.Text            = "✔  SELECCIONAR"
selectBtn.TextScaled      = true
selectBtn.Font            = Enum.Font.GothamBold
selectBtn.TextColor3      = Color3.fromRGB(255,255,255)
selectBtn.ZIndex          = 53
selectBtn.Visible         = true
selectBtn.Parent          = powerCard
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0.4,0)

local function makeArrow(anchorX, txt)
    local a = Instance.new("TextButton")
    a.AnchorPoint     = Vector2.new(anchorX,0.5)
    a.Size            = UDim2.new(0,58,0,58)
    a.Position        = UDim2.new(anchorX==1 and 0.11 or 0.89, 0, 0.52, 0)
    a.BackgroundColor3 = Color3.fromRGB(20,10,30)
    a.BorderSizePixel = 0
    a.Text            = txt
    a.TextScaled      = true
    a.Font            = Enum.Font.GothamBold
    a.TextColor3      = Color3.fromRGB(255,200,100)
    a.ZIndex          = 52
    a.Parent          = carouselBG
    Instance.new("UICorner",a).CornerRadius = UDim.new(1,0)
    local s = Instance.new("UIStroke"); s.Color=Color3.fromRGB(200,150,0); s.Thickness=2; s.Parent=a
    return a
end
local leftArrow  = makeArrow(1,"‹")
local rightArrow = makeArrow(0,"›")

-- Indicadores de punto (dots)
local dotsFrame = Instance.new("Frame")
dotsFrame.AnchorPoint        = Vector2.new(0.5,0)
dotsFrame.Size               = UDim2.new(0,140,0,20)
dotsFrame.Position           = UDim2.new(0.5,0,0.86,0)
dotsFrame.BackgroundTransparency = 1
dotsFrame.ZIndex             = 52
dotsFrame.Parent             = carouselBG
local dotsLayout = Instance.new("UIListLayout")
dotsLayout.FillDirection       = Enum.FillDirection.Horizontal
dotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dotsLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
dotsLayout.Padding             = UDim.new(0,10)
dotsLayout.Parent              = dotsFrame

local dots = {}
for i = 1, #POWERS do
    local d = Instance.new("Frame")
    d.Size             = UDim2.new(0, i==1 and 16 or 10, 0, i==1 and 16 or 10)
    d.BackgroundColor3 = i==1 and Color3.fromRGB(220,0,0) or Color3.fromRGB(60,20,20)
    d.BorderSizePixel  = 0
    d.ZIndex           = 53
    d.Parent           = dotsFrame
    Instance.new("UICorner",d).CornerRadius = UDim.new(1,0)
    dots[i] = d
end

local CARD_NORMAL = UDim2.new(0.60,0,0.58,0)
local CARD_SMALL  = UDim2.new(0.56,0,0.54,0)

local function updateCarouselCard(idx)
    local p = POWERS[idx]
    TweenService:Create(cardIcon,TweenInfo.new(0.08),{TextTransparency=1}):Play()
    task.delay(0.10,function()
        cardIcon.Text    = p.icon
        cardName.Text    = p.name
        cardDesc.Text    = p.desc
        devBadge.Visible  = p.locked
        selectBtn.Visible = not p.locked
        -- Actualizar colores según poder
        local accent = p.accentColor
        TweenService:Create(cardStroke,TweenInfo.new(0.22),{Color=accent}):Play()
        TweenService:Create(selectBtn, TweenInfo.new(0.22),{BackgroundColor3=Color3.fromRGB(
            math.floor(accent.R*160), math.floor(accent.G*80), math.floor(accent.B*80)
        )}):Play()
        TweenService:Create(cardIcon, TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
    end)
    for i,d in ipairs(dots) do
        TweenService:Create(d,TweenInfo.new(0.18),{
            BackgroundColor3 = i==idx and POWERS[i].accentColor or Color3.fromRGB(60,20,40),
            Size = i==idx and UDim2.new(0,16,0,16) or UDim2.new(0,9,0,9),
        }):Play()
    end
end

local function bounceCard()
    TweenService:Create(powerCard,TweenInfo.new(0.08,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=CARD_SMALL}):Play()
    task.delay(0.08,function()
        TweenService:Create(powerCard,TweenInfo.new(0.20,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=CARD_NORMAL}):Play()
    end)
end

leftArrow.MouseButton1Click:Connect(function()
    currentPowerIndex = currentPowerIndex==1 and #POWERS or currentPowerIndex-1
    bounceCard(); updateCarouselCard(currentPowerIndex)
end)
rightArrow.MouseButton1Click:Connect(function()
    currentPowerIndex = currentPowerIndex==#POWERS and 1 or currentPowerIndex+1
    bounceCard(); updateCarouselCard(currentPowerIndex)
end)

-- Swipe táctil
local swipeStartX = nil
carouselBG.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch then swipeStartX=input.Position.X end
end)
carouselBG.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch and swipeStartX then
        local delta = input.Position.X - swipeStartX
        if math.abs(delta)>50 then
            currentPowerIndex = delta<0
                and (currentPowerIndex==#POWERS and 1 or currentPowerIndex+1)
                or  (currentPowerIndex==1 and #POWERS or currentPowerIndex-1)
            bounceCard(); updateCarouselCard(currentPowerIndex)
        end
        swipeStartX=nil
    end
end)

local function closeCarousel()
    TweenService:Create(carouselTitle,TweenInfo.new(0.25),{TextTransparency=1}):Play()
    TweenService:Create(carouselSub,  TweenInfo.new(0.25),{TextTransparency=1}):Play()
    TweenService:Create(powerCard,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,0)}):Play()
    task.delay(0.32,function()
        TweenService:Create(carouselBG,TweenInfo.new(0.30),{BackgroundTransparency=1}):Play()
        task.delay(0.32,function() carouselBG:Destroy() end)
    end)
end

selectBtn.MouseButton1Click:Connect(function()
    local p = POWERS[currentPowerIndex]
    if p.locked then return end
    selectedPower = p.id
    TweenService:Create(selectBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,180,60)}):Play()
    -- Mostrar/ocultar grupos de botones según poder elegido
    task.delay(0.12,function()
        BloodFrame.Visible     = (selectedPower=="Blood")
        LightningFrame.Visible = (selectedPower=="Lightning")
    end)
    task.delay(0.4,closeCarousel)
end)

-- Mostrar carrusel con entrada épica
task.delay(0.5,function()
    TweenService:Create(carouselBG,    TweenInfo.new(0.35),{BackgroundTransparency=0}):Play()  -- NEGRO SÓLIDO
    TweenService:Create(carouselTitle, TweenInfo.new(0.45),{TextTransparency=0}):Play()
    TweenService:Create(carouselSub,   TweenInfo.new(0.45),{TextTransparency=0}):Play()
    TweenService:Create(powerCard, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=CARD_NORMAL}):Play()
end)

-- ═══════════════════════════════════════════════════════════════
--  FUNCIÓN HELPER DE BOTONES
-- ═══════════════════════════════════════════════════════════════
local function createPowerButton(parent, name, key, icon, color1, order)
    local btn = Instance.new("Frame")
    btn.Name             = name
    btn.Size             = UDim2.new(0,80,0,80)
    btn.BackgroundTransparency = 1
    btn.LayoutOrder      = order
    btn.Parent           = parent

    local bg = Instance.new("ImageLabel")
    bg.Name              = "Background"
    bg.Size              = UDim2.new(0,80,0,80)
    bg.Position          = UDim2.new(0.5,-40,0,0)
    bg.BackgroundColor3  = Color3.fromRGB(5,0,10)
    bg.BorderSizePixel   = 0
    bg.ImageTransparency = 1
    bg.Active            = true
    bg.ZIndex            = 2
    bg.Parent            = btn
    Instance.new("UICorner",bg).CornerRadius = UDim.new(1,0)

    local stroke = Instance.new("UIStroke")
    stroke.Color     = color1
    stroke.Thickness = 2.5
    stroke.Parent    = bg

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size               = UDim2.new(0.58,0,0.58,0)
    iconLbl.Position           = UDim2.new(0.21,0,0.12,0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text               = icon
    iconLbl.TextScaled         = true
    iconLbl.Font               = Enum.Font.GothamBold
    iconLbl.TextColor3         = Color3.fromRGB(255,255,255)
    iconLbl.ZIndex             = 4
    iconLbl.Parent             = bg

    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size             = UDim2.new(0,22,0,22)
    keyLbl.Position         = UDim2.new(0.60,0,-0.06,0)
    keyLbl.BackgroundColor3 = Color3.fromRGB(10,5,20)
    keyLbl.BorderSizePixel  = 0
    keyLbl.Text             = key
    keyLbl.TextScaled       = true
    keyLbl.Font             = Enum.Font.GothamBold
    keyLbl.TextColor3       = color1
    keyLbl.ZIndex           = 5
    keyLbl.Parent           = btn
    Instance.new("UICorner",keyLbl).CornerRadius = UDim.new(0.3,0)

    local cd = Instance.new("Frame")
    cd.Name              = "CooldownOverlay"
    cd.Size              = UDim2.new(1,0,0,0)
    cd.Position          = UDim2.new(0,0,0,0)
    cd.BackgroundColor3  = Color3.fromRGB(0,0,0)
    cd.BackgroundTransparency = 0.38
    cd.BorderSizePixel   = 0
    cd.ZIndex            = 3
    cd.Parent            = bg
    Instance.new("UICorner",cd).CornerRadius = UDim.new(1,0)

    local cdt = Instance.new("TextLabel")
    cdt.Size               = UDim2.new(1,0,1,0)
    cdt.BackgroundTransparency = 1
    cdt.Text               = ""
    cdt.TextScaled         = true
    cdt.Font               = Enum.Font.GothamBold
    cdt.TextColor3         = Color3.fromRGB(255,255,255)
    cdt.ZIndex             = 4
    cdt.Parent             = bg

    local glow = Instance.new("Frame")
    glow.Size             = UDim2.new(1,14,1,14)
    glow.Position         = UDim2.new(0,-7,0,-7)
    glow.BackgroundColor3 = color1
    glow.BackgroundTransparency = 0.82
    glow.BorderSizePixel  = 0
    glow.ZIndex           = 1
    Instance.new("UICorner",glow).CornerRadius = UDim.new(1,0)
    glow.Parent           = bg

    task.spawn(function()
        while bg and bg.Parent do
            TweenService:Create(glow,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.52}):Play()
            task.wait(1.2)
            TweenService:Create(glow,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.88}):Play()
            task.wait(1.2)
        end
    end)

    return btn, bg, cd, cdt, stroke
end

-- ═══════════════════════════════════════════════════════════════
--  FRAME CONTENEDOR — SANGRE
-- ═══════════════════════════════════════════════════════════════
BloodFrame = Instance.new("Frame")
BloodFrame.Name             = "BloodFrame"
BloodFrame.AnchorPoint      = Vector2.new(1,1)
BloodFrame.Size             = UDim2.new(0,86,0,268)
BloodFrame.Position         = UDim2.new(1,-14,1,-125)
BloodFrame.BackgroundTransparency = 1
BloodFrame.Visible          = false   -- se muestra al elegir sangre
BloodFrame.Parent           = ScreenGui
local bloodList = Instance.new("UIListLayout")
bloodList.FillDirection       = Enum.FillDirection.Vertical
bloodList.HorizontalAlignment = Enum.HorizontalAlignment.Center
bloodList.VerticalAlignment   = Enum.VerticalAlignment.Bottom
bloodList.SortOrder           = Enum.SortOrder.LayoutOrder
bloodList.Padding             = UDim.new(0,14)
bloodList.Parent              = BloodFrame

local btn1,bg1,cd1,cdt1,stroke1 = createPowerButton(BloodFrame,"Bola de Sangre",  "Q","🩸",Color3.fromRGB(220,20,20),1)
local btn2,bg2,cd2,cdt2,stroke2 = createPowerButton(BloodFrame,"Glóbulos",        "E","💀",Color3.fromRGB(180,0,60), 2)
local btn3,bg3,cd3,cdt3,stroke3 = createPowerButton(BloodFrame,"Látigo de Sangre","R","⛓",Color3.fromRGB(200,0,0),  3)

-- Botón 1000 Almas
local btn4Frame = Instance.new("Frame")
btn4Frame.Name             = "Souls1000Btn"
btn4Frame.Size             = UDim2.new(0,80,0,80)
btn4Frame.BackgroundTransparency = 1
btn4Frame.LayoutOrder      = 4
btn4Frame.Visible          = false
btn4Frame.Parent           = BloodFrame

local bg4 = Instance.new("ImageLabel")
bg4.Name             = "Background"
bg4.Size             = UDim2.new(0,80,0,80)
bg4.Position         = UDim2.new(0.5,-40,0,0)
bg4.BackgroundColor3 = Color3.fromRGB(5,0,20)
bg4.BorderSizePixel  = 0
bg4.ImageTransparency = 1
bg4.Active           = true
bg4.ZIndex           = 2
bg4.Parent           = btn4Frame
Instance.new("UICorner",bg4).CornerRadius = UDim.new(1,0)
local stroke4 = Instance.new("UIStroke")
stroke4.Color=Color3.fromRGB(180,0,255); stroke4.Thickness=3; stroke4.Parent=bg4
local icon4 = Instance.new("TextLabel")
icon4.Size=UDim2.new(0.58,0,0.58,0); icon4.Position=UDim2.new(0.21,0,0.12,0)
icon4.BackgroundTransparency=1; icon4.Text="☠"; icon4.TextScaled=true
icon4.Font=Enum.Font.GothamBold; icon4.TextColor3=Color3.fromRGB(200,50,255)
icon4.ZIndex=4; icon4.Parent=bg4
local key4 = Instance.new("TextLabel")
key4.Size=UDim2.new(0,22,0,22); key4.Position=UDim2.new(0.60,0,-0.06,0)
key4.BackgroundColor3=Color3.fromRGB(18,0,40); key4.BorderSizePixel=0
key4.Text="F"; key4.TextScaled=true; key4.Font=Enum.Font.GothamBold
key4.TextColor3=Color3.fromRGB(200,50,255); key4.ZIndex=5; key4.Parent=btn4Frame
Instance.new("UICorner",key4).CornerRadius=UDim.new(0.3,0)
local cd4=Instance.new("Frame"); cd4.Name="CooldownOverlay"
cd4.Size=UDim2.new(1,0,0,0); cd4.Position=UDim2.new(0,0,0,0)
cd4.BackgroundColor3=Color3.fromRGB(0,0,0); cd4.BackgroundTransparency=0.4
cd4.BorderSizePixel=0; cd4.ZIndex=3; cd4.Parent=bg4
Instance.new("UICorner",cd4).CornerRadius=UDim.new(1,0)
local cdt4=Instance.new("TextLabel"); cdt4.Size=UDim2.new(1,0,1,0)
cdt4.BackgroundTransparency=1; cdt4.Text=""; cdt4.TextScaled=true
cdt4.Font=Enum.Font.GothamBold; cdt4.TextColor3=Color3.fromRGB(255,255,255)
cdt4.ZIndex=4; cdt4.Parent=bg4
local glow4=Instance.new("Frame"); glow4.Size=UDim2.new(1,14,1,14)
glow4.Position=UDim2.new(0,-7,0,-7); glow4.BackgroundColor3=Color3.fromRGB(180,0,255)
glow4.BackgroundTransparency=0.7; glow4.BorderSizePixel=0; glow4.ZIndex=1
Instance.new("UICorner",glow4).CornerRadius=UDim.new(1,0); glow4.Parent=bg4
task.spawn(function()
    while bg4 and bg4.Parent do
        TweenService:Create(glow4,TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.28,BackgroundColor3=Color3.fromRGB(255,50,255)}):Play()
        task.wait(0.7)
        TweenService:Create(glow4,TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.85,BackgroundColor3=Color3.fromRGB(100,0,180)}):Play()
        task.wait(0.7)
    end
end)
souls1000Button = btn4Frame

-- ═══════════════════════════════════════════════════════════════
--  FRAME CONTENEDOR — RAYO (LIGHTNING)
-- ═══════════════════════════════════════════════════════════════
LightningFrame = Instance.new("Frame")
LightningFrame.Name             = "LightningFrame"
LightningFrame.AnchorPoint      = Vector2.new(1,1)
LightningFrame.Size             = UDim2.new(0,86,0,268)
LightningFrame.Position         = UDim2.new(1,-14,1,-125)
LightningFrame.BackgroundTransparency = 1
LightningFrame.Visible          = false   -- se muestra al elegir rayo
LightningFrame.Parent           = ScreenGui
local lightningList = Instance.new("UIListLayout")
lightningList.FillDirection       = Enum.FillDirection.Vertical
lightningList.HorizontalAlignment = Enum.HorizontalAlignment.Center
lightningList.VerticalAlignment   = Enum.VerticalAlignment.Bottom
lightningList.SortOrder           = Enum.SortOrder.LayoutOrder
lightningList.Padding             = UDim.new(0,14)
lightningList.Parent              = LightningFrame

local GOLD  = Color3.fromRGB(255,220,0)
local CYAN  = Color3.fromRGB(80,220,255)
local WHITE = Color3.fromRGB(220,240,255)

local lbtn1,lbg1,lcd1,lcdt1,lstroke1 = createPowerButton(LightningFrame,"Rayo Devastador",  "Q","⚡",GOLD, 1)
local lbtn2,lbg2,lcd2,lcdt2,lstroke2 = createPowerButton(LightningFrame,"Cadena de Trueno", "E","🌩",CYAN, 2)
local lbtn3,lbg3,lcd3,lcdt3,lstroke3 = createPowerButton(LightningFrame,"Tormenta Eléctrica","R","🌪",WHITE,3)

-- Botón Descarga Suprema (desbloqueable)
local lbtn4Frame = Instance.new("Frame")
lbtn4Frame.Name             = "SupremeBtn"
lbtn4Frame.Size             = UDim2.new(0,80,0,80)
lbtn4Frame.BackgroundTransparency = 1
lbtn4Frame.LayoutOrder      = 4
lbtn4Frame.Visible          = false
lbtn4Frame.Parent           = LightningFrame

local lbg4 = Instance.new("ImageLabel")
lbg4.Name="Background"; lbg4.Size=UDim2.new(0,80,0,80); lbg4.Position=UDim2.new(0.5,-40,0,0)
lbg4.BackgroundColor3=Color3.fromRGB(0,10,30); lbg4.BorderSizePixel=0; lbg4.ImageTransparency=1
lbg4.Active=true; lbg4.ZIndex=2; lbg4.Parent=lbtn4Frame
Instance.new("UICorner",lbg4).CornerRadius=UDim.new(1,0)
local lstroke4=Instance.new("UIStroke"); lstroke4.Color=Color3.fromRGB(0,200,255); lstroke4.Thickness=3; lstroke4.Parent=lbg4
local licon4=Instance.new("TextLabel"); licon4.Size=UDim2.new(0.58,0,0.58,0); licon4.Position=UDim2.new(0.21,0,0.12,0)
licon4.BackgroundTransparency=1; licon4.Text="☁"; licon4.TextScaled=true; licon4.Font=Enum.Font.GothamBold
licon4.TextColor3=Color3.fromRGB(100,220,255); licon4.ZIndex=4; licon4.Parent=lbg4
local lkey4=Instance.new("TextLabel"); lkey4.Size=UDim2.new(0,22,0,22); lkey4.Position=UDim2.new(0.60,0,-0.06,0)
lkey4.BackgroundColor3=Color3.fromRGB(0,10,30); lkey4.BorderSizePixel=0; lkey4.Text="F"
lkey4.TextScaled=true; lkey4.Font=Enum.Font.GothamBold; lkey4.TextColor3=Color3.fromRGB(0,220,255)
lkey4.ZIndex=5; lkey4.Parent=lbtn4Frame; Instance.new("UICorner",lkey4).CornerRadius=UDim.new(0.3,0)
local lcd4=Instance.new("Frame"); lcd4.Name="CooldownOverlay"; lcd4.Size=UDim2.new(1,0,0,0)
lcd4.Position=UDim2.new(0,0,0,0); lcd4.BackgroundColor3=Color3.fromRGB(0,0,0)
lcd4.BackgroundTransparency=0.4; lcd4.BorderSizePixel=0; lcd4.ZIndex=3; lcd4.Parent=lbg4
Instance.new("UICorner",lcd4).CornerRadius=UDim.new(1,0)
local lcdt4=Instance.new("TextLabel"); lcdt4.Size=UDim2.new(1,0,1,0)
lcdt4.BackgroundTransparency=1; lcdt4.Text=""; lcdt4.TextScaled=true; lcdt4.Font=Enum.Font.GothamBold
lcdt4.TextColor3=Color3.fromRGB(255,255,255); lcdt4.ZIndex=4; lcdt4.Parent=lbg4
local lglow4=Instance.new("Frame"); lglow4.Size=UDim2.new(1,14,1,14); lglow4.Position=UDim2.new(0,-7,0,-7)
lglow4.BackgroundColor3=Color3.fromRGB(0,200,255); lglow4.BackgroundTransparency=0.7; lglow4.BorderSizePixel=0; lglow4.ZIndex=1
Instance.new("UICorner",lglow4).CornerRadius=UDim.new(1,0); lglow4.Parent=lbg4
task.spawn(function()
    while lbg4 and lbg4.Parent do
        TweenService:Create(lglow4,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.20,BackgroundColor3=Color3.fromRGB(150,240,255)}):Play()
        task.wait(0.5)
        TweenService:Create(lglow4,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.85,BackgroundColor3=Color3.fromRGB(0,120,200)}):Play()
        task.wait(0.5)
    end
end)
supremeButton = lbtn4Frame

-- ═══════════════════════════════════════════════════════════════
--  ANIMACIONES (Motor6D Tweening)
-- ═══════════════════════════════════════════════════════════════
local animLock  = false
local DEFAULT_C0 = {}

local function getMotors(char)
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local t = {}
    -- R6
    local torso = char:FindFirstChild("Torso")
    if torso then
        local names = {
            ["Left Shoulder"]  = "Left Arm",
            ["Right Shoulder"] = "Right Arm",
            ["Left Hip"]       = "Left Leg",
            ["Right Hip"]      = "Right Leg",
            ["Neck"]           = "Head",
        }
        for mname,key in pairs(names) do
            local m = torso:FindFirstChild(mname)
            if m then t[key]=m end
        end
    else
        -- R15
        local function fm(pn,mn,key)
            local p=char:FindFirstChild(pn)
            if p then local m=p:FindFirstChildOfClass("Motor6D") or p:FindFirstChild(mn); if m then t[key]=m end end
        end
        fm("LeftUpperArm","LeftShoulder","Left Arm")
        fm("RightUpperArm","RightShoulder","Right Arm")
        fm("LeftUpperLeg","LeftHip","Left Leg")
        fm("RightUpperLeg","RightHip","Right Leg")
        local hp=char:FindFirstChild("Head"); if hp then local m=hp:FindFirstChildOfClass("Motor6D"); if m then t["Head"]=m end end
    end
    local rj=hrp:FindFirstChild("RootJoint"); if rj then t["HumanoidRootPart"]=rj end
    return t
end

local function tweenMotor(motor, targetC0, duration, easingStyle)
    if not motor then return end
    local start=motor.C0; local elapsed=0; local conn
    conn=RunService.RenderStepped:Connect(function(dt)
        elapsed=elapsed+dt
        local a=math.min(elapsed/duration,1)
        motor.C0=start:Lerp(targetC0,TweenService:GetValue(a,easingStyle or Enum.EasingStyle.Quad,Enum.EasingDirection.Out))
        if a>=1 then conn:Disconnect() end
    end)
end

local function poseC0(k,v)
    local b=DEFAULT_C0[k]
    if b then return CFrame.new(b.X,b.Y,b.Z)*CFrame.Angles(v.X,v.Y,v.Z) end
    return CFrame.Angles(v.X,v.Y,v.Z)
end

local function restoreIdle(char,dur)
    dur=dur or 0.25
    for k,m in pairs(getMotors(char) or {}) do
        if DEFAULT_C0[k] then tweenMotor(m,DEFAULT_C0[k],dur,Enum.EasingStyle.Back) end
    end
end

local function captureDefaults(char)
    task.wait(0.4)
    local motors=getMotors(char); if not motors then return end
    local n=0
    for k,m in pairs(motors) do
        if m and m.Parent then DEFAULT_C0[k]=m.C0; n=n+1 end
    end
    if n==0 then
        task.wait(0.6); motors=getMotors(char)
        if motors then
            for k,m in pairs(motors) do
                if m and m.Parent then DEFAULT_C0[k]=m.C0 end
            end
        end
    end
end

-- ─── POSES SANGRE ───────────────────────────────────────────────
local function pose_BloodBall(char)
    if animLock then return end; animLock=true
    local mo=getMotors(char); if not mo then animLock=false return end
    if mo["Left Arm"]         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",        Vector3.new(0,0,math.rad(-130))),0.5,Enum.EasingStyle.Sine) end
    if mo["Right Arm"]        then tweenMotor(mo["Right Arm"],       poseC0("Right Arm",       Vector3.new(0,0,math.rad(25))),  0.5,Enum.EasingStyle.Sine) end
    if mo["HumanoidRootPart"] then tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(20),0),        0.5,Enum.EasingStyle.Sine) end
    task.delay(0.5,function()
        if mo["Left Arm"] and mo["Left Arm"].Parent   then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-90))),0.15,Enum.EasingStyle.Back) end
        if mo["Right Arm"] and mo["Right Arm"].Parent then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(30))),  0.15,Enum.EasingStyle.Quad) end
        if mo["HumanoidRootPart"] and mo["HumanoidRootPart"].Parent then
            tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(5),math.rad(-15),0),0.15,Enum.EasingStyle.Back)
        end
        task.delay(0.18,function()
            if mo["Left Arm"] and mo["Left Arm"].Parent then tweenMotor(mo["Left Arm"],poseC0("Left Arm",Vector3.new(0,0,math.rad(-60))),0.25,Enum.EasingStyle.Bounce) end
            task.delay(0.35,function() restoreIdle(char,0.35); task.delay(0.35,function() animLock=false end) end)
        end)
    end)
end

local function pose_BloodCorpuscle(char)
    if animLock then return end; animLock=true
    local mo=getMotors(char); if not mo then animLock=false return end
    if mo["Left Arm"]         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-80))),  0.45,Enum.EasingStyle.Sine) end
    if mo["Right Arm"]        then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(80))),   0.45,Enum.EasingStyle.Sine) end
    if mo["HumanoidRootPart"] then tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(-8),0,0),    0.45,Enum.EasingStyle.Sine) end
    task.delay(0.5,function()
        if mo["Left Arm"] and mo["Left Arm"].Parent         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-85))),  0.22,Enum.EasingStyle.Back) end
        if mo["Right Arm"] and mo["Right Arm"].Parent       then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(85))),   0.22,Enum.EasingStyle.Back) end
        if mo["HumanoidRootPart"] and mo["HumanoidRootPart"].Parent then
            tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(-14),0,0),0.22,Enum.EasingStyle.Quad)
        end
    end)
    task.delay(2.0,function()
        if mo["Left Arm"] and mo["Left Arm"].Parent         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-90))),0.14,Enum.EasingStyle.Back) end
        if mo["Right Arm"] and mo["Right Arm"].Parent       then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(90))),  0.14,Enum.EasingStyle.Back) end
        if mo["HumanoidRootPart"] and mo["HumanoidRootPart"].Parent then
            tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(8),0,0),0.14,Enum.EasingStyle.Back)
        end
        task.delay(0.4,function() restoreIdle(char,0.4); task.delay(0.4,function() animLock=false end) end)
    end)
end

local function pose_BloodWhip(char)
    if animLock then return end; animLock=true
    local mo=getMotors(char); if not mo then animLock=false return end
    if mo["Left Arm"]         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-90))),0.4,Enum.EasingStyle.Sine) end
    if mo["Right Arm"]        then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(90))),  0.4,Enum.EasingStyle.Sine) end
    if mo["HumanoidRootPart"] then tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(6),0,0),   0.4,Enum.EasingStyle.Sine) end
    local se=0; local sc
    sc=RunService.RenderStepped:Connect(function(dt)
        se=se+dt
        if se>8 then sc:Disconnect(); restoreIdle(char,0.4); task.delay(0.4,function() animLock=false end); return end
        local w=math.sin(se*6)*0.04; local w2=math.sin(se*9+1)*0.03
        if mo["Left Arm"] and mo["Left Arm"].Parent then
            local b=DEFAULT_C0["Left Arm"]; local px,py,pz=b and b.X or -1,b and b.Y or 0.5,b and b.Z or 0
            mo["Left Arm"].C0=CFrame.new(px,py,pz)*CFrame.Angles(w2,0,math.rad(-90)+w*20*math.pi/180)
        end
        if mo["Right Arm"] and mo["Right Arm"].Parent then
            local b=DEFAULT_C0["Right Arm"]; local px,py,pz=b and b.X or 1,b and b.Y or 0.5,b and b.Z or 0
            mo["Right Arm"].C0=CFrame.new(px,py,pz)*CFrame.Angles(-w2,0,math.rad(90)-w*20*math.pi/180)
        end
        if mo["HumanoidRootPart"] and mo["HumanoidRootPart"].Parent then
            mo["HumanoidRootPart"].C0=CFrame.new(0,0,0)*CFrame.Angles(math.rad(6)+math.sin(se*4)*0.025,0,0)
        end
    end)
end

local function pose_Souls1000(char)
    if animLock then return end; animLock=true
    local mo=getMotors(char); if not mo then animLock=false return end
    if mo["Left Arm"]         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-170))),0.6,Enum.EasingStyle.Sine) end
    if mo["Right Arm"]        then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(170))),  0.6,Enum.EasingStyle.Sine) end
    if mo["HumanoidRootPart"] then tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(-18),0,0),  0.6,Enum.EasingStyle.Sine) end
    task.delay(1.0,function()
        if mo["Left Arm"] and mo["Left Arm"].Parent   then tweenMotor(mo["Left Arm"],  poseC0("Left Arm",  Vector3.new(0,0,math.rad(-130))),0.30,Enum.EasingStyle.Back) end
        if mo["Right Arm"] and mo["Right Arm"].Parent then tweenMotor(mo["Right Arm"], poseC0("Right Arm", Vector3.new(0,0,math.rad(130))),  0.30,Enum.EasingStyle.Back) end
    end)
    task.delay(3.0,function()
        if mo["Left Arm"] and mo["Left Arm"].Parent   then tweenMotor(mo["Left Arm"],  poseC0("Left Arm",  Vector3.new(0,0,math.rad(-90))),0.12,Enum.EasingStyle.Bounce) end
        if mo["Right Arm"] and mo["Right Arm"].Parent then tweenMotor(mo["Right Arm"], poseC0("Right Arm", Vector3.new(0,0,math.rad(90))),  0.12,Enum.EasingStyle.Bounce) end
        if mo["HumanoidRootPart"] and mo["HumanoidRootPart"].Parent then
            tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(12),0,0),0.12,Enum.EasingStyle.Back)
        end
        task.delay(0.25,function()
            if mo["Left Arm"] and mo["Left Arm"].Parent   then tweenMotor(mo["Left Arm"],  poseC0("Left Arm",  Vector3.new(0,0,math.rad(-60))),0.20,Enum.EasingStyle.Quad) end
            if mo["Right Arm"] and mo["Right Arm"].Parent then tweenMotor(mo["Right Arm"], poseC0("Right Arm", Vector3.new(0,0,math.rad(60))),  0.20,Enum.EasingStyle.Quad) end
            task.delay(0.55,function() restoreIdle(char,0.5); task.delay(0.5,function() animLock=false end) end)
        end)
    end)
end

-- ─── POSES RAYO ─────────────────────────────────────────────────
local function pose_LightningBolt(char)
    if animLock then return end; animLock=true
    local mo=getMotors(char); if not mo then animLock=false return end
    -- Brazo derecho se eleva apuntando al frente, cuerpo gira levemente
    if mo["Right Arm"]        then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(135))),0.18,Enum.EasingStyle.Back) end
    if mo["Left Arm"]         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-30))),0.18,Enum.EasingStyle.Quad) end
    if mo["HumanoidRootPart"] then tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(-15),0),0.18,Enum.EasingStyle.Sine) end
    task.delay(0.20,function()
        -- Impulso del disparo
        if mo["Right Arm"] and mo["Right Arm"].Parent then tweenMotor(mo["Right Arm"],poseC0("Right Arm",Vector3.new(0,0,math.rad(80))),0.10,Enum.EasingStyle.Quad) end
        task.delay(0.35,function() restoreIdle(char,0.4); task.delay(0.4,function() animLock=false end) end)
    end)
end

local function pose_ThunderChain(char)
    if animLock then return end; animLock=true
    local mo=getMotors(char); if not mo then animLock=false return end
    -- Ambos brazos se expanden hacia los lados cargando la cadena
    if mo["Left Arm"]         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-150))),0.35,Enum.EasingStyle.Back) end
    if mo["Right Arm"]        then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(150))), 0.35,Enum.EasingStyle.Back) end
    if mo["HumanoidRootPart"] then tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(-10),0,0), 0.35,Enum.EasingStyle.Sine) end
    -- Vibración eléctrica en los brazos
    local t=0; local conn
    conn=RunService.RenderStepped:Connect(function(dt)
        t=t+dt
        if t>1.5 then conn:Disconnect() return end
        local jitter=math.sin(t*40)*0.04
        if mo["Left Arm"] and mo["Left Arm"].Parent then
            local b=DEFAULT_C0["Left Arm"]; local px,py,pz=b and b.X or -1,b and b.Y or 0.5,b and b.Z or 0
            mo["Left Arm"].C0=CFrame.new(px,py,pz)*CFrame.Angles(jitter,jitter*0.5,math.rad(-150)+jitter*2)
        end
        if mo["Right Arm"] and mo["Right Arm"].Parent then
            local b=DEFAULT_C0["Right Arm"]; local px,py,pz=b and b.X or 1,b and b.Y or 0.5,b and b.Z or 0
            mo["Right Arm"].C0=CFrame.new(px,py,pz)*CFrame.Angles(-jitter,jitter*0.5,math.rad(150)-jitter*2)
        end
    end)
    task.delay(1.8,function() restoreIdle(char,0.4); task.delay(0.4,function() animLock=false end) end)
end

local function pose_ElectricStorm(char)
    if animLock then return end; animLock=true
    local mo=getMotors(char); if not mo then animLock=false return end
    -- Brazos elevados apuntando al cielo, cuerpo inclinado hacia atrás
    if mo["Left Arm"]         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-180))),0.5,Enum.EasingStyle.Back) end
    if mo["Right Arm"]        then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(180))),  0.5,Enum.EasingStyle.Back) end
    if mo["HumanoidRootPart"] then tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(-20),0,0),  0.5,Enum.EasingStyle.Sine) end
    task.delay(5.5,function() restoreIdle(char,0.5); task.delay(0.5,function() animLock=false end) end)
end

local function pose_SupremeDisch(char)
    if animLock then return end; animLock=true
    local mo=getMotors(char); if not mo then animLock=false return end
    if mo["Left Arm"]         then tweenMotor(mo["Left Arm"],        poseC0("Left Arm",  Vector3.new(0,0,math.rad(-90))),0.3,Enum.EasingStyle.Back) end
    if mo["Right Arm"]        then tweenMotor(mo["Right Arm"],       poseC0("Right Arm", Vector3.new(0,0,math.rad(90))),  0.3,Enum.EasingStyle.Back) end
    if mo["HumanoidRootPart"] then tweenMotor(mo["HumanoidRootPart"],CFrame.new(0,0,0)*CFrame.Angles(math.rad(5),0,0),   0.3,Enum.EasingStyle.Sine) end
    -- Vibración extrema del cuerpo completo durante el canal
    local t=0; local conn
    conn=RunService.RenderStepped:Connect(function(dt)
        t=t+dt
        if t>4.0 then conn:Disconnect() return end
        local j=math.sin(t*35)*0.06*(1-t/4)
        if mo["HumanoidRootPart"] and mo["HumanoidRootPart"].Parent then
            mo["HumanoidRootPart"].C0=CFrame.new(j*0.3,0,0)*CFrame.Angles(math.rad(5)+j,j*0.5,j*0.3)
        end
    end)
    task.delay(4.5,function() restoreIdle(char,0.5); task.delay(0.5,function() animLock=false end) end)
end

-- ═══════════════════════════════════════════════════════════════
--  FUNCIONES DE EFECTOS VISUALES LOCALES
-- ═══════════════════════════════════════════════════════════════
local function epicActivationEffect(color1, color2, onFinish)
    color1=color1 or Color3.fromRGB(220,0,0)
    color2=color2 or Color3.fromRGB(255,60,0)
    local char=LocalPlayer.Character
    if not char then if onFinish then onFinish() end return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if not hrp then if onFinish then onFinish() end return end
    local N=16; local orbs={}; local sr=0.5; local er=3.2; local ET=0.42
    for i=1,N do
        local ba=(i/N)*math.pi*2
        local o=Instance.new("Part"); o.Size=Vector3.new(0.22,0.22,0.22); o.Shape=Enum.PartType.Ball
        o.Color=(i%3==0) and color2 or color1
        o.Material=Enum.Material.Neon; o.Transparency=0; o.CanCollide=false; o.CastShadow=false; o.Anchored=true
        local pl=Instance.new("PointLight"); pl.Color=color1; pl.Brightness=6; pl.Range=10; pl.Parent=o
        o.CFrame=hrp.CFrame*CFrame.new(sr*math.cos(ba),0.5,sr*math.sin(ba)); o.Parent=Workspace
        table.insert(orbs,{part=o,baseAngle=ba})
    end
    local elapsed=0; local rot=0; local ec
    ec=RunService.RenderStepped:Connect(function(dt)
        elapsed=elapsed+dt; rot=rot+dt*5
        local a=math.min(elapsed/ET,1); local cr=sr+(er-sr)*a
        for _,d in ipairs(orbs) do
            local p=d.part; if p and p.Parent then
                local ang=d.baseAngle+rot
                p.CFrame=hrp.CFrame*CFrame.new(cr*math.cos(ang),0.5,cr*math.sin(ang))
                p.Transparency=a>0.75 and (a-0.75)*4 or 0
            end
        end
        if a>=1 then
            ec:Disconnect()
            for _,d in ipairs(orbs) do if d.part and d.part.Parent then d.part:Destroy() end end
            if onFinish then onFinish() end
        end
    end)
end

local function flashBracelet()
    local char=LocalPlayer.Character; if not char then return end
    local la=char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("LeftHand")
    if not la then return end
    for _,v in ipairs(la:GetChildren()) do
        if v:IsA("BasePart") and (v.Name=="BloodBracelet" or v.Name=="BraceletOrb") then
            local ot=v.Transparency
            TweenService:Create(v,TweenInfo.new(0.08),{Transparency=0}):Play()
            task.delay(0.08,function() if v and v.Parent then TweenService:Create(v,TweenInfo.new(0.25),{Transparency=ot}):Play() end end)
        end
    end
end

local function flashLightning()
    -- Flash eléctrico en la mano derecha
    local char=LocalPlayer.Character; if not char then return end
    local ra=char:FindFirstChild("Right Arm") or char:FindFirstChild("RightLowerArm") or char:FindFirstChild("RightHand")
    if not ra then return end
    for _,v in ipairs(ra:GetChildren()) do
        if v:IsA("PointLight") then
            local ob=v.Brightness; v.Brightness=ob*8
            task.delay(0.12,function() if v and v.Parent then v.Brightness=ob end end)
        end
    end
end

local cooldownActive={BloodBall=false,BloodCorpuscle=false,BloodWhip=false,Souls1000=false,
    LightningBolt=false,ThunderChain=false,ElectricStorm=false,SupremeDisch=false}

local function startCooldownVisual(skill,dur,overlay,cdLbl)
    cooldownActive[skill]=true
    overlay.Size=UDim2.new(1,0,1,0)
    local st=tick()
    TweenService:Create(overlay,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(1,0,0,0)}):Play()
    task.spawn(function()
        while tick()-st<dur do
            if cdLbl then cdLbl.Text=tostring(math.ceil(dur-(tick()-st))) end
            task.wait(0.1)
        end
        if cdLbl then cdLbl.Text="" end
        overlay.Size=UDim2.new(1,0,0,0)
        cooldownActive[skill]=false
    end)
end

local function spawnLocalBloodSplash(pos,n)
    for i=1,n do
        local p=Instance.new("Part"); p.Size=Vector3.new(0.22,0.22,0.22)
        p.Position=pos+Vector3.new(math.random(-2,2),math.random(0,3),math.random(-2,2))
        p.BrickColor=BrickColor.new("Bright red"); p.Material=Enum.Material.Neon
        p.Shape=Enum.PartType.Ball; p.Anchored=false; p.CanCollide=false; p.CastShadow=false; p.Parent=Workspace
        local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(math.random(-14,14),math.random(8,22),math.random(-14,14)); bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=p
        game:GetService("Debris"):AddItem(p,1.5)
        TweenService:Create(p,TweenInfo.new(1.5,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1,Size=Vector3.new(0.05,0.05,0.05)}):Play()
    end
end

local function spawnLocalLightningSplash(pos,n)
    for i=1,n do
        local p=Instance.new("Part"); p.Size=Vector3.new(0.15,0.15,0.15)
        p.Position=pos+Vector3.new(math.random(-3,3),math.random(0,4),math.random(-3,3))
        p.Color=Color3.fromRGB(180,240,255); p.Material=Enum.Material.Neon
        p.Shape=Enum.PartType.Ball; p.Anchored=false; p.CanCollide=false; p.CastShadow=false; p.Parent=Workspace
        local pl=Instance.new("PointLight"); pl.Color=Color3.fromRGB(100,200,255); pl.Brightness=8; pl.Range=12; pl.Parent=p
        local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(math.random(-20,20),math.random(12,30),math.random(-20,20)); bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=p
        game:GetService("Debris"):AddItem(p,1.0)
        TweenService:Create(p,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1,Size=Vector3.new(0.02,0.02,0.02)}):Play()
    end
end

local function shakeCamera(intensity,duration)
    local st=tick(); local sc
    sc=RunService.RenderStepped:Connect(function()
        local e=tick()-st; if e>duration then sc:Disconnect(); return end
        local f=1-(e/duration)
        Camera.CFrame=Camera.CFrame*CFrame.new(
            (math.random()-0.5)*intensity*f,
            (math.random()-0.5)*intensity*f,
            (math.random()-0.5)*intensity*f
        )
    end)
end

local function playAura(character,duration,color)
    if not character then return end
    local hrp=character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local aura=Instance.new("Part"); aura.Name="Aura"; aura.Size=Vector3.new(6,6,6)
    aura.Shape=Enum.PartType.Ball; aura.CFrame=hrp.CFrame; aura.Color=color or Color3.fromRGB(220,0,0)
    aura.Material=Enum.Material.Neon; aura.Anchored=true; aura.CanCollide=false; aura.CastShadow=false
    aura.Transparency=0.7; aura.Parent=Workspace
    local fc; fc=RunService.RenderStepped:Connect(function()
        if aura and aura.Parent and hrp and hrp.Parent then aura.CFrame=hrp.CFrame else fc:Disconnect() end
    end)
    local em=Instance.new("ParticleEmitter")
    em.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,color or Color3.fromRGB(220,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(20,0,0))}
    em.LightEmission=1; em.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.8),NumberSequenceKeypoint.new(1,0)}
    em.Speed=NumberRange.new(2,8); em.Rate=80; em.Lifetime=NumberRange.new(0.5,1.2); em.Parent=aura
    TweenService:Create(aura,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=0.55,Size=Vector3.new(7,7,7)}):Play()
    task.delay(duration-0.5,function()
        if aura and aura.Parent then
            em.Enabled=false
            TweenService:Create(aura,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=1,Size=Vector3.new(1,1,1)}):Play()
            task.delay(0.5,function() fc:Disconnect(); if aura and aura.Parent then aura:Destroy() end end)
        end
    end)
    task.delay(duration+0.6,function() fc:Disconnect(); if aura and aura.Parent then aura:Destroy() end end)
end

local function slowMotionEffect(duration)
    local blur=Instance.new("BlurEffect"); blur.Size=0; blur.Parent=Camera
    TweenService:Create(blur,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=8}):Play()
    task.delay(duration*0.2,function() TweenService:Create(blur,TweenInfo.new(duration*0.7,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Size=4}):Play() end)
    task.delay(duration,function()
        TweenService:Create(blur,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=0}):Play()
        task.delay(0.4,function() blur:Destroy() end)
    end)
end

local function electricFlashScreen(color,intensity,duration)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,1,0); f.BackgroundColor3=color
    f.BackgroundTransparency=intensity; f.BorderSizePixel=0; f.ZIndex=22; f.Parent=ScreenGui
    TweenService:Create(f,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
    task.delay(duration,function() if f and f.Parent then f:Destroy() end end)
end

local function electricRingExplosion(pos,color)
    color=color or Color3.fromRGB(150,230,255)
    for ring=1,5 do
        task.delay(ring*0.055,function()
            local w=Instance.new("Part"); w.Shape=Enum.PartType.Cylinder
            w.Size=Vector3.new(0.12,ring*1.2,ring*1.2)
            w.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2)
            w.Color=ring<=2 and Color3.fromRGB(220,255,255) or color
            w.Material=Enum.Material.Neon; w.Anchored=true; w.CanCollide=false; w.CastShadow=false
            w.Transparency=0.25; w.Parent=Workspace
            local pl=Instance.new("PointLight"); pl.Color=color; pl.Brightness=12; pl.Range=20; pl.Parent=w
            TweenService:Create(w,TweenInfo.new(0.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                Size=Vector3.new(0.04,28*ring,28*ring),Transparency=1
            }):Play()
            game:GetService("Debris"):AddItem(w,0.8)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  EVENTOS DEL SERVIDOR → CLIENTE
-- ═══════════════════════════════════════════════════════════════

RE_Anim.OnClientEvent:Connect(function(targetPlayer,animName)
    if targetPlayer~=LocalPlayer then return end
    local char=LocalPlayer.Character; if not char then return end
    if not next(DEFAULT_C0) then captureDefaults(char); task.wait(0.4) end
    local mo=getMotors(char); if not mo or not next(mo) then return end
    if     animName=="BloodBall_Pose"      then pose_BloodBall(char)
    elseif animName=="BloodCorpuscle_Pose" then pose_BloodCorpuscle(char)
    elseif animName=="BloodWhip_Pose"      then pose_BloodWhip(char)
    elseif animName=="Souls1000_Pose"      then pose_Souls1000(char)
    elseif animName=="LightningBolt_Pose"  then pose_LightningBolt(char)
    elseif animName=="ThunderChain_Pose"   then pose_ThunderChain(char)
    elseif animName=="ElectricStorm_Pose"  then pose_ElectricStorm(char)
    elseif animName=="SupremeDisch_Pose"   then pose_SupremeDisch(char)
    end
end)

RE_Effect.OnClientEvent:Connect(function(effectName,...)
    local args={...}
    -- ── SANGRE ──────────────────────────────────────────────────
    if effectName=="BloodBall_Cast" then
        local cp=args[1]; if cp and cp.Character then
            playAura(cp.Character,0.6,Color3.fromRGB(220,0,0))
            local la=cp.Character:FindFirstChild("LeftHand") or cp.Character:FindFirstChild("Left Arm")
            if la then
                local p=Instance.new("Part"); p.Size=Vector3.new(0.1,0.1,0.1); p.CFrame=la.CFrame
                p.Anchored=true; p.CanCollide=false; p.Transparency=1; p.CastShadow=false; p.Parent=Workspace
                local pe=Instance.new("ParticleEmitter"); pe.Texture="rbxassetid://122502397357855"
                pe.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,80,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(180,0,0))}
                pe.LightEmission=1; pe.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(1,0)}
                pe.Speed=NumberRange.new(3,9); pe.Rate=0; pe.Lifetime=NumberRange.new(0.2,0.5)
                pe.SpreadAngle=Vector2.new(45,45); pe.RotSpeed=NumberRange.new(-180,180); pe.Parent=p; pe:Emit(30)
                game:GetService("Debris"):AddItem(p,1)
            end
        end
    elseif effectName=="BloodBall_Explode" then
        local pos=args[1]; if pos then
            spawnLocalBloodSplash(pos,22)
            electricFlashScreen(Color3.fromRGB(220,0,0),0.55,0.35)
            for ring=1,4 do task.delay(ring*0.06,function()
                local w=Instance.new("Part"); w.Shape=Enum.PartType.Cylinder
                w.Size=Vector3.new(0.15,ring*1.5,ring*1.5)
                w.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2)
                w.Color=ring<=2 and Color3.fromRGB(255,20,0) or Color3.fromRGB(140,0,0)
                w.Material=Enum.Material.Neon; w.Anchored=true; w.CanCollide=false; w.Transparency=0.3; w.CastShadow=false; w.Parent=Workspace
                TweenService:Create(w,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(0.05,26*ring,26*ring),Transparency=1}):Play()
                game:GetService("Debris"):AddItem(w,0.9)
            end) end
        end
    elseif effectName=="BloodCorpuscle_Start" then
        local cp=args[1]; if cp and cp.Character then playAura(cp.Character,3,Color3.fromRGB(200,0,50)); shakeCamera(0.3,0.5) end
        slowMotionEffect(4)
    elseif effectName=="BloodCorpuscle_Transform" then shakeCamera(0.5,0.8)
    elseif effectName=="Spine_Hit" then
        local pos=args[1]; if pos then spawnLocalBloodSplash(pos,9) end
    elseif effectName=="BloodWhip_Cast" then
        local cp=args[1]; if cp and cp.Character then playAura(cp.Character,8,Color3.fromRGB(180,0,0)) end
        shakeCamera(0.8,0.8); slowMotionEffect(3)
    elseif effectName=="Souls1000_Start" then
        local cp=args[1]; if cp and cp.Character then playAura(cp.Character,5,Color3.fromRGB(160,0,200)) end
        shakeCamera(0.8,1.0); slowMotionEffect(5)
    elseif effectName=="Souls1000_CrystalForm" then
        shakeCamera(0.6,0.8)
        electricFlashScreen(Color3.fromRGB(120,0,200),0.6,0.8)
    elseif effectName=="Souls1000_Launch" then shakeCamera(1.5,1.5)
    elseif effectName=="Souls1000_FinalBlow" then
        local pos=args[1]; shakeCamera(2.5,1.2)
        if pos then spawnLocalBloodSplash(pos,55) end
        electricFlashScreen(Color3.fromRGB(255,150,255),0.2,1.0)
    elseif effectName=="Crystal_Hit" then
        local pos=args[1]; if pos then spawnLocalBloodSplash(pos,7) end
    -- ── RAYO ────────────────────────────────────────────────────
    elseif effectName=="LightningBolt_Cast" then
        local cp=args[1]; if cp and cp.Character then playAura(cp.Character,0.5,Color3.fromRGB(180,240,255)) end
        electricFlashScreen(Color3.fromRGB(200,240,255),0.72,0.12)
        shakeCamera(0.35,0.3)
    elseif effectName=="LightningBolt_Hit" then
        local pos=args[1]; if pos then
            spawnLocalLightningSplash(pos,18)
            electricRingExplosion(pos,Color3.fromRGB(100,200,255))
            electricFlashScreen(Color3.fromRGB(220,255,255),0.45,0.25)
            shakeCamera(0.5,0.4)
        end
    elseif effectName=="ThunderChain_Cast" then
        local cp=args[1]; if cp and cp.Character then playAura(cp.Character,2,Color3.fromRGB(50,180,255)) end
        shakeCamera(0.6,0.6); slowMotionEffect(2)
        electricFlashScreen(Color3.fromRGB(100,200,255),0.60,0.20)
    elseif effectName=="ThunderChain_Hit" then
        local pos=args[1]; if pos then
            spawnLocalLightningSplash(pos,12)
            shakeCamera(0.3,0.3)
        end
    elseif effectName=="ElectricStorm_Cast" then
        local cp=args[1]; if cp and cp.Character then playAura(cp.Character,6,Color3.fromRGB(80,160,255)) end
        shakeCamera(1.0,1.0); slowMotionEffect(6)
        electricFlashScreen(Color3.fromRGB(80,160,255),0.55,0.40)
    elseif effectName=="ElectricStorm_Strike" then
        local pos=args[1]; if pos then
            spawnLocalLightningSplash(pos,10)
            electricRingExplosion(pos,Color3.fromRGB(80,200,255))
            shakeCamera(0.4,0.25)
            electricFlashScreen(Color3.fromRGB(200,240,255),0.68,0.15)
        end
    elseif effectName=="SupremeDisch_Cast" then
        local cp=args[1]; if cp and cp.Character then playAura(cp.Character,4,Color3.fromRGB(0,200,255)) end
        shakeCamera(1.5,1.5); slowMotionEffect(4.5)
        electricFlashScreen(Color3.fromRGB(0,200,255),0.25,0.6)
    elseif effectName=="SupremeDisch_Explode" then
        local pos=args[1]; if pos then
            spawnLocalLightningSplash(pos,60)
            electricRingExplosion(pos,Color3.fromRGB(0,200,255))
            shakeCamera(3.0,1.8)
            electricFlashScreen(Color3.fromRGB(255,255,255),0.0,0.5)
            task.delay(0.08,function() electricFlashScreen(Color3.fromRGB(0,200,255),0.3,0.8) end)
        end
    end
end)

RE_Stun.OnClientEvent:Connect(function(duration)
    isStunnedLocal=true; stunEndTime=tick()+duration
    shakeCamera(0.3,0.5)
    task.delay(duration,function() isStunnedLocal=false end)
end)

RE_Unlock1000.OnClientEvent:Connect(function()
    if not souls1000Button then return end
    souls1000Button.Visible=true
    TweenService:Create(bg4,TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
    electricFlashScreen(Color3.fromRGB(180,0,255),0.3,0.8)
    local ut=Instance.new("TextLabel"); ut.Size=UDim2.new(0.6,0,0.15,0); ut.Position=UDim2.new(0.2,0,0.35,0)
    ut.BackgroundTransparency=1; ut.Text="☠ ¡PODER DESBLOQUEADO!\n1000 ALMAS ☠"; ut.TextScaled=true
    ut.Font=Enum.Font.GothamBold; ut.TextColor3=Color3.fromRGB(200,100,255)
    ut.TextStrokeTransparency=0.2; ut.TextStrokeColor3=Color3.fromRGB(80,0,120); ut.ZIndex=26; ut.Parent=ScreenGui
    TweenService:Create(ut,TweenInfo.new(2.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=1,Position=UDim2.new(0.2,0,0.25,0)}):Play()
    task.delay(2.5,function() if ut and ut.Parent then ut:Destroy() end end)
    shakeCamera(0.5,0.8)
end)

RE_UnlockSupreme.OnClientEvent:Connect(function()
    if not supremeButton then return end
    supremeButton.Visible=true
    TweenService:Create(lbg4,TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
    electricFlashScreen(Color3.fromRGB(0,200,255),0.2,1.0)
    local ut=Instance.new("TextLabel"); ut.Size=UDim2.new(0.7,0,0.15,0); ut.Position=UDim2.new(0.15,0,0.35,0)
    ut.BackgroundTransparency=1; ut.Text="⚡ ¡DESCARGA SUPREMA\nDESBLOQUEADA! ⚡"; ut.TextScaled=true
    ut.Font=Enum.Font.GothamBold; ut.TextColor3=Color3.fromRGB(100,220,255)
    ut.TextStrokeTransparency=0.15; ut.TextStrokeColor3=Color3.fromRGB(0,60,120); ut.ZIndex=26; ut.Parent=ScreenGui
    TweenService:Create(ut,TweenInfo.new(2.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=1,Position=UDim2.new(0.15,0,0.25,0)}):Play()
    task.delay(2.5,function() if ut and ut.Parent then ut:Destroy() end end)
    shakeCamera(0.8,1.0)
end)

-- ═══════════════════════════════════════════════════════════════
--  KEYBINDS — SANGRE
-- ═══════════════════════════════════════════════════════════════
local function fireBloodBall()
    if cooldownActive.BloodBall then return end
    if isStunnedLocal and tick()<stunEndTime then return end
    startCooldownVisual("BloodBall",COOLDOWN.BloodBall,cd1,cdt1)
    epicActivationEffect(Color3.fromRGB(220,0,0),Color3.fromRGB(255,60,0),function()
        flashBracelet(); RE_BloodBall:FireServer()
    end)
end
local function fireBloodCorpuscle()
    if cooldownActive.BloodCorpuscle then return end
    if isStunnedLocal and tick()<stunEndTime then return end
    startCooldownVisual("BloodCorpuscle",COOLDOWN.BloodCorpuscle,cd2,cdt2)
    epicActivationEffect(Color3.fromRGB(180,0,60),Color3.fromRGB(220,0,80),function()
        flashBracelet(); RE_BloodCorpuscle:FireServer()
    end)
end
local function fireBloodWhip()
    if cooldownActive.BloodWhip then return end
    if isStunnedLocal and tick()<stunEndTime then return end
    startCooldownVisual("BloodWhip",COOLDOWN.BloodWhip,cd3,cdt3)
    epicActivationEffect(Color3.fromRGB(200,0,0),Color3.fromRGB(255,20,0),function()
        flashBracelet(); RE_BloodWhip:FireServer()
    end)
end
local function fireSouls1000()
    if not souls1000Button or not souls1000Button.Visible then return end
    if cooldownActive.Souls1000 then return end
    if isStunnedLocal and tick()<stunEndTime then return end
    startCooldownVisual("Souls1000",COOLDOWN.Souls1000,cd4,cdt4)
    epicActivationEffect(Color3.fromRGB(180,0,255),Color3.fromRGB(100,0,200),function()
        flashBracelet(); RE_Souls1000:FireServer()
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  KEYBINDS — RAYO
-- ═══════════════════════════════════════════════════════════════
local function fireLightningBolt()
    if cooldownActive.LightningBolt then return end
    if isStunnedLocal and tick()<stunEndTime then return end
    startCooldownVisual("LightningBolt",COOLDOWN.LightningBolt,lcd1,lcdt1)
    epicActivationEffect(Color3.fromRGB(255,220,0),Color3.fromRGB(200,240,255),function()
        flashLightning(); RE_LightningBolt:FireServer()
    end)
end
local function fireThunderChain()
    if cooldownActive.ThunderChain then return end
    if isStunnedLocal and tick()<stunEndTime then return end
    startCooldownVisual("ThunderChain",COOLDOWN.ThunderChain,lcd2,lcdt2)
    epicActivationEffect(Color3.fromRGB(80,200,255),Color3.fromRGB(150,240,255),function()
        flashLightning(); RE_ThunderChain:FireServer()
    end)
end
local function fireElectricStorm()
    if cooldownActive.ElectricStorm then return end
    if isStunnedLocal and tick()<stunEndTime then return end
    startCooldownVisual("ElectricStorm",COOLDOWN.ElectricStorm,lcd3,lcdt3)
    epicActivationEffect(Color3.fromRGB(200,240,255),Color3.fromRGB(80,160,255),function()
        flashLightning(); RE_ElectricStorm:FireServer()
    end)
end
local function fireSupremeDisch()
    if not supremeButton or not supremeButton.Visible then return end
    if cooldownActive.SupremeDisch then return end
    if isStunnedLocal and tick()<stunEndTime then return end
    startCooldownVisual("SupremeDisch",COOLDOWN.SupremeDisch,lcd4,lcdt4)
    epicActivationEffect(Color3.fromRGB(0,200,255),Color3.fromRGB(255,255,255),function()
        flashLightning(); RE_SupremeDisch:FireServer()
    end)
end

-- ─── TECLADO ──────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input,gameProcessed)
    if gameProcessed then return end
    if selectedPower=="Blood" then
        if     input.KeyCode==Enum.KeyCode.Q then fireBloodBall()
        elseif input.KeyCode==Enum.KeyCode.E then fireBloodCorpuscle()
        elseif input.KeyCode==Enum.KeyCode.R then fireBloodWhip()
        elseif input.KeyCode==Enum.KeyCode.F then fireSouls1000()
        end
    elseif selectedPower=="Lightning" then
        if     input.KeyCode==Enum.KeyCode.Q then fireLightningBolt()
        elseif input.KeyCode==Enum.KeyCode.E then fireThunderChain()
        elseif input.KeyCode==Enum.KeyCode.R then fireElectricStorm()
        elseif input.KeyCode==Enum.KeyCode.F then fireSupremeDisch()
        end
    end
end)

-- ─── BOTONES TÁCTILES ─────────────────────────────────────────
local function setupTouchButton(bgFrame,actionFunc)
    bgFrame.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            TweenService:Create(bgFrame,TweenInfo.new(0.08,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,72,0,72),Position=UDim2.new(0.5,-36,0,4)}):Play()
            task.delay(0.1,function()
                TweenService:Create(bgFrame,TweenInfo.new(0.12,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,80,0,80),Position=UDim2.new(0.5,-40,0,0)}):Play()
            end)
            actionFunc()
        end
    end)
end

-- Sangre
setupTouchButton(bg1,fireBloodBall)
setupTouchButton(bg2,fireBloodCorpuscle)
setupTouchButton(bg3,fireBloodWhip)
setupTouchButton(bg4,fireSouls1000)
-- Rayo
setupTouchButton(lbg1,fireLightningBolt)
setupTouchButton(lbg2,fireThunderChain)
setupTouchButton(lbg3,fireElectricStorm)
setupTouchButton(lbg4,fireSupremeDisch)

-- ─── PULSO DE BORDE ANIMADO ────────────────────────────────────
task.spawn(function()
    local bloodStrokes={stroke1,stroke2,stroke3}
    local lightStrokes={lstroke1,lstroke2,lstroke3}
    while true do
        for _,s in ipairs(bloodStrokes) do if s and s.Parent then TweenService:Create(s,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Thickness=3.5}):Play() end end
        for _,s in ipairs(lightStrokes) do if s and s.Parent then TweenService:Create(s,TweenInfo.new(0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Thickness=3.8}):Play() end end
        task.wait(1)
        for _,s in ipairs(bloodStrokes) do if s and s.Parent then TweenService:Create(s,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Thickness=1.5}):Play() end end
        for _,s in ipairs(lightStrokes) do if s and s.Parent then TweenService:Create(s,TweenInfo.new(0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Thickness=1.8}):Play() end end
        task.wait(1)
    end
end)

-- ─── CAPTURA DEFAULTS AL SPAWN ────────────────────────────────
local function onCharacterAdded(char)
    char:WaitForChild("HumanoidRootPart",10)
    task.wait(0.5); captureDefaults(char)
end
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

print("[Powers] LocalScript cargado correctamente ✓")
