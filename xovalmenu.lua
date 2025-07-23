```lua
-- Подключаем сервисы Roblox
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Состояние меню
local guiOpen = false
local currentTab = "Главная"
local settingsOpen = false
local isDragging = false
local dragStart, startPos

-- Конфигурация
local config = {
    menuColor = Color3.fromRGB(30, 30, 30), -- Цвет фона меню
    accentColor = Color3.fromRGB(0, 170, 255), -- Акцентный цвет
    animationType = "SlideFade", -- Тип анимации
    animationSpeed = 0.3, -- Скорость анимации
    espEnabled = false, -- Включён ли ESP
    aimbotEnabled = false, -- Включён ли аимбот
    killAuraEnabled = false, -- Включена ли килл-аура
    autoFarm = false, -- Включён ли автофарм монет
    speedHack = 16, -- Скорость персонажа
    espColor = Color3.fromRGB(255, 0, 0), -- Цвет ESP
    espTransparency = 0.5, -- Прозрачность ESP
    noclip = false, -- Включён ли ноклип
    godMode = false, -- Включён ли режим бога
    murdererFeatures = false, -- Функции для мардера
    sheriffFeatures = false, -- Функции для шерифа
    teleportEnabled = false, -- Включён ли телепорт
    teleportSpeed = 200, -- Скорость телепорта
    knifeAuraRange = 15, -- Радиус ауры ножа
    gunAuraRange = 20 -- Радиус ауры пистолета
}

-- Сохранение/загрузка конфигурации
local function saveConfig()
    if writefile then
        local success, err = pcall(function()
            local json = HttpService:JSONEncode(config)
            writefile("XovalMM2ProConfig.json", json)
        end)
        if not success then
            warn("[XOVAL] Ошибка сохранения конфигурации: " .. err)
        end
    else
        warn("[XOVAL] Функция writefile не поддерживается")
    end
end

local function loadConfig()
    if readfile and isfile and isfile("XovalMM2ProConfig.json") then
        local success, result = pcall(function()
            local json = readfile("XovalMM2ProConfig.json")
            return HttpService:JSONDecode(json)
        end)
        if success then
            for k, v in pairs(result) do
                config[k] = v
            end
        else
            warn("[XOVAL] Ошибка загрузки конфигурации: " .. result)
        end
    end
end

loadConfig()

-- Создание интерфейса
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XovalMM2Pro"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false
screenGui.Enabled = true

-- Главный фрейм (перетаскиваемый)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 550)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -275)
mainFrame.BackgroundColor3 = config.menuColor
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui
local uICorner = Instance.new("UICorner", mainFrame)
uICorner.CornerRadius = UDim.new(0, 12)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Color = config.accentColor
uiStroke.Thickness = 2

-- Перетаскивание
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

-- Верхняя панель
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BorderSizePixel = 0
local topCorner = Instance.new("UICorner", topBar)
topCorner.CornerRadius = UDim.new(0, 12)

-- Заголовок
local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(0.5, 0, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "XOVAL MM2 PRO"
title.TextColor3 = config.accentColor
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0, 10)

-- Система вкладок
local tabHolder = Instance.new("Frame", mainFrame)
tabHolder.Size = UDim2.new(0, 120, 1, -60)
tabHolder.Position = UDim2.new(0, 10, 0, 60)
tabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tabHolder.BorderSizePixel = 0
local tabHolderCorner = Instance.new("UICorner", tabHolder)
tabHolderCorner.CornerRadius = UDim.new(0, 10)

local tabLayout = Instance.new("UIListLayout", tabHolder)
tabLayout.Padding = UDim.new(0, 5)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

local tabs = {"Главная", "Бой", "Визуалы", "Мардер", "Шериф", "Настройки"}
local tabFrames = {}
local tabButtons = {}

for i, tabName in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton", tabHolder)
    tabBtn.Size = UDim2.new(1, -10, 0, 50)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabBtn.TextColor3 = currentTab == tabName and config.accentColor or Color3.fromRGB(200, 200, 200)
    tabBtn.Text = tabName
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.TextSize = 16
    local tabCorner = Instance.new("UICorner", tabBtn)
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabButtons[tabName] = tabBtn

    local tabFrame = Instance.new("ScrollingFrame", mainFrame)
    tabFrame.Size = UDim2.new(1, -150, 1, -80)
    tabFrame.Position = UDim2.new(0, 140, 0, 60)
    tabFrame.BackgroundTransparency = 1
    tabFrame.ScrollBarThickness = 4
    tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabFrame.Visible = tabName == "Главная"
    tabFrames[tabName] = tabFrame

    local listLayout = Instance.new("UIListLayout", tabFrame)
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
end

-- Нижняя панель
local footer = Instance.new("TextLabel", mainFrame)
footer.Size = UDim2.new(1, 0, 0, 20)
footer.Position = UDim2.new(0, 0, 1, -20)
footer.BackgroundTransparency = 1
footer.Text = "Переключение: Insert | Создано XOVAL Team"
footer.TextColor3 = Color3.fromRGB(100, 100, 100)
footer.Font = Enum.Font.Gotham
footer.TextSize = 12

-- Фрейм настроек
local settingsFrame = Instance.new("Frame", screenGui)
settingsFrame.Size = UDim2.new(0, 400, 0, 500)
settingsFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
settingsFrame.BackgroundColor3 = config.menuColor
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
local settingsCorner = Instance.new("UICorner", settingsFrame)
settingsCorner.CornerRadius = UDim.new(0, 12)
local settingsStroke = Instance.new("UIStroke", settingsFrame)
settingsStroke.Color = config.accentColor
settingsStroke.Thickness = 2

-- Верхняя панель настроек
local settingsTopBar = Instance.new("Frame", settingsFrame)
settingsTopBar.Size = UDim2.new(1, 0, 0, 50)
settingsTopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
settingsTopBar.BorderSizePixel = 0
local settingsTopCorner = Instance.new("UICorner", settingsTopBar)
settingsTopCorner.CornerRadius = UDim.new(0, 12)

-- Заголовок настроек
local settingsTitle = Instance.new("TextLabel", settingsTopBar)
settingsTitle.Size = UDim2.new(0.7, 0, 1, 0)
settingsTitle.Position = UDim2.new(0, 15, 0, 0)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "Настройки"
settingsTitle.TextColor3 = config.accentColor
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 20
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопка закрытия настроек
local settingsCloseBtn = Instance.new("TextButton", settingsTopBar)
settingsCloseBtn.Size = UDim2.new(0, 40, 0, 40)
settingsCloseBtn.Position = UDim2.new(1, -50, 0, 5)
settingsCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
settingsCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsCloseBtn.Text = "X"
settingsCloseBtn.Font = Enum.Font.GothamBold
settingsCloseBtn.TextSize = 18
local settingsCloseCorner = Instance.new("UICorner", settingsCloseBtn)
settingsCloseCorner.CornerRadius = UDim.new(0, 10)

-- Контент настроек
local settingsScroll = Instance.new("ScrollingFrame", settingsFrame)
settingsScroll.Size = UDim2.new(1, -20, 1, -70)
settingsScroll.Position = UDim2.new(0, 10, 0, 60)
settingsScroll.BackgroundTransparency = 1
settingsScroll.ScrollBarThickness = 4
settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local settingsLayout = Instance.new("UIListLayout", settingsScroll)
settingsLayout.Padding = UDim.new(0, 10)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Палитра цветов
local colorPresets = {
    {Name = "Неоновый синий", Color = Color3.fromRGB(0, 170, 255)},
    {Name = "Красный", Color = Color3.fromRGB(220, 20, 60)},
    {Name = "Лаймовый", Color = Color3.fromRGB(50, 205, 50)},
    {Name = "Фиолетовый", Color = Color3.fromRGB(138, 43, 226)},
    {Name = "Янтарный", Color = Color3.fromRGB(255, 191, 0)}
}

local colorLabel = Instance.new("TextLabel", settingsScroll)
colorLabel.Size = UDim2.new(1, 0, 0, 30)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "Акцентный цвет"
colorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
colorLabel.Font = Enum.Font.Gotham
colorLabel.TextSize = 16
colorLabel.TextXAlignment = Enum.TextXAlignment.Left

local colorHolder = Instance.new("Frame", settingsScroll)
colorHolder.Size = UDim2.new(1, 0, 0, 40)
colorHolder.BackgroundTransparency = 1
local colorLayout = Instance.new("UIListLayout", colorHolder)
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.Padding = UDim.new(0, 8)

for _, preset in ipairs(colorPresets) do
    local colorBtn = Instance.new("TextButton", colorHolder)
    colorBtn.Size = UDim2.new(0, 60, 0, 30)
    colorBtn.BackgroundColor3 = preset.Color
    colorBtn.Text = preset.Name
    colorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorBtn.Font = Enum.Font.Gotham
    colorBtn.TextSize = 12
    local btnCorner = Instance.new("UICorner", colorBtn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    colorBtn.MouseButton1Click:Connect(function()
        config.accentColor = preset.Color
        title.TextColor3 = preset.Color
        uiStroke.Color = preset.Color
        settingsStroke.Color = preset.Color
        settingsTitle.TextColor3 = preset.Color
        for _, btn in pairs(tabButtons) do
            btn.TextColor3 = currentTab == btn.Text and preset.Color or Color3.fromRGB(200, 200, 200)
        end
        saveConfig()
    end)
end

-- Каталог анимаций
local animationTypes = {
    "SlideFade",
    "PopIn",
    "SlideLeft",
    "SlideDown",
    "FadeOnly",
    "Elastic"
}

local animLabel = Instance.new("TextLabel", settingsScroll)
animLabel.Size = UDim2.new(1, 0, 0, 30)
animLabel.BackgroundTransparency = 1
animLabel.Text = "Тип анимации"
animLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
animLabel.Font = Enum.Font.Gotham
animLabel.TextSize = 16
animLabel.TextXAlignment = Enum.TextXAlignment.Left

local animDropdown = Instance.new("TextButton", settingsScroll)
animDropdown.Size = UDim2.new(1, 0, 0, 40)
animDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
animDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
animDropdown.Text = config.animationType
animDropdown.Font = Enum.Font.Gotham
animDropdown.TextSize = 16
local animCorner = Instance.new("UICorner", animDropdown)
animCorner.CornerRadius = UDim.new(0, 8)

local animDropdownFrame = Instance.new("Frame", settingsScroll)
animDropdownFrame.Size = UDim2.new(1, 0, 0, #animationTypes * 40)
animDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
animDropdownFrame.Visible = false
local animDropdownCorner = Instance.new("UICorner", animDropdownFrame)
animDropdownCorner.CornerRadius = UDim.new(0, 8)
local animDropdownLayout = Instance.new("UIListLayout", animDropdownFrame)
animDropdownLayout.Padding = UDim.new(0, 5)

for _, anim in ipairs(animationTypes) do
    local animOption = Instance.new("TextButton", animDropdownFrame)
    animOption.Size = UDim2.new(1, -10, 0, 35)
    animOption.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    animOption.TextColor3 = Color3.fromRGB(255, 255, 255)
    animOption.Text = anim
    animOption.Font = Enum.Font.Gotham
    animOption.TextSize = 14
    local optionCorner = Instance.new("UICorner", animOption)
    optionCorner.CornerRadius = UDim.new(0, 6)
    animOption.MouseButton1Click:Connect(function()
        config.animationType = anim
        animDropdown.Text = anim
        animDropdownFrame.Visible = false
        saveConfig()
    end)
end

animDropdown.MouseButton1Click:Connect(function()
    animDropdownFrame.Visible = not animDropdownFrame.Visible
end)

-- Слайдер скорости анимации
local speedLabel = Instance.new("TextLabel", settingsScroll)
speedLabel.Size = UDim2.new(1, 0, 0, 30)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Скорость анимации: " .. string.format("%.2f", config.animationSpeed) .. "с"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 16
speedLabel.TextXAlignment = Enum.TextXAlignment.Left

local speedSlider = Instance.new("Frame", settingsScroll)
speedSlider.Size = UDim2.new(1, 0, 0, 20)
speedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local speedCorner = Instance.new("UICorner", speedSlider)
speedCorner.CornerRadius = UDim.new(0, 10)

local speedKnob = Instance.new("Frame", speedSlider)
speedKnob.Size = UDim2.new(0, 20, 1, 0)
speedKnob.BackgroundColor3 = config.accentColor
speedKnob.Position = UDim2.new((config.animationSpeed - 0.2) / 0.8, 0, 0, 0)
local knobCorner = Instance.new("UICorner", speedKnob)
knobCorner.CornerRadius = UDim.new(0, 10)

speedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local function updateSlider()
            local mouseX = UserInputService:GetMouseLocation().X
            local relativeX = math.clamp((mouseX - speedSlider.AbsolutePosition.X) / speedSlider.AbsoluteSize.X, 0, 1)
            config.animationSpeed = 0.2 + (relativeX * 0.8)
            speedKnob.Position = UDim2.new(relativeX, 0, 0, 0)
            speedLabel.Text = "Скорость анимации: " .. string.format("%.2f", config.animationSpeed) .. "с"
            saveConfig()
        end
        local conn
        conn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider()
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                conn:Disconnect()
            end
        end)
    end
end)

-- Кнопка выгрузки
local unloadBtn = Instance.new("TextButton", settingsScroll)
unloadBtn.Size = UDim2.new(1, 0, 0, 50)
unloadBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
unloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unloadBtn.Text = "Выгрузить чит"
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.TextSize = 20
local unloadUICorner = Instance.new("UICorner", unloadBtn)
unloadUICorner.CornerRadius = UDim.new(0, 15)

unloadBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    print("[XOVAL MM2 PRO] Чит выгружен")
end)

-- Анимации
local function animateOpen(frame)
    frame.Visible = true
    local tweenInfo = TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if config.animationType == "SlideFade" then
        frame.Position = UDim2.new(0.5, -250, 1.5, -275)
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -250, 0.5, -275), BackgroundTransparency = 0}):Play()
    elseif config.animationType == "PopIn" then
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 500, 0, 550)}):Play()
    elseif config.animationType == "SlideLeft" then
        frame.Position = UDim2.new(-0.5, -250, 0.5, -275)
        TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -250, 0.5, -275)}):Play()
    elseif config.animationType == "SlideDown" then
        frame.Position = UDim2.new(0.5, -250, -0.5, -275)
        TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -250, 0.5, -275)}):Play()
    elseif config.animationType == "FadeOnly" then
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0}):Play()
    elseif config.animationType == "Elastic" then
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 500, 0, 550)}):Play()
    end
end

local function animateClose(frame)
    local tweenInfo = TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tween
    if config.animationType == "SlideFade" then
        tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -250, 1.5, -275), BackgroundTransparency = 1})
    elseif config.animationType == "PopIn" then
        tween = TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
    elseif config.animationType == "SlideLeft" then
        tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(-0.5, -250, 0.5, -275)})
    elseif config.animationType == "SlideDown" then
        tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -250, -0.5, -275)})
    elseif config.animationType == "FadeOnly" then
        tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 1})
    elseif config.animationType == "Elastic" then
        tween = TweenService:Create(frame, TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 0, 0, 0)})
    end
    tween:Play()
    tween.Completed:Wait()
    frame.Visible = false
end

-- Переключение вкладок
for tabName, tabBtn in pairs(tabButtons) do
    tabBtn.MouseButton1Click:Connect(function()
        currentTab = tabName
        for name, frame in pairs(tabFrames) do
            frame.Visible = name == tabName
        end
        for name, btn in pairs(tabButtons) do
            btn.TextColor3 = name == tabName and config.accentColor or Color3.fromRGB(200, 200, 200)
        end
    end)
end

-- Переключение меню
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        guiOpen = not guiOpen
        if guiOpen then
            animateOpen(mainFrame)
            settingsFrame.Visible = false
            settingsOpen = false
        else
            if settingsOpen then
                animateClose(settingsFrame)
                settingsOpen = false
            end
            animateClose(mainFrame)
        end
    end
end)

-- Закрытие меню
closeBtn.MouseButton1Click:Connect(function()
    guiOpen = false
    animateClose(mainFrame)
end)

settingsCloseBtn.MouseButton1Click:Connect(function()
    settingsOpen = false
    animateClose(settingsFrame)
    animateOpen(mainFrame)
end)

-- Открытие настроек
tabButtons.Настройки.MouseButton1Click:Connect(function()
    settingsOpen = true
    animateOpen(settingsFrame)
    animateClose(mainFrame)
end)

-- Утилиты
local function createToggle(tab, name, configKey)
    local toggleFrame = Instance.new("Frame", tabFrames[tab])
    toggleFrame.Size = UDim2.new(1, 0, 0, 40)
    toggleFrame.BackgroundTransparency = 1

    local toggleBtn = Instance.new("TextButton", toggleFrame)
    toggleBtn.Size = UDim2.new(0, 60, 0, 30)
    toggleBtn.Position = UDim2.new(1, -70, 0, 5)
    toggleBtn.BackgroundColor3 = config[configKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Text = config[configKey] and "ВКЛ" or "ВЫКЛ"
    toggleBtn.Font = Enum.Font.Gotham
    toggleBtn.TextSize = 14
    local toggleCorner = Instance.new("UICorner", toggleBtn)
    toggleCorner.CornerRadius = UDim.new(0, 8)

    local toggleLabel = Instance.new("TextLabel", toggleFrame)
    toggleLabel.Size = UDim2.new(0.8, 0, 1, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = name
    toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextSize = 16
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left

    toggleBtn.MouseButton1Click:Connect(function()
        config[configKey] = not config[configKey]
        toggleBtn.BackgroundColor3 = config[configKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        toggleBtn.Text = config[configKey] and "ВКЛ" or "ВЫКЛ"
        saveConfig()
    end)
end

local function createSlider(tab, name, configKey, min, max, default)
    local sliderFrame = Instance.new("Frame", tabFrames[tab])
    sliderFrame.Size = UDim2.new(1, 0, 0, 60)
    sliderFrame.BackgroundTransparency = 1

    local sliderLabel = Instance.new("TextLabel", sliderFrame)
    sliderLabel.Size = UDim2.new(1, 0, 0, 30)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = name .. ": " .. config[configKey]
    sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextSize = 16
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left

    local slider = Instance.new("Frame", sliderFrame)
    slider.Size = UDim2.new(1, 0, 0, 20)
    slider.Position = UDim2.new(0, 0, 0, 30)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    local sliderCorner = Instance.new("UICorner", slider)
    sliderCorner.CornerRadius = UDim.new(0, 10)

    local sliderKnob = Instance.new("Frame", slider)
    sliderKnob.Size = UDim2.new(0, 20, 1, 0)
    sliderKnob.BackgroundColor3 = config.accentColor
    sliderKnob.Position = UDim2.new((config[configKey] - min) / (max - min), 0, 0, 0)
    local knobCorner = Instance.new("UICorner", sliderKnob)
    knobCorner.CornerRadius = UDim.new(0, 10)

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local function updateSlider()
                local mouseX = UserInputService:GetMouseLocation().X
                local relativeX = math.clamp((mouseX - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                config[configKey] = math.floor(min + (relativeX * (max - min)))
                sliderKnob.Position = UDim2.new(relativeX, 0, 0, 0)
                sliderLabel.Text = name .. ": " .. config[configKey]
                saveConfig()
            end
            local conn
            conn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    conn:Disconnect()
                end
            end)
        end
    end)
end

-- Вкладка "Главная"
local welcomeLabel = Instance.new("TextLabel", tabFrames["Главная"])
welcomeLabel.Size = UDim2.new(1, 0, 0, 100)
welcomeLabel.BackgroundTransparency = 1
welcomeLabel.Text = "Добро пожаловать в XOVAL MM2 PRO\nПродвинутый чит для Murder Mystery 2\nПереключение меню: Insert"
welcomeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
welcomeLabel.Font = Enum.Font.Gotham
welcomeLabel.TextSize = 16
welcomeLabel.TextWrapped = true
welcomeLabel.TextYAlignment = Enum.TextYAlignment.Top

createToggle("Главная", "Автофарм монет", "autoFarm")

-- Кнопка телепорта
local teleportBtn = Instance.new("TextButton", tabFrames["Главная"])
teleportBtn.Size = UDim2.new(1, 0, 0, 50)
teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Text = "Телепорт к игроку"
teleportBtn.Font = Enum.Font.GothamBold
teleportBtn.TextSize = 18
local teleportCorner = Instance.new("UICorner", teleportBtn)
teleportCorner.CornerRadius = UDim.new(0, 10)

local teleportDropdown = Instance.new("Frame", tabFrames["Главная"])
teleportDropdown.Size = UDim2.new(1, 0, 0, 0)
teleportDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
teleportDropdown.Visible = false
local teleportDropdownCorner = Instance.new("UICorner", teleportDropdown)
teleportDropdownCorner.CornerRadius = UDim.new(0, 8)
local teleportLayout = Instance.new("UIListLayout", teleportDropdown)
teleportLayout.Padding = UDim.new(0, 5)

local function updateTeleportDropdown()
    for _, child in ipairs(teleportDropdown:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    teleportDropdown.Size = UDim2.new(1, 0, 0, #Players:GetPlayers() * 40)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local playerBtn = Instance.new("TextButton", teleportDropdown)
            playerBtn.Size = UDim2.new(1, -10, 0, 35)
            playerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerBtn.Text = player.Name
            playerBtn.Font = Enum.Font.Gotham
            playerBtn.TextSize = 14
            local btnCorner = Instance.new("UICorner", playerBtn)
            btnCorner.CornerRadius = UDim.new(0, 6)
            playerBtn.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
                else
                    warn("[XOVAL] Не удалось телепортироваться к " .. player.Name)
                end
                teleportDropdown.Visible = false
            end)
        end
    end
end

Players.PlayerAdded:Connect(updateTeleportDropdown)
Players.PlayerRemoving:Connect(updateTeleportDropdown)
updateTeleportDropdown()

teleportBtn.MouseButton1Click:Connect(function()
    teleportDropdown.Visible = not teleportDropdown.Visible
end)

-- Вкладка "Бой"
createToggle("Бой", "Аимбот", "aimbotEnabled")
createToggle("Бой", "Килл-аура", "killAuraEnabled")
createToggle("Бой", "Ноклип", "noclip")
createToggle("Бой", "Режим бога", "godMode")
createSlider("Бой", "Скорость персонажа", "speedHack", 16, 100, 16)

-- Вкладка "Визуалы"
createToggle("Визуалы", "ESP игроков", "espEnabled")

local espColorLabel = Instance.new("TextLabel", tabFrames["Визуалы"])
espColorLabel.Size = UDim2.new(1, 0, 0, 30)
espColorLabel.BackgroundTransparency = 1
espColorLabel.Text = "Цвет ESP"
espColorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
espColorLabel.Font = Enum.Font.Gotham
espColorLabel.TextSize = 16
espColorLabel.TextXAlignment = Enum.TextXAlignment.Left

local espColorHolder = Instance.new("Frame", tabFrames["Визуалы"])
espColorHolder.Size = UDim2.new(1, 0, 0, 40)
espColorHolder.BackgroundTransparency = 1
local espColorLayout = Instance.new("UIListLayout", espColorHolder)
espColorLayout.FillDirection = Enum.FillDirection.Horizontal
espColorLayout.Padding = UDim.new(0, 8)

for _, preset in ipairs(colorPresets) do
    local espColorBtn = Instance.new("TextButton", espColorHolder)
    espColorBtn.Size = UDim2.new(0, 60, 0, 30)
    espColorBtn.BackgroundColor3 = preset.Color
    espColorBtn.Text = preset.Name
    espColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espColorBtn.Font = Enum.Font.Gotham
    espColorBtn.TextSize = 12
    local btnCorner = Instance.new("UICorner", espColorBtn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    espColorBtn.MouseButton1Click:Connect(function()
        config.espColor = preset.Color
        saveConfig()
    end)
end

createSlider("Визуалы", "Прозрачность ESP", "espTransparency", 0, 1, 0.5)

-- Вкладка "Мардер"
createToggle("Мардер", "Аура ножа", "murdererFeatures")
createSlider("Мардер", "Радиус ауры ножа", "knifeAuraRange", 5, 30, 15)

-- Вкладка "Шериф"
createToggle("Шериф", "Аура пистолета", "sheriffFeatures")
createSlider("Шериф", "Радиус ауры пистолета", "gunAuraRange", 10, 50, 20)

-- Реализация ESP
local espCache = {}
local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if config.espEnabled then
                if not espCache[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = player.Character
                    highlight.Adornee = player.Character
                    highlight.FillColor = config.espColor
                    highlight.OutlineColor = config.espColor
                    highlight.FillTransparency = config.espTransparency
                    highlight.OutlineTransparency = 0
                    espCache[player] = highlight
                else
                    espCache[player].FillColor = config.espColor
                    espCache[player].OutlineColor = config.espColor
                    espCache[player].FillTransparency = config.espTransparency
                end
            else
                if espCache[player] then
                    espCache[player]:Destroy()
                    espCache[player] = nil
                end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    if espCache[player] then
        espCache[player]:Destroy()
        espCache[player] = nil
    end
end)

-- Реализация аимбота
local function getClosestPlayer()
    local closest, dist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if distance < dist then
                    closest = player
                    dist = distance
                end
            end
        end
    end
    return closest
end

-- Определение роли
local function getPlayerRole()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    if (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) then
        return "Murderer"
    elseif (backpack and backpack:FindFirstChild("Gun")) or (character and character:FindFirstChild("Gun")) then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- Аура ножа для мардера
local function knifeAura()
    if not config.murdererFeatures or getPlayerRole() ~= "Murderer" then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local tool = character:FindFirstChild("Knife") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Knife"))
    if tool then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                if distance <= config.knifeAuraRange then
                    local remote = tool:FindFirstChildOfClass("RemoteEvent")
                    if remote then
                        pcall(function()
                            remote:FireServer(player.Character.Humanoid)
                        end)
                    end
                end
            end
        end
    end
end

-- Аура пистолета для шерифа
local function gunAura()
    if not config.sheriffFeatures or getPlayerRole() ~= "Sheriff" then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local tool = character:FindFirstChild("Gun") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Gun"))
    if tool then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                if distance <= config.gunAuraRange then
                    local remote = tool:FindFirstChildOfClass("RemoteEvent")
                    if remote then
                        pcall(function()
                            remote:FireServer(player.Character.Humanoid)
                        end)
                    end
                end
            end
        end
    end
end

-- Автофарм монет
local function autoFarm()
    if not config.autoFarm then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    for _, coin in ipairs(Workspace:GetDescendants()) do
        if coin.Name == "Coin" and coin:IsA("BasePart") then
            character.HumanoidRootPart.CFrame = coin.CFrame
            wait(0.1)
        end
    end
end

-- Ноклип
local function noClip()
    if not config.noclip then return end
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

-- Режим бога
local function godMode()
    if not config.godMode then return end
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.Health = 100
    end
end

-- Скорость персонажа
local function updateSpeed()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = config.speedHack
    end
end

-- Основной цикл
RunService.RenderStepped:Connect(function()
    pcall(function()
        if config.espEnabled then
            updateESP()
        end
        if config.aimbotEnabled then
            local closest = getClosestPlayer()
            if closest and closest.Character and closest.Character:FindFirstChild("Head") then
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, closest.Character.Head.Position)
            end
        end
        knifeAura()
        gunAura()
        autoFarm()
        noClip()
        godMode()
        updateSpeed()
    end)
end)

print("[XOVAL MM2 PRO] Чит успешно загружен")
```
