-- Защита от повторного запуска (удаляет старый UI, если скрипт запущен еще раз)
local oldGui = game:GetService("CoreGui"):FindFirstChild("SpeedTrackerGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("SpeedTrackerGui")
if oldGui then oldGui:Destroy() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Настройка скорости
local TARGET_SPEED = 80

-- Создаем интерфейс (используем CoreGui, чтобы UI не пропадал при смерти)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedTrackerGui"
screenGui.ResetOnSpawn = false

-- Проверка на поддержку CoreGui инжектором (безопасное добавление)
local success, err = pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Создаем текст по центру экрана
local textLabel = Instance.new("TextLabel")
textLabel.Name = "SpeedDisplay"
textLabel.Size = UDim2.new(0, 400, 0, 50)
textLabel.Position = UDim2.new(0.5, 0, 0.5, 0) -- Точный центр
textLabel.AnchorPoint = Vector2.new(0.5, 0.5)  -- Центрирование относительно своей оси
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(0, 255, 128) -- Красивый неоново-зеленый цвет
textLabel.TextSize = 22
textLabel.Font = Enum.Font.RobotoMono -- Моноширинный шрифт (отлично для читов)
textLabel.TextStrokeTransparency = 0 -- Черная обводка
textLabel.Parent = screenGui

-- Постоянный цикл для удержания скорости и обновления текста
local connection
connection = RunService.RenderStepped:Connect(function()
    -- Проверяем, существует ли еще интерфейс (если его удалили — отключаем цикл)
    if not textLabel or not textLabel.Parent then
        connection:Disconnect()
        return
    end

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Принудительно ставим скорость (защита от сброса игрой)
            humanoid.WalkSpeed = TARGET_SPEED
            
            -- Выводим Никнейм и Текущую скорость
            textLabel.Text = string.format("%s | Speed: %d", player.Name, humanoid.WalkSpeed)
        else
            textLabel.Text = player.Name .. " | Loading..."
        end
    else
        textLabel.Text = player.Name .. " | Dead"
    end
end)
