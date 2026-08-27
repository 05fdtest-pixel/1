local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)
monitor.clear()

local W, H = monitor.getSize()

-- Цвета
local SKY_COLOR = colors.toBlit(colors.cyan)
local FLOOR_COLOR = colors.toBlit(colors.green)
local WALL_LIGHT = colors.toBlit(colors.lightGray)
local WALL_DARK = colors.toBlit(colors.gray)

-- Карта 10x10, полностью замкнутая со всех сторон
local MAP_SIZE = 10
local map = {
    {1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1}
}

-- Игрок
local posX, posY = 5.5, 5.5
local dirX, dirY = -1.0, 0.0

-- Корректировка угла обзора под пиксели монитора CC ( Aspect Ratio ~ 0.45 )
local FOV = 0.66
local planeX, planeY = 0.0, FOV * (H / W) * 0.45

local moveSpeed = 3.0
local rotSpeed = 2.0
local RADIUS = 0.2

local keysHeld = { forward = false, back = false, left = false, right = false }

local function render()
    -- Рендерим капотные столбцы прямо в текстовые буферы строк экрана
    local screenFG = {}
    local screenBG = {}
    
    local halfH = math.floor(H / 2)
    for y = 1, H do
        screenFG[y] = {}
        screenBG[y] = {}
    end

    for x = 1, W do
        -- Нормализованная координата X на экране [-1; 1]
        local cameraX = 2 * (x - 1) / (W - 1) - 1
        local rayDirX = dirX + planeX * cameraX
        local rayDirY = dirY + planeY * cameraX

        local mapX = math.floor(posX)
        local mapY = math.floor(posY)

        local deltaDistX = (rayDirX == 0) and 1e30 or math.abs(1 / rayDirX)
        local deltaDistY = (rayDirY == 0) and 1e30 or math.abs(1 / rayDirY)

        local stepX, stepY
        local sideDistX, sideDistY

        if rayDirX < 0 then
            stepX = -1
            sideDistX = (posX - mapX) * deltaDistX
        else
            stepX = 1
            sideDistX = (mapX + 1.0 - posX) * deltaDistX
        end

        if rayDirY < 0 then
            stepY = -1
            sideDistY = (posY - mapY) * deltaDistY
        else
            stepY = 1
            sideDistY = (mapY + 1.0 - posY) * deltaDistY
        end

        local hit = 0
        local side = 0

        -- Цикл трассировки луча
        while hit == 0 do
            if sideDistX < sideDistY then
                sideDistX = sideDistX + deltaDistX
                mapX = mapX + stepX
                side = 0
            else
                sideDistY = sideDistY + deltaDistY
                mapY = mapY + stepY
                side = 1
            end

            -- Проверка на границы карты во избежание вылетов и дыр
            if mapX < 1 or mapX > MAP_SIZE or mapY < 1 or mapY > MAP_SIZE then
                hit = 1
            elseif map[mapY][mapX] > 0 then
                hit = 1
            end
        end

        -- Перпендикулярная дистанция до стены (убирает эффекты рыбьего глаза)
        local perpWallDist
        if side == 0 then
            perpWallDist = (mapX - posX + (1 - stepX) / 2) / rayDirX
        else
            perpWallDist = (mapY - posY + (1 - stepY) / 2) / rayDirY
        end

        if perpWallDist < 0.01 then perpWallDist = 0.01 end

        -- Расчет высоты стены
        local lineHeight = math.floor(H / perpWallDist)
        local drawStart = math.floor(-lineHeight / 2 + H / 2)
        local drawEnd = math.floor(lineHeight / 2 + H / 2)

        local yMin = math.max(1, drawStart)
        local yMax = math.min(H, drawEnd)

        local wallColor = (side == 1) and WALL_DARK or WALL_LIGHT

        -- Заполнение столбца x
        for y = 1, H do
            if y < yMin then
                screenBG[y][x] = SKY_COLOR
            elseif y > yMax then
                screenBG[y][x] = FLOOR_COLOR
            else
                screenBG[y][x] = wallColor
            end
            screenFG[y][x] = "0" -- Заглушка цвета текста
        end
    end

    -- Отрисовка готового кадра на монитор без лагов
    local emptyText = string.rep(" ", W)
    for y = 1, H do
        monitor.setCursorPos(1, y)
        monitor.blit(emptyText, table.concat(screenFG[y]), table.concat(screenBG[y]))
    end
end

local function update(dt)
    local moveStep = moveSpeed * dt
    local rotStep = rotSpeed * dt

    local rot = 0
    if keysHeld.right then rot = rot - rotStep end
    if keysHeld.left then rot = rot + rotStep end

    if rot ~= 0 then
        local oldDirX = dirX
        dirX = dirX * math.cos(rot) - dirY * math.sin(rot)
        dirY = oldDirX * math.sin(rot) + dirY * math.cos(rot)

        local oldPlaneX = planeX
        planeX = planeX * math.cos(rot) - planeY * math.sin(rot)
        planeY = oldPlaneX * math.sin(rot) + planeY * math.cos(rot)
    end

    local dx, dy = 0, 0
    if keysHeld.forward then dx = dx + dirX * moveStep; dy = dy + dirY * moveStep end
    if keysHeld.back then dx = dx - dirX * moveStep; dy = dy - dirY * moveStep end

    if dx ~= 0 then
        local targetX = posX + dx
        local checkX = dx > 0 and (targetX + RADIUS) or (targetX - RADIUS)
        if map[math.floor(posY)] and map[math.floor(posY)][math.floor(checkX)] == 0 then
            posX = targetX
        end
    end

    if dy ~= 0 then
        local targetY = posY + dy
        local checkY = dy > 0 and (targetY + RADIUS) or (targetY - RADIUS)
        if map[math.floor(checkY)] and map[math.floor(checkY)][math.floor(posX)] == 0 then
            posY = targetY
        end
    end
end

local lastTime = os.clock()
while true do
    local now = os.clock()
    local dt = math.min(now - lastTime, 0.05)
    lastTime = now

    update(dt)
    render()

    local timerId = os.startTimer(0.001)
    while true do
        local event, p1, p2, p3, p4 = os.pullEvent()
        if event == "modem_message" and p2 == CHANNEL then
            if type(p4) == "table" and p4.action then
                keysHeld[p4.action] = p4.state
            end
        elseif event == "timer" and p1 == timerId then
            break
        end
    end
end
