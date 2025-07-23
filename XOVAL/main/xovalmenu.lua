-- Подключение сервисов Roblox для работы с игрой
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Состояние интерфейса
local guiOpen = false -- Флаг, показывающий, открыто ли меню
local currentTab = "Главная" -- Текущая активная вкладка
local settingsOpen = false -- Флаг окна настроек
local isDragging = false -- Флаг перетаскивания меню
local dragStart, startPos -- Переменные для перетаскивания
local notificationQueue = {} -- Очередь уведомлений

-- Конфигурация чита
local config = {
    menuColor = Color3.fromRGB(30, 30, 30), -- Основной цвет меню
    accentColor = Color3.fromRGB(0, 170, 255), -- Акцентный цвет
    useGradient = true, -- Использовать градиент для меню
    gradientColor1 = Color3.fromRGB(0, 120, 255), -- Начало градиента
    gradientColor2 = Color3.fromRGB(0, 255, 200), -- Конец градиента
    animationType = "SlideFade", -- Тип анимации меню
    animationSpeed = 0.3, -- Скорость анимации (в секундах)
    espEnabled = false, -- Включён ли ESP
    espMurdererColor = Color3.fromRGB(255, 0, 0), -- Цвет ESP для мардера
    espSheriffColor = Color3.fromRGB(0, 0, 255), -- Цвет ESP для шерифа
    espInnocentColor = Color3.fromRGB(0, 255, 0), -- Цвет ESP для мирных
    espTransparency = 0.5, -- Прозрачность ESP
    espShowNames = true, -- Показывать имена игроков
    espShowRoles = true, -- Показывать роли игроков
    aimbotEnabled = false, -- Включён ли аимбот
    aimbotFOV = 100, -- Поле зрения аимбота
    killAuraEnabled = false, -- Включена ли килл-аура
    autoFarm = false, -- Включён ли автофарм монет
    speedHack = 16, -- Скорость персонажа
    noclip = false, -- Включён ли ноклип
    godMode = false, -- Включён ли режим бога
    murdererFeatures = false, -- Функции для мардера
    sheriffFeatures = false, -- Функции для шерифа
    knifeAuraRange = 15, -- Радиус ауры ножа
    gunAuraRange = 20, -- Радиус ауры пистолета
    teleportEnabled = false, -- Включён ли телепорт
    teleportSpeed = 200, -- Скорость телепорта
    autoKnifeThrow = false, -- Автоматический бросок ножа (мардер)
    autoShoot = false, -- Автоматическая стрельба (шериф)
    visualEffects = true, -- Включены ли визуальные эффекты (например, частицы)
    notificationDuration = 3 -- Длительность уведомлений (в секундах)
}

-- Сохранение конфигурации
local function saveConfig()
    local success, err = pcall(function()
        if writefile then
            local json = HttpService:JSONEncode(config)
            writefile("XovalConfig.json", json)
            print("[XOVAL] Конфигурация сохранена")
        else
            warn("[XOVAL] Функция writefile не поддерживается")
        end
    end)
    if not success then
        warn("[XOVAL] Ошибка сохранения конфигурации: " .. err)
    end
end

-- Загрузка конфигурации
local function loadConfig()
    local success, result = pcall(function()
        if readfile and isfile and isfile("XovalConfig.json") then
            local json = readfile("XovalConfig.json")
            return HttpService:JSONDecode(json)
        end
    end)
    if success and result then
        for k, v in pairs(result) do
            config[k] = v
        end
        print("[XOVAL] Конфигурация загружена")
    else
        warn("[XOVAL] Не удалось загрузить конфигурацию")
    end
end

loadConfig()

-- Создание уведомлений
local function createNotification(message, color)
    table.insert(notificationQueue, {text = message, color = color or Color3.fromRGB(255, 255, 255)})
    if #notificationQueue > 5 then
        table.remove(notificationQueue, 1)
    end

    local notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(0, 300, 0, 50)
    notificationFrame.Position = UDim2.new(1, -310, 1, -60 - (#notificationQueue - 1) * 60)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = screenGui
    local corner = Instance.new("UICorner", notificationFrame)
    corner.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", notificationFrame)
    stroke.Color = config.accentColor
    stroke.Thickness = 1

    local label = Instance.new("TextLabel", notificationFrame)
    label.Size = UDim2.new(1, -20, 1, -10)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left

    local tweenInfo = TweenInfo.new(config.notificationDuration, Enum.EasingStyle.Linear)
    TweenService:Create(notificationFrame, tweenInfo, {BackgroundTransparency = 1, Position = UDim2.new(1, -310, 1, -60 - (#notificationQueue - 1) * 60)}):Play()
    TweenService:Create(label, tweenInfo, {TextTransparency = 1}):Play()
    wait(config.notificationDuration)
    notificationFrame:Destroy()
end

-- Создание интерфейса
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Xoval"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false
screenGui.Enabled = true

-- Главный фрейм (перетаскиваемый)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 550, 0, 600)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -300)
mainFrame.BackgroundColor3 = config.menuColor
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui
local uICorner = Instance.new("UICorner", mainFrame)
uICorner.CornerRadius = UDim.new(0, 12)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Color = config.accentColor
uiStroke.Thickness = 2
local gradient = Instance.new("UIGradient", mainFrame)
gradient.Enabled = config.useGradient
gradient.Color = ColorSequence.new(config.gradientColor1, config.gradientColor2)

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
local topGradient = Instance.new("UIGradient", topBar)
topGradient.Enabled = config.useGradient
topGradient.Color = ColorSequence.new(config.gradientColor1, config.gradientColor2)

-- Заголовок
local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(0.5, 0, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "XOVAL"
title.TextColor3 = config.accentColor
title.Font = Enum.Font.GothamBold
title.TextSize = 24
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

-- Вкладки
local tabHolder = Instance.new("Frame", mainFrame)
tabHolder.Size = UDim2.new(0, 130, 1, -70)
tabHolder.Position = UDim2.new(0, 10, 0, 60)
tabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tabHolder.BorderSizePixel = 0
local tabHolderCorner = Instance.new("UICorner", tabHolder)
tabHolderCorner.CornerRadius = UDim.new(0, 10)
local tabHolderStroke = Instance.new("UIStroke", tabHolder)
tabHolderStroke.Color = config.accentColor
tabHolderStroke.Thickness = 1

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
    local tabStroke = Instance.new("UIStroke", tabBtn)
    tabStroke.Color = config.accentColor
    tabStroke.Thickness = 1
    tabButtons[tabName] = tabBtn

    local tabFrame = Instance.new("ScrollingFrame", mainFrame)
    tabFrame.Size = UDim2.new(1, -150, 1, -90)
    tabFrame.Position = UDim2.new(0, 150, 0, 70)
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
footer.Text = "Переключение: Insert | XOVAL Team 2025"
footer.TextColor3 = Color3.fromRGB(100, 100, 100)
footer.Font = Enum.Font.Gotham
footer.TextSize = 12

-- Фрейм настроек
local settingsFrame = Instance.new("Frame", screenGui)
settingsFrame.Size = UDim2.new(0, 450, 0, 550)
settingsFrame.Position = UDim2.new(0.5, -225, 0.5, -275)
settingsFrame.BackgroundColor3 = config.menuColor
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
local settingsCorner = Instance.new("UICorner", settingsFrame)
settingsCorner.CornerRadius = UDim.new(0, 12)
local settingsStroke = Instance.new("UIStroke", settingsFrame)
settingsStroke.Color = config.accentColor
settingsStroke.Thickness = 2
local settingsGradient = Instance.new("UIGradient", settingsFrame)
settingsGradient.Enabled = config.useGradient
settingsGradient.Color = ColorSequence.new(config.gradientColor1, config.gradientColor2)

-- Верхняя панель настроек
local settingsTopBar = Instance.new("Frame", settingsFrame)
settingsTopBar.Size = UDim2.new(1, 0, 0, 50)
settingsTopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
settingsTopBar.BorderSizePixel = 0
local settingsTopCorner = Instance.new("UICorner", settingsTopBar)
settingsTopCorner.CornerRadius = UDim.new(0, 12)
local settingsTopGradient = Instance.new("UIGradient", settingsTopBar)
settingsTopGradient.Enabled = config.useGradient
settingsTopGradient.Color = ColorSequence.new(config.gradientColor1, config.gradientColor2)

-- Заголовок настроек
local settingsTitle = Instance.new("TextLabel", settingsTopBar)
settingsTitle.Size = UDim2.new(0.7, 0, 1, 0)
settingsTitle.Position = UDim2.new(0, 15, 0, 0)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "Настройки"
settingsTitle.TextColor3 = config.accentColor
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 24
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
    local btnStroke = Instance.new("UIStroke", colorBtn)
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Thickness = 1
    colorBtn.MouseButton1Click:Connect(function()
        config.accentColor = preset.Color
        title.TextColor3 = preset.Color
        uiStroke.Color = preset.Color
        settingsStroke.Color = preset.Color
        settingsTitle.TextColor3 = preset.Color
        tabHolderStroke.Color = preset.Color
        for _, btn in pairs(tabButtons) do
            btn.TextColor3 = currentTab == btn.Text and preset.Color or Color3.fromRGB(200, 200, 200)
            btn:FindFirstChildOfClass("UIStroke").Color = preset.Color
        end
        saveConfig()
        createNotification("Акцентный цвет изменён на " .. preset.Name, preset.Color)
    end)
end

-- Переключатель градиента
local gradientToggle = Instance.new("Frame", settingsScroll)
gradientToggle.Size = UDim2.new(1, 0, 0, 40)
gradientToggle.BackgroundTransparency = 1

local gradientToggleBtn = Instance.new("TextButton", gradientToggle)
gradientToggleBtn.Size = UDim2.new(0, 60, 0, 30)
gradientToggleBtn.Position = UDim2.new(1, -70, 0, 5)
gradientToggleBtn.BackgroundColor3 = config.useGradient and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
gradientToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
gradientToggleBtn.Text = config.useGradient and "ВКЛ" or "ВЫКЛ"
gradientToggleBtn.Font = Enum.Font.Gotham
gradientToggleBtn.TextSize = 14
local gradientToggleCorner = Instance.new("UICorner", gradientToggleBtn)
gradientToggleCorner.CornerRadius = UDim.new(0, 8)

local gradientToggleLabel = Instance.new("TextLabel", gradientToggle)
gradientToggleLabel.Size = UDim2.new(0.8, 0, 1, 0)
gradientToggleLabel.BackgroundTransparency = 1
gradientToggleLabel.Text = "Использовать градиент"
gradientToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
gradientToggleLabel.Font = Enum.Font.Gotham
gradientToggleLabel.TextSize = 16
gradientToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

gradientToggleBtn.MouseButton1Click:Connect(function()
    config.useGradient = not config.useGradient
    gradientToggleBtn.BackgroundColor3 = config.useGradient and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    gradientToggleBtn.Text = config.useGradient and "ВКЛ" or "ВЫКЛ"
    gradient.Enabled = config.useGradient
    topGradient.Enabled = config.useGradient
    settingsGradient.Enabled = config.useGradient
    settingsTopGradient.Enabled = config.useGradient
    saveConfig()
    createNotification("Градиент " .. (config.useGradient and "включён" or "выключен"), config.accentColor)
end)

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
local animStroke = Instance.new("UIStroke", animDropdown)
animStroke.Color = config.accentColor
animStroke.Thickness = 1

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
    local optionStroke = Instance.new("UIStroke", animOption)
    optionStroke.Color = config.accentColor
    optionStroke.Thickness = 1
    animOption.MouseButton1Click:Connect(function()
        config.animationType = anim
        animDropdown.Text = anim
        animDropdownFrame.Visible = false
        saveConfig()
        createNotification("Анимация изменена на " .. anim, config.accentColor)
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
local speedStroke = Instance.new("UIStroke", speedSlider)
speedStroke.Color = config.accentColor
speedStroke.Thickness = 1

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
            createNotification("Скорость анимации: " .. string.format("%.2f", config.animationSpeed) .. "с", config.accentColor)
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
local unloadStroke = Instance.new("UIStroke", unloadBtn)
unloadStroke.Color = Color3.fromRGB(255, 255, 255)
unloadStroke.Thickness = 1

unloadBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    print("[XOVAL] Чит выгружен")
    createNotification("Чит выгружен", Color3.fromRGB(200, 40, 40))
end)

-- Анимации
local function animateOpen(frame)
    frame.Visible = true
    local tweenInfo = TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if config.animationType == "SlideFade" then
        frame.Position = UDim2.new(0.5, -275, 1.5, -300)
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -275, 0.5, -300), BackgroundTransparency = 0}):Play()
    elseif config.animationType == "PopIn" then
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 550, 0, 600)}):Play()
    elseif config.animationType == "SlideLeft" then
        frame.Position = UDim2.new(-0.5, -275, 0.5, -300)
        TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -275, 0.5, -300)}):Play()
    elseif config.animationType == "SlideDown" then
        frame.Position = UDim2.new(0.5, -275, -0.5, -300)
        TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -275, 0.5, -300)}):Play()
    elseif config.animationType == "FadeOnly" then
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0}):Play()
    elseif config.animationType == "Elastic" then
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 550, 0, 600)}):Play()
    end
end

local function animateClose(frame)
    local tweenInfo = TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tween
    if config.animationType == "SlideFade" then
        tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -275, 1.5, -300), BackgroundTransparency = 1})
    elseif config.animationType == "PopIn" then
        tween = TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
    elseif config.animationType == "SlideLeft" then
        tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(-0.5, -275, 0.5, -300)})
    elseif config.animationType == "SlideDown" then
        tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -275, -0.5, -300)})
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
        createNotification("Переключена вкладка: " .. tabName, config.accentColor)
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
            createNotification("Меню открыто", config.accentColor)
        else
            if settingsOpen then
                animateClose(settingsFrame)
                settingsOpen = false
            end
            animateClose(mainFrame)
            createNotification("Меню закрыто", config.accentColor)
        end
    end
end)

-- Закрытие меню
closeBtn.MouseButton1Click:Connect(function()
    guiOpen = false
    animateClose(mainFrame)
    createNotification("Меню закрыто", config.accentColor)
end)

settingsCloseBtn.MouseButton1Click:Connect(function()
    settingsOpen = false
    animateClose(settingsFrame)
    animateOpen(mainFrame)
    createNotification("Настройки закрыты", config.accentColor)
end)

-- Открытие настроек
tabButtons.Настройки.MouseButton1Click:Connect(function()
    settingsOpen = true
    animateOpen(settingsFrame)
    animateClose(mainFrame)
    createNotification("Открыты настройки", config.accentColor)
end)

-- Утилиты для интерфейса
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
    local toggleStroke = Instance.new("UIStroke", toggleBtn)
    toggleStroke.Color = config.accentColor
    toggleStroke.Thickness = 1

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
        createNotification(name .. ": " .. (config[configKey] and "включено" or "выключено"), config.accentColor)
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
    local sliderStroke = Instance.new("UIStroke", slider)
    sliderStroke.Color = config.accentColor
    sliderStroke.Thickness = 1

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
                createNotification(name .. ": " .. config[configKey], config.accentColor)
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
welcomeLabel.Size = UDim2.new(1, 0, 0, 120)
welcomeLabel.BackgroundTransparency = 1
welcomeLabel.Text = "Добро пожаловать в XOVAL!\nПродвинутый чит для Murder Mystery 2\nПереключение меню: Insert\nСоздано XOVAL Team 2025"
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
local teleportStroke = Instance.new("UIStroke", teleportBtn)
teleportStroke.Color = config.accentColor
teleportStroke.Thickness = 1

local teleportDropdown = Instance.new("Frame", tabFrames["Главная"])
teleportDropdown.Size = UDim2.new(1, 0, 0, 0)
teleportDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
teleportDropdown.Visible = false
local teleportDropdownCorner = Instance.new("UICorner", teleportDropdown)
teleportDropdownCorner.CornerRadius = UDim.new(0, 8)
local teleportDropdownStroke = Instance.new("UIStroke", teleportDropdown)
teleportDropdownStroke.Color = config.accentColor
teleportDropdownStroke.Thickness = 1
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
            local btnStroke = Instance.new("UIStroke", playerBtn)
            btnStroke.Color = config.accentColor
            btnStroke.Thickness = 1
            playerBtn.MouseButton1Click:Connect(function()
                local success, err = pcall(function()
                    if LocalPlayer.Character and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
                        createNotification("Телепортировались к " .. player.Name, config.accentColor)
                    else
                        createNotification("Ошибка: Игрок недоступен", Color3.fromRGB(200, 40, 40))
                    end
                end)
                if not success then
                    createNotification("Ошибка телепорта: " .. err, Color3.fromRGB(200, 40, 40))
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
    createNotification("Меню телепорта " .. (teleportDropdown.Visible and "открыто" or "закрыто"), config.accentColor)
end)

-- Вкладка "Бой"
createToggle("Бой", "Аимбот", "aimbotEnabled")
createSlider("Бой", "Поле зрения аимбота", "aimbotFOV", 50, 200, 100)
createToggle("Бой", "Килл-аура", "killAuraEnabled")
createToggle("Бой", "Ноклип", "noclip")
createToggle("Бой", "Режим бога", "godMode")
createSlider("Бой", "Скорость персонажа", "speedHack", 16, 100, 16)

-- Вкладка "Визуалы"
createToggle("Визуалы", "ESP игроков", "espEnabled")
createToggle("Визуалы", "Показывать имена", "espShowNames")
createToggle("Визуалы", "Показывать роли", "espShowRoles")
createToggle("Визуалы", "Визуальные эффекты", "visualEffects")

local espColorLabelMurderer = Instance.new("TextLabel", tabFrames["Визуалы"])
espColorLabelMurderer.Size = UDim2.new(1, 0, 0, 30)
espColorLabelMurderer.BackgroundTransparency = 1
espColorLabelMurderer.Text = "Цвет ESP для мардера"
espColorLabelMurderer.TextColor3 = Color3.fromRGB(200, 200, 200)
espColorLabelMurderer.Font = Enum.Font.Gotham
espColorLabelMurderer.TextSize = 16
espColorLabelMurderer.TextXAlignment = Enum.TextXAlignment.Left

local espColorHolderMurderer = Instance.new("Frame", tabFrames["Визуалы"])
espColorHolderMurderer.Size = UDim2.new(1, 0, 0, 40)
espColorHolderMurderer.BackgroundTransparency = 1
local espColorLayoutMurderer = Instance.new("UIListLayout", espColorHolderMurderer)
espColorLayoutMurderer.FillDirection = Enum.FillDirection.Horizontal
espColorLayoutMurderer.Padding = UDim.new(0, 8)

for _, preset in ipairs(colorPresets) do
    local espColorBtn = Instance.new("TextButton", espColorHolderMurderer)
    espColorBtn.Size = UDim2.new(0, 60, 0, 30)
    espColorBtn.BackgroundColor3 = preset.Color
    espColorBtn.Text = preset.Name
    espColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espColorBtn.Font = Enum.Font.Gotham
    espColorBtn.TextSize = 12
    local btnCorner = Instance.new("UICorner", espColorBtn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    local btnStroke = Instance.new("UIStroke", espColorBtn)
    btnStroke.Color = config.accentColor
    btnStroke.Thickness = 1
    espColorBtn.MouseButton1Click:Connect(function()
        config.espMurdererColor = preset.Color
        saveConfig()
        createNotification("Цвет ESP мардера: " .. preset.Name, preset.Color)
    end)
end

local espColorLabelSheriff = Instance.new("TextLabel", tabFrames["Визуалы"])
espColorLabelSheriff.Size = UDim2.new(1, 0, 0, 30)
espColorLabelSheriff.BackgroundTransparency = 1
espColorLabelSheriff.Text = "Цвет ESP для шерифа"
espColorLabelSheriff.TextColor3 = Color3.fromRGB(200, 200, 200)
espColorLabelSheriff.Font = Enum.Font.Gotham
espColorLabelSheriff.TextSize = 16
espColorLabelSheriff.TextXAlignment = Enum.TextXAlignment.Left

local espColorHolderSheriff = Instance.new("Frame", tabFrames["Визуалы"])
espColorHolderSheriff.Size = UDim2.new(1, 0, 0, 40)
espColorHolderSheriff.BackgroundTransparency = 1
local espColorLayoutSheriff = Instance.new("UIListLayout", espColorHolderSheriff)
espColorLayoutSheriff.FillDirection = Enum.FillDirection.Horizontal
espColorLayoutSheriff.Padding = UDim.new(0, 8)

for _, preset in ipairs(colorPresets) do
    local espColorBtn = Instance.new("TextButton", espColorHolderSheriff)
    espColorBtn.Size = UDim2.new(0, 60, 0, 30)
    espColorBtn.BackgroundColor3 = preset.Color
    espColorBtn.Text = preset.Name
    espColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espColorBtn.Font = Enum.Font.Gotham
    espColorBtn.TextSize = 12
    local btnCorner = Instance.new("UICorner", espColorBtn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    local btnStroke = Instance.new("UIStroke", espColorBtn)
    btnStroke.Color = config.accentColor
    btnStroke.Thickness = 1
    espColorBtn.MouseButton1Click:Connect(function()
        config.espSheriffColor = preset.Color
        saveConfig()
        createNotification("Цвет ESP шерифа: " .. preset.Name, preset.Color)
    end)
end

local espColorLabelInnocent = Instance.new("TextLabel", tabFrames["Визуалы"])
espColorLabelInnocent.Size = UDim2.new(1, 0, 0, 30)
espColorLabelInnocent.BackgroundTransparency = 1
espColorLabelInnocent.Text = "Цвет ESP для мирных"
espColorLabelInnocent.TextColor3 = Color3.fromRGB(200, 200, 200)
espColorLabelInnocent.Font = Enum.Font.Gotham
espColorLabelInnocent.TextSize = 16
espColorLabelInnocent.TextXAlignment = Enum.TextXAlignment.Left

local espColorHolderInnocent = Instance.new("Frame", tabFrames["Визуалы"])
espColorHolderInnocent.Size = UDim2.new(1, 0, 0, 40)
espColorHolderInnocent.BackgroundTransparency = 1
local espColorLayoutInnocent = Instance.new("UIListLayout", espColorHolderInnocent)
espColorLayoutInnocent.FillDirection = Enum.FillDirection.Horizontal
espColorLayoutInnocent.Padding = UDim.new(0, 8)

for _, preset in ipairs(colorPresets) do
    local espColorBtn = Instance.new("TextButton", espColorHolderInnocent)
    espColorBtn.Size = UDim2.new(0, 60, 0, 30)
    espColorBtn.BackgroundColor3 = preset.Color
    espColorBtn.Text = preset.Name
    espColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espColorBtn.Font = Enum.Font.Gotham
    espColorBtn.TextSize = 12
    local btnCorner = Instance.new("UICorner", espColorBtn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    local btnStroke = Instance.new("UIStroke", espColorBtn)
    btnStroke.Color = config.accentColor
    btnStroke.Thickness = 1
    espColorBtn.MouseButton1Click:Connect(function()
        config.espInnocentColor = preset.Color
        saveConfig()
        createNotification("Цвет ESP мирных: " .. preset.Name, preset.Color)
    end)
end

createSlider("Визуалы", "Прозрачность ESP", "espTransparency", 0, 1, 0.5)

-- Вкладка "Мардер"
createToggle("Мардер", "Аура ножа", "murdererFeatures")
createSlider("Мардер", "Радиус ауры ножа", "knifeAuraRange", 5, 30, 15)
createToggle("Мардер", "Автобросок ножа", "autoKnifeThrow")

-- Вкладка "Шериф"
createToggle("Шериф", "Аура пистолета", "sheriffFeatures")
createSlider("Шериф", "Радиус ауры пистолета", "gunAuraRange", 10, 50, 20)
createToggle("Шериф", "Автострельба", "autoShoot")

-- Визуальные эффекты (частицы)
local function createParticleEffect(character)
    if not config.visualEffects or not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Parent = character.HumanoidRootPart
    particleEmitter.Texture = "rbxassetid://243098098"
    particleEmitter.Color = ColorSequence.new(config.accentColor)
    particleEmitter.Size = NumberSequence.new(0.5)
    particleEmitter.Lifetime = NumberRange.new(0.5, 1)
    particleEmitter.Rate = 20
    particleEmitter.Speed = NumberRange.new(5)
    return particleEmitter
end

-- Определение роли
local function getPlayerRole(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    if (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) then
        return "Murderer"
    elseif (backpack and backpack:FindFirstChild("Gun")) or (character and character:FindFirstChild("Gun")) then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- Реализация ESP
local espCache = {}
local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local role = getPlayerRole(player)
            local color = role == "Murderer" and config.espMurdererColor or role == "Sheriff" and config.espSheriffColor or config.espInnocentColor
            if config.espEnabled then
                if not espCache[player] then
                    espCache[player] = {}
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = player.Character
                    highlight.Adornee = player.Character
                    highlight.FillColor = color
                    highlight.OutlineColor = color
                    highlight.FillTransparency = config.espTransparency
                    highlight.OutlineTransparency = 0
                    espCache[player].highlight = highlight

                    if config.espShowNames or config.espShowRoles then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Parent = player.Character.HumanoidRootPart
                        billboard.Adornee = player.Character.HumanoidRootPart
                        billboard.Size = UDim2.new(0, 200, 0, 50)
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.AlwaysOnTop = true

                        local nameLabel = Instance.new("TextLabel", billboard)
                        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                        nameLabel.BackgroundTransparency = 1
                        nameLabel.Text = config.espShowNames and player.Name or ""
                        nameLabel.TextColor3 = color
                        nameLabel.Font = Enum.Font.GothamBold
                        nameLabel.TextSize = 14
                        nameLabel.TextStrokeTransparency = 0.5

                        local roleLabel = Instance.new("TextLabel", billboard)
                        roleLabel.Size = UDim2.new(1, 0, 0.5, 0)
                        roleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                        roleLabel.BackgroundTransparency = 1
                        roleLabel.Text = config.espShowRoles and role or ""
                        roleLabel.TextColor3 = color
                        roleLabel.Font = Enum.Font.Gotham
                        roleLabel.TextSize = 12
                        roleLabel.TextStrokeTransparency = 0.5

                        espCache[player].billboard = billboard
                    end

                    if config.visualEffects then
                        espCache[player].particle = createParticleEffect(player.Character)
                    end
                else
                    espCache[player].highlight.FillColor = color
                    espCache[player].highlight.OutlineColor = color
                    espCache[player].highlight.FillTransparency = config.espTransparency
                    if espCache[player].billboard then
                        espCache[player].billboard:FindFirstChildOfClass("TextLabel").Text = config.espShowNames and player.Name or ""
                        espCache[player].billboard:FindFirstChildOfClass("TextLabel").TextColor3 = color
                        espCache[player].billboard:FindFirstChildOfClass("TextLabel").NextSibling.Text = config.espShowRoles and role or ""
                        espCache[player].billboard:FindFirstChildOfClass("TextLabel").NextSibling.TextColor3 = color
                    end
                    if config.visualEffects and not espCache[player].particle then
                        espCache[player].particle = createParticleEffect(player.Character)
                    elseif not config.visualEffects and espCache[player].particle then
                        espCache[player].particle:Destroy()
                        espCache[player].particle = nil
                    end
                end
            else
                if espCache[player] then
                    if espCache[player].highlight then
                        espCache[player].highlight:Destroy()
                    end
                    if espCache[player].billboard then
                        espCache[player].billboard:Destroy()
                    end
                    if espCache[player].particle then
                        espCache[player].particle:Destroy()
                    end
                    espCache[player] = nil
                end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    if espCache[player] then
        if espCache[player].highlight then
            espCache[player].highlight:Destroy()
        end
        if espCache[player].billboard then
            espCache[player].billboard:Destroy()
        end
        if espCache[player].particle then
            espCache[player].particle:Destroy()
        end
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
                if distance < config.aimbotFOV and distance < dist then
                    closest = player
                    dist = distance
                end
            end
        end
    end
    return closest
end

-- Аура ножа для мардера
local function knifeAura()
    if not config.murdererFeatures or getPlayerRole(LocalPlayer) ~= "Murderer" then return end
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
    if not config.sheriffFeatures or getPlayerRole(LocalPlayer) ~= "Sheriff" then return end
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

-- Автобросок ножа
local function autoKnifeThrow()
    if not config.autoKnifeThrow or getPlayerRole(LocalPlayer) ~= "Murderer" then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local tool = character:FindFirstChild("Knife") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Knife"))
    if tool then
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        remote:FireServer(player.Character.Humanoid)
                    end)
                end
            end
        end
    end
end

-- Автострельба
local function autoShoot()
    if not config.autoShoot or getPlayerRole(LocalPlayer) ~= "Sheriff" then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local tool = character:FindFirstChild("Gun") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Gun"))
    if tool then
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        remote:FireServer(player.Character.Humanoid)
                    end)
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
        autoKnifeThrow()
        autoShoot()
        autoFarm()
        noClip()
        godMode()
        updateSpeed()
    end)
end)

-- Инициализация
print("[XOVAL] Чит успешно загружен")
createNotification("XOVAL загружен", config.accentColor)
