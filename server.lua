local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)
monitor.clear()

local MW, MH = monitor.getSize()
local W = MW
local H = MH * 2 -- Двойное вертикальное разрешение за счет спецсимволов

-- Цвета
local SKY_COLOR = colors.cyan
local FLOOR_COLOR = colors.green
local WALL_MAIN = colors.lightGray
local WALL_SHADE = colors.gray

-- Карта помещения
local map = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
}

-- Игрок
local posX, posY = 5.0, 5.0
local dirX, dirY = -1.0, 0.0
-- Увеличенный вектор обзора (plane), чтобы стены не обрезались по бокам
local planeX, planeY = 0.0, 0.75 

local moveSpeed = 3.5
local rotSpeed = 2.5
local RADIUS = 0.2

local keysHeld = { forward = false, back = false, left = false, right = false }

-- Виртуальный пиксельный буфер (W x H)
local buffer = {}
for y = 1, H do
    buffer[y] = {}
end

local function clearBuffer()
    local halfH = math.floor(H / 2)
    for y = 1, halfH do
        local row = buffer[y]
        for x = 1, W do row[x] = SKY_COLOR end
    end
    for y = halfH + 1, H do
        local row = buffer[y]
        for x = 1, W do row[x] = FLOOR_COLOR end
    end
end

local function drawVerticalLine(x, yMin, yMax, color)
    if yMin < 1 then yMin = 1 end
    if yMax > H then yMax = H end
    for y = yMin, yMax do
        buffer[y][x] = color
    end
end

-- Мгновенный вывод буфера без мерцаний через blit
local function flushBuffer()
    for cy = 1, MH do
        local topY = (cy - 1) * 2 + 1
        local botY = topY + 1
        
        local topRow = buffer[topY]
        local botRow = buffer[botY]
        
        local tChars, tFG, tBG = {}, {}, {}
        for x = 1, W do
            tChars[x] = "\157" -- Нижний полублок
            tFG[x] = colors.toBlit(botRow[x])
            tBG[x] = colors.toBlit(topRow[x])
        end
        
        monitor.setCursorPos(1, cy)
        monitor.blit(table.concat(tChars), table.concat(tFG), table.concat(tBG))
    end
end

local function render()
    clearBuffer()

    -- ASPECT_RATIO компенсирует прямоугольность символов терминов Minecraft
    local ASPECT_RATIO = 1.6 

    for x = 1, W do
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

        local hit = 0
        local side = 0

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

        local perpWallDist
        if side == 0 then
            perpWallDist = (mapX - posX + (1 - stepX) / 2) / rayDirX
        else
            perpWallDist = (mapY - posY + (1 - stepY) / 2) / rayDirY
        end

        if perpWallDist < 0.05 then perpWallDist = 0.05 end

        -- Умножение на ASPECT_RATIO подтягивает высоту стены до нормального 3D вида
        local lineHeight = math.floor((H / perpWallDist) * ASPECT_RATIO)
        local drawStart = math.floor(-lineHeight / 2 + H / 2)
        local drawEnd = math.floor(lineHeight / 2 + H / 2)

        local col = (side == 1) and WALL_SHADE or WALL_MAIN
        drawVerticalLine(x, drawStart, drawEnd, col)
    end

    flushBuffer()
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
