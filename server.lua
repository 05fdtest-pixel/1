local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)
monitor.clear()

local MW, MH = monitor.getSize()
local W = MW
local H = MH * 2

local SKY_COLOR = colors.cyan
local FLOOR_COLOR = colors.green
local WALL_MAIN = colors.lightGray
local WALL_SHADE = colors.gray

-- Карта с БОЛЬШИМИ квадратными комнатами и широкими туннелями
local map = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,1,1,0,0,0,0,0,1},
    {1,0,0,0,0,0,1,1,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,1,1,0,0,0,0,0,1},
    {1,0,0,0,0,0,1,1,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1}
}

-- Старт игрока в центре квадратного зала
local posX, posY = 3.5, 3.5
local dirAngle = 0 -- Угол поворота (в радианах)

local moveSpeed = 3.5
local rotSpeed = 2.5
local RADIUS = 0.2

local keysHeld = { forward = false, back = false, left = false, right = false }

-- Буферы строк цвета (верхняя и нижняя половина символа)
local topRow, botRow = {}, {}
for y = 1, MH do
    topRow[y] = {}
    botRow[y] = {}
end

local function setPixel(x, y, color)
    if x < 1 or x > W or y < 1 or y > H then return end
    local my = math.floor((y - 1) / 2) + 1
    if y % 2 == 1 then
        topRow[my][x] = color
    else
        botRow[my][x] = color
    end
end

local function drawPixelbox()
    for y = 1, MH do
        monitor.setCursorPos(1, y)
        local tR, bR = topRow[y], botRow[y]
        local tStr, bStr = {}, {}
        for x = 1, W do
            tStr[x] = colors.toBlit(tR[x])
            bStr[x] = colors.toBlit(bR[x])
        end
        monitor.blit(string.rep("\157", W), table.concat(tStr), table.concat(bStr))
    end
end

local function render()
    -- Очистка фона
    for x = 1, W do
        for y = 1, MH do
            topRow[y][x] = SKY_COLOR
            botRow[y][x] = FLOOR_COLOR
        end
    end

    -- Вектор направления взгляда
    local dirX = math.cos(dirAngle)
    local dirY = math.sin(dirAngle)

    -- Вектор плоскости экрана (FOV ~ 66 градусов)
    local fov = 0.66
    local planeX = -dirY * fov
    local planeY = dirX * fov

    for x = 1, W do
        -- Отклонение луча от центра экрана (-1..1)
        local cameraX = 2 * (x - 1) / W - 1
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

        local hit, side = 0, 0
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
            if map[mapY] and map[mapY][mapX] and map[mapY][mapX] > 0 then
                hit = 1
            end
        end

        -- ВАЖНО: Точная перпендикулярная дистанция убирает рыбий глаз
        local perpWallDist
        if side == 0 then
            perpWallDist = (mapX - posX + (1 - stepX) / 2) / rayDirX
        else
            perpWallDist = (mapY - posY + (1 - stepY) / 2) / rayDirY
        end

        if perpWallDist < 0.01 then perpWallDist = 0.01 end

        -- Пропорция высоты: 1.0 для абсолютного квадрата
        local lineHeight = math.floor(H / perpWallDist)

        local drawStart = math.floor(-lineHeight / 2 + H / 2)
        local drawEnd = math.floor(lineHeight / 2 + H / 2)

        local yMin = math.max(1, drawStart)
        local yMax = math.min(H, drawEnd)

        local wallColor = (side == 1) and WALL_SHADE or WALL_MAIN
        for y = yMin, yMax do
            setPixel(x, y, wallColor)
        end
    end

    drawPixelbox()
end

local function update(dt)
    local moveStep = moveSpeed * dt
    local rotStep = rotSpeed * dt

    if keysHeld.right then dirAngle = dirAngle + rotStep end
    if keysHeld.left then dirAngle = dirAngle - rotStep end

    local dirX = math.cos(dirAngle)
    local dirY = math.sin(dirAngle)

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
