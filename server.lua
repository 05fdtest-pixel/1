local pixelbox = require("pixelbox_lite")

-- Открываем беспроводной модем справа
local modemSide = "right"
if peripheral.getType(modemSide) ~= "modem" and peripheral.getType(modemSide) ~= "wireless_modem" then
    error("Wireless modem not found on 'right' side!")
end
rednet.open(modemSide)

print("Server started! High FPS mode with collisions.")

-- Простая карта мира: 1 — стена, 0 — проход
local map = {
    {1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,1},
    {1,0,1,1,0,1,0,1},
    {1,0,1,0,0,1,0,1},
    {1,0,0,0,1,1,0,1},
    {1,1,1,0,0,0,0,1},
    {1,0,0,0,1,1,0,1},
    {1,1,1,1,1,1,1,1},
}

-- Координаты игрока и угол обзора
local px, py = 3.5, 3.5
local pfa = 0

-- Настройки движения, коллизий и плавности поворотов
local MOVE_SPEED = 0.15
local ROT_SPEED = 0.1

-- Функция проверки коллизий со стенами
local function isWall(x, y)
    local mx = math.floor(x) + 1
    local my = math.floor(y) + 1
    if mx < 1 or mx > 8 or my < 1 or my > 8 then return true end
    return map[my][mx] == 1
end

-- Функция отрисовки кадра
local function renderFrame()
    term.clear()
    
    pixelbox.drawText(2, 2, "X: " .. string.format("%.2f", px) .. " Y: " .. string.format("%.2f", py), colors.green)
    pixelbox.drawText(2, 3, "Angle: " .. string.format("%.2f", pfa), colors.cyan)
    
    pixelbox.flush()
end

-- Основной игровой цикл
while true do
    renderFrame()

    -- Стабильный таймер для высокого FPS (~50 кадров/сек)
    local timerId = os.startTimer(0.02)
    local event, p1, p2 = os.pullEvent()

    if event == "rednet_message" then
        local senderId, message = p1, p2
        if type(message) == "table" and message.type == "key" then
            local key = message.key
            
            local newX = px
            local newY = py
            
            if key == keys.w then
                newX = px + math.cos(pfa) * MOVE_SPEED
                newY = py + math.sin(pfa) * MOVE_SPEED
            elseif key == keys.s then
                newX = px - math.cos(pfa) * MOVE_SPEED
                newY = py - math.sin(pfa) * MOVE_SPEED
            elseif key == keys.a then
                pfa = pfa - ROT_SPEED
            elseif key == keys.d then
                pfa = pfa + ROT_SPEED
            end
            
            -- Проверка коллизий раздельно по осям (для скольжения вдоль стен)
            if not isWall(newX, py) then
                px = newX
            end
            if not isWall(px, newY) then
                py = newY
            end
        end
    end
end
