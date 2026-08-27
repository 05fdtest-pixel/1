local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)
monitor.clear()

local termW, termH = monitor.getSize()
-- Максимальное разрешение: 2 пикселя по горизонтали, 3 по вертикали на символ
local W = termW * 2
local H = termH * 3

local SKY_COLOR = colors.cyan
local FLOOR_COLOR = colors.green
local WALL_LIGHT = colors.lightGray
local WALL_DARK = colors.gray

-- Просторная карта с широкими туннелями
local map = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,1,1,1,0,0,1,1,1,1,0,0,1},
    {1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1},
    {1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1},
    {1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1},
    {1,0,0,1,1,1,1,0,0,1,1,1,1,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
}

local posX, posY = 2.5, 2.5
local dirX, dirY = -1, 0
-- Исправленный FOV (угол обзора ~66 градусов)
local planeX, planeY = 0, 0.66

local moveSpeed = 4.0
local rotSpeed = 3.0
local RADIUS = 0.2

local keysHeld = { forward = false, back = false, left = false, right = false }

-- Буфер пикселей (W x H)
local pixelBuf = {}
for y = 1, H do
    pixelBuf[y] = {}
end

local function clearBuffer()
    for y = 1, math.floor(H / 2) do
        local row = pixelBuf[y]
        for x = 1, W do row[x] = SKY_COLOR end
    end
    for y = math.floor(H / 2) + 1, H do
        local row = pixelBuf[y]
        for x = 1, W do row[x] = FLOOR_COLOR end
    end
end

-- Отрисовка 2x3 пикселей на символ
local function drawBuffer()
    for ty = 1, termH do
        monitor.setCursorPos(1, ty)
        local y1 = (ty - 1) * 3 + 1
        local y2 = y1 + 1
        local y3 = y1 + 2

        local charRow, fgRow, bgRow = {}, {}, {}

        for tx = 1, termW do
            local x1 = (tx - 1) * 2 + 1
            local x2 = x1 + 1

            -- Считываем 6 sub-пикселей
            local c1 = pixelBuf[y1][x1]
            local c2 = pixelBuf[y1][x2]
            local c3 = pixelBuf[y2][x1]
            local c4 = pixelBuf[y2][x2]
            local c5 = pixelBuf[y3][x1]
            local c6 = pixelBuf[y3][x2]

            -- Преобладающий цвет заднего фона
            local bg = c1
            local fg = c1
            if c2 ~= bg then fg = c2
            elseif c3 ~= bg then fg = c3
            elseif c4 ~= bg then fg = c4
            elseif c5 ~= bg then fg = c5
            elseif c6 ~= bg then fg = c6 end

            -- Формирование маски символа 2x3
            local mask = 0
            if c1 == fg then mask = mask + 1 end
            if c2 == fg then mask = mask + 2 end
            if c3 == fg then mask = mask + 4 end
            if c4 == fg then mask = mask + 8 end
            if c5 == fg then mask = mask + 16 end
            if c6 == fg then mask = mask + 32 end

            local ch = " "
            if mask == 63 then
                ch = "\157"
            elseif mask > 0 then
                ch = string.char(128 + mask)
            end

            charRow[tx] = ch
            fgRow[tx] = colors.toBlit(fg)
            bgRow[tx] = colors.toBlit(bg)
        end

        monitor.blit(table.concat(charRow), table.concat(fgRow), table.concat(bgRow))
    end
end

local function render()
    clearBuffer()

    -- Точный физический аспект пикселей Minecraft
    local aspectCorrection = (W / H) * 0.75

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

        -- Вычисление перпендикулярного расстояния без трапецеидальных искажений
        local perpWallDist
        if side == 0 then
            perpWallDist = (mapX - posX + (1 - stepX) / 2) / rayDirX
        else
            perpWallDist = (mapY - posY + (1 - stepY) / 2) / rayDirY
        end

        if perpWallDist < 0.05 then perpWallDist = 0.05 end

        local lineHeight = math.floor((H / perpWallDist) * aspectCorrection)

        local drawStart = math.floor(-lineHeight / 2 + H / 2)
        local drawEnd = math.floor(lineHeight / 2 + H / 2)

        local yMin = math.max(1, drawStart)
        local yMax = math.min(H, drawEnd)

        local col = (side == 1) and WALL_DARK or WALL_LIGHT
        for y = yMin, yMax do
            pixelBuf[y][x] = col
        end
    end

    drawBuffer()
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
