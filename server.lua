local modemSide = "right"
if peripheral.getType(modemSide) ~= "modem" and peripheral.getType(modemSide) ~= "wireless_modem" then
    error("Wireless modem not found on the 'right' side of the server!")
end
rednet.open(modemSide)

print("Raycasting server started!")

-- Карта мира (1 — стена, 0 — пустота)
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
local px, py, pfa = 3.5, 3.5, 0

local MOVE_SPEED = 0.08
local ROT_SPEED = 0.05

local screenWidth, screenHeight = term.getSize()

local function isWall(x, y)
    local mx = math.floor(x) + 1
    local my = math.floor(y) + 1
    if mx < 1 or mx > 8 or my < 1 or my > 8 then return true end
    return map[my][mx] == 1
end

-- Функция рэйкастинга с гранями стен
local function renderRaycasting()
    term.clear()

    for x = 1, screenWidth do
        local cameraX = 2 * x / screenWidth - 1
        local rayAngle = pfa + math.atan(cameraX * 0.66)

        local distanceToWall = 0
        local hitWall = false
        local side = 0 -- 0 для вертикальной грани, 1 для горизонтальной (нужно для затенения)

        local eyeX = math.cos(rayAngle)
        local eyeY = math.sin(rayAngle)

        while not hitWall and distanceToWall < 16 do
            distanceToWall = distanceToWall + 0.05
            local testX = math.floor(px + eyeX * distanceToWall)
            local testY = math.floor(py + eyeY * distanceToWall)
            
            if testX < 0 or testX >= 8 or testY < 0 or testY >= 8 then
                hitWall = true
                distanceToWall = 16
            else
                local mx = testX + 1
                local my = testY + 1
                if mx >= 1 and mx <= 8 and my >= 1 and my <= 8 then
                    if map[my][mx] == 1 then
                        hitWall = true
                        -- Проверяем, с какой стороны прилетел луч, чтобы сделать грань темнее
                        local prevX = math.floor(px + eyeX * (distanceToWall - 0.05))
                        if prevX ~= testX then
                            side = 1
                        end
                    end
                end
            end
        end

        local ceiling = math.floor(screenHeight / 2 - screenHeight / distanceToWall)
        local floor = screenHeight - ceiling

        for y = 1, screenHeight do
            term.setCursorPos(x, y)
            if y < ceiling then
                -- Голубое небо
                term.setBackgroundColor(colors.blue)
                term.write(" ")
            elseif y >= ceiling and y <= floor then
                -- Стены: серые, а боковые грани (side == 1) делаем темно-серыми для объема
                if side == 1 then
                    term.setBackgroundColor(colors.gray)
                else
                    term.setBackgroundColor(colors.lightGray)
                end
                term.write(" ")
            else
                -- Зеленый пол
                term.setBackgroundColor(colors.green)
                term.write(" ")
            end
        end
    end
end

-- Основной игровой цикл
while true do
    renderRaycasting()

    local timerId = os.startTimer(0.03)
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
            
            if not isWall(newX, py) then px = newX end
            if not isWall(px, newY) then py = newY end
        end
    end
end
