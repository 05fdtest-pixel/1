local pixelbox = require("pixelbox_lite")

local modemSide = "right"
if peripheral.getType(modemSide) ~= "modem" and peripheral.getType(modemSide) ~= "wireless_modem" then
    error("Wireless modem not found on 'right' side!")
end
rednet.open(modemSide)

-- Инициализация Pixelbox
local box = pixelbox.new(term.current())

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

local px, py, pfa = 3.5, 3.5, 0

-- Настройки плавной скорости и поворота
local MOVE_SPEED = 0.08
local ROT_SPEED = 0.05

local pw, ph = box.width, box.height

local function isWall(x, y)
    local mx = math.floor(x) + 1
    local my = math.floor(y) + 1
    if mx < 1 or mx > 8 or my < 1 or my > 8 then return true end
    return map[my][mx] == 1
end

local function renderRaycasting()
    -- Быстрая очистка экрана через закрашивание буфера
    box:rect(1, 1, pw, ph / 2, colors.cyan)      -- Небо
    box:rect(1, ph / 2 + 1, pw, ph, colors.green) -- Пол

    -- Отрисовка 3D лучей
    for x = 1, pw do
        local camX = 2 * x / pw - 1
        local rayAngle = pfa + math.atan(camX * 0.66)

        local dist = 0
        local hit = false
        local side = 0

        local eyeX = math.cos(rayAngle)
        local eyeY = math.sin(rayAngle)

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

        local wallHeight = math.floor(ph / dist)
        local yStart = math.max(1, math.floor(ph / 2 - wallHeight / 2))
        local yEnd = math.min(ph, math.floor(ph / 2 + wallHeight / 2))

        local wallColor = (side == 1) and colors.gray or colors.lightGray
        box:rect(x, yStart, 1, yEnd - yStart + 1, wallColor)
    end

    box:draw()
end

while true do
    renderRaycasting()

    local timerId = os.startTimer(0.02)
    local event, p1, p2 = os.pullEvent()

    if event == "rednet_message" and type(p2) == "table" and p2.type == "key" then
        local key = p2.key
        local newX, newY = px, py

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

        if not isWall(newX, py) then px = newX end
        if not isWall(px, newY) then py = newY end
    end
end
