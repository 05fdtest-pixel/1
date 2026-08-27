-- Главный сервер (Рейкастинг с Pixelbox Lite)
local pixelbox = require("pixelbox_lite")

local modemSide = "right"
if peripheral.getType(modemSide) ~= "modem" and peripheral.getType(modemSide) ~= "wireless_modem" then
    error("Wireless modem not found on 'right' side of the server!")
end
rednet.open(modemSide)

-- Инициализация холста Pixelbox под размер экрана
local box = pixelbox.new(term.current())

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

-- Начальные координаты игрока и угол обзора
local px, py, pfa = 3.5, 3.5, 0

-- Ограничение скорости для плавного передвижения
local MOVE_SPEED = 0.08
local ROT_SPEED = 0.05

local pw, ph = box.width, box.height

-- Функция проверки коллизий со стенами
local function isWall(x, y)
    local mx = math.floor(x) + 1
    local my = math.floor(y) + 1
    if mx < 1 or mx > 8 or my < 1 or my > 8 then return true end
    return map[my][mx] == 1
end

-- Функция отрисовки 3D мира
local function renderRaycasting()
    -- 1. Закрашиваем небо (сверху) и пол (снизу) в буфере
    for y = 1, math.floor(ph / 2) do
        for x = 1, pw do
            box.canvas[y][x] = colors.cyan
        end
    end
    for y = math.floor(ph / 2) + 1, ph do
        for x = 1, pw do
            box.canvas[y][x] = colors.green
        end
    end

    -- 2. Пускаем лучи для каждого вертикального столбца экрана
    for x = 1, pw do
        local camX = 2 * x / pw - 1
        local rayAngle = pfa + math.atan(camX * 0.66)

        local dist = 0
        local hit = false
        local side = 0

        local eyeX = math.cos(rayAngle)
        local eyeY = math.sin(rayAngle)

        -- Шагаем лучом до упора в стену
        while not hit and dist < 16 do
            dist = dist + 0.05
            local tx = math.floor(px + eyeX * dist)
            local ty = math.floor(py + eyeY * dist)

            if tx < 0 or tx >= 8 or ty < 0 or ty >= 8 then
                hit = true
                dist = 16
            elseif map[ty + 1] and map[ty + 1][tx + 1] == 1 then
                hit = true
                local prevX = math.floor(px + eyeX * (dist - 0.05))
                if prevX ~= tx then side = 1 end
            end
        end

        -- Вычисляем высоту стены на экране
        local wallHeight = math.floor(ph / dist)
        local yStart = math.max(1, math.floor(ph / 2 - wallHeight / 2))
        local yEnd = math.min(ph, math.floor(ph / 2 + wallHeight / 2))

        -- Делаем боковые грани темнее для объёма
        local wallColor = (side == 1) and colors.gray or colors.lightGray

        -- Записываем пиксели стены в матрицу
        for y = yStart, yEnd do
            box.canvas[y][x] = wallColor
        end
    end

    -- Выводим готовый кадр на экран монитора
    box:render()
end

-- Основной игровой цикл сервера
while true do
    renderRaycasting()

    -- Ожидание сообщений от пульта с ограничением по времени (высокий FPS)
    local timerId = os.startTimer(0.02)
    local event, p1, p2 = os.pullEvent()

    if event == "rednet_message" and type(p2) == "table" and p2.type == "key" then
        local key = p2.key
        local newX, newY = px, py

        -- Обработка перемещения
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

        -- Проверка коллизий по осям (скольжение вдоль стен)
        if not isWall(newX, py) then px = newX end
        if not isWall(px, newY) then py = newY end
    end
end
