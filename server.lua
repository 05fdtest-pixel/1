-- Подключаем Pixelbox Lite (убедись, что файл pixelbox_lite.lua скачан)
local pixelbox = require("pixelbox_lite")

-- Открываем беспроводной модем справа
local modemSide = "right"
if peripheral.getType(modemSide) ~= "modem" and peripheral.getType(modemSide) ~= "wireless_modem" then
    error("Wireless modem not found on the 'right' side of the server!")
end
rednet.open(modemSide)

print("Server started successfully!")
print("My Server ID: " .. os.getComputerID())

-- Начальные координаты и угол обзора игрока в 3D мире
local px, py, pfa = 3.5, 3.5, 0

-- Функция отрисовки (пример минимального кадра)
local function renderFrame()
    pixelbox.clear(colors.black)
    -- Здесь происходит вся логика рейкастинга...
    pixelbox.drawText(2, 2, "X: " .. math.floor(px) .. " Y: " .. math.floor(py), colors.yellow)
    pixelbox.flush()
end

-- Основной игровой цикл
while true do
    renderFrame()

    -- Ждем события с таймаутом, чтобы игра не замерзала на месте
    local timerId = os.startTimer(0.05)
    local event, p1, p2, p3 = os.pullEvent()

    if event == "rednet_message" then
        local senderId, message = p1, p2
        -- Проверяем, что сообщение пришло от нашего пульта и это событие клавиши
        if type(message) == "table" and message.type == "key" then
            local key = message.key
            
            -- Логика управления движением
            if key == keys.w then
                px = px + math.cos(pfa) * 0.2
                py = py + math.sin(pfa) * 0.2
            elseif key == keys.s then
                px = px - math.cos(pfa) * 0.2
                py = py - math.sin(pfa) * 0.2
            elseif key == keys.a then
                pfa = pfa - 0.2
            elseif key == keys.d then
                pfa = pfa + 0.2
            end
        end
    elseif event == "timer" and p1 == timerId then
        -- Срабатывает таймер обновления кадра, ничего делать не нужно
    end
end
