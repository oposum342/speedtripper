-- Защита от повторного запуска (удаляет старый UI, если скрипт запущен еще раз)
local oldGui = game:GetService("CoreGui"):FindFirstChild("SpeedTrackerGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("SpeedTrackerGui")
if oldGui then oldGui:Destroy() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Настройки
local TARGET_SPEED = 80
local FLY_SPEED = 50

-- Переменные состояния
local menuVisible = true
local flyEnabled = false

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
textLabel.Size = UDim2.new(0, 500, 0, 80) -- Немного увеличили размер для новых строк
textLabel.Position = UDim2.new(0.5, 0, 0.5, 0) -- Точный центр
textLabel.AnchorPoint = Vector2.new(0.5, 0.5)  -- Центрирование относительно своей оси
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(0, 255, 128) -- Красивый неоново-зеленый цвет
textLabel.TextSize = 18 -- Чуть уменьшили размер, чтобы помещалось 3 строки
textLabel.Font = Enum.Font.RobotoMono -- Моноширинный шрифт
textLabel.TextStrokeTransparency = 0 -- Черная обводка
textLabel.Parent = screenGui

-- Логика полета (Fly)
local bodyGyro, bodyVelocity
local forward, backward, left, right = 0, 0, 0, 0

local function startFly(character, rootPart)
    if not rootPart then return end
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.cframe = rootPart.CFrame
    bodyGyro.Parent = rootPart
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.velocity = Vector3.new(0, 0.1, 0)
    bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Parent = rootPart
    
    -- Игнорируем гравитацию во время полета
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = true end
end

local function stopFly(character)
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
    
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
end

-- Отслеживание нажатий клавиш для Fly (W, A, S, D) и биндов (R, U)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Переключение Fly на R
    if input.KeyCode == Enum.KeyCode.R then
        flyEnabled = not flyEnabled
        local character = player.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if flyEnabled then
                startFly(character, rootPart)
            else
                stopFly(character)
            end
        end
    -- Скрытие/Показ меню на U
    elseif input.KeyCode == Enum.KeyCode.U then
        menuVisible = not menuVisible
        textLabel.Visible = menuVisible
    end
    
    -- Управление направлением полета
    if input.KeyCode == Enum.KeyCode.W then forward = 1
    elseif input.KeyCode == Enum.KeyCode.S then backward = -1
    elseif input.KeyCode == Enum.KeyCode.A then left = -1
    elseif input.KeyCode == Enum.KeyCode.D then right = 1
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then forward = 0
    elseif input.KeyCode == Enum.KeyCode.S then backward = 0
    elseif input.KeyCode == Enum.KeyCode.A then left = 0
    elseif input.KeyCode == Enum.KeyCode.D then right = 0
    end
end)

-- Постоянный цикл для удержания скорости, полета и обновления текста
local connection
connection = RunService.RenderStepped:Connect(function()
    -- Проверяем, существует ли еще интерфейс
    if not textLabel or not textLabel.Parent then
        connection:Disconnect()
        return
    end

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and rootPart then
            -- Статус функций для вывода на экран
            local flyStatus = flyEnabled and "ON" or "OFF"
            local menuStatus = menuVisible and "VISIBLE" or "HIDDEN"
            
            -- Если включен полет, управляем перемещением в воздухе
            if flyEnabled and bodyVelocity and bodyGyro then
                local camera = workspace.CurrentCamera
                bodyGyro.cframe = camera.CFrame
                
                local moveDirection = camera.CFrame.LookVector * (forward + backward) + camera.CFrame.RightVector * (left + right)
                if moveDirection.Magnitude > 0 then
                    bodyVelocity.velocity = moveDirection.Unit * FLY_SPEED
                else
                    bodyVelocity.velocity = Vector3.new(0, 0, 0)
                end
                
                -- Во время полета WalkSpeed не отображает реальную скорость, пишем FLY_SPEED
                textLabel.Text = string.format("%s | Speed: %d\n[R] Fly: %s\n[U] Menu: %s", player.Name, FLY_SPEED, flyStatus, menuStatus)
            else
                -- Если полет выключен — работает обычный спидхак
                humanoid.WalkSpeed = TARGET_SPEED
                textLabel.Text = string.format("%s | Speed: %d\n[R] Fly: %s\n[U] Menu: %s", player.Name, humanoid.WalkSpeed, flyStatus, menuStatus)
            end
        else
            textLabel.Text = player.Name .. " | Loading..."
        end
    else
        flyEnabled = false -- Сбрасываем флаг полета при смерти
        textLabel.Text = player.Name .. " | Dead"
    end
end)
