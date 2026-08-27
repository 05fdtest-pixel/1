local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)
monitor.clear()

local termW, termH = monitor.getSize()
local W = termW
local H = termH * 2

local SKY_COLOR = colors.cyan
local FLOOR_COLOR = colors.green
local WALL_LIGHT = colors.lightGray
local WALL_DARK = colors.gray

local map = {
    {1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,1,1,1,1,1,0,0,1},
    {1,0,0,1,0,0,0,0,1,0,0,1},
    {1,0,0,1,0,0,0,0,1,0,0,1},
    {1,0,0,1,0,0,0,0,1,0,0,1},
    {1,0,0,1,1,0,0,1,1,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1}
}

local posX, posY = 2.5, 2.5
local dirX, dirY = -1, 0
local planeX, planeY = 0, 0.66

local moveSpeed = 3.5
local rotSpeed = 2.5
local RADIUS = 0.2

local keysHeld = { forward = false, back = false, left = false, right = false }

local topBuf, botBuf = {}, {}
for y = 1, termH do
    topBuf[y] = {}
    botBuf[y] = {}
end

local function setPixel(x, y, col)
    if x < 1 or x > W or y < 1 or y > H then return end
    local cellY = math.floor((y - 1) / 2) + 1
    if (y - 1) % 2 == 0 then
        topBuf[cellY][x] = col
    else
        botBuf[cellY][x] = col
    end
end

local function flushScreen()
    for y = 1, termH do
        monitor.setCursorPos(1, y)
        local tRow, bRow = topBuf[y], botBuf[y]
        local tStr, bStr = {}, {}
        for x = 1, W do
            tStr[x] = colors.toBlit(tRow[x])
            bStr[x] = colors.toBlit(bRow[x])
        end
        monitor.blit(string.rep("\157", W), table.concat(tStr), table.concat(bStr))
    end
end

local function render()
    for x = 1, W do
        for y = 1, math.floor(H / 2) do
            setPixel(x, y, SKY_COLOR)
        end
        for y = math.floor(H / 2) + 1, H do
            setPixel(x, y, FLOOR_COLOR)
        end
    end

    -- Коэффициент коррекции геометрии пикселей CraftOS для 1:1 соотношения
    local aspectCorrection = 0.6

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
            perpWallDist = sideDistX - deltaDistX
        else
            perpWallDist = sideDistY - deltaDistY
        end

        if perpWallDist < 0.05 then perpWallDist = 0.05 end

        local lineHeight = math.floor((H / perpWallDist) * aspectCorrection)

        local drawStart = math.floor(-lineHeight / 2 + H / 2)
        local drawEnd = math.floor(lineHeight / 2 + H / 2)

        local yMin = math.max(1, drawStart)
        local yMax = math.min(H, drawEnd)

        local col = (side == 1) and WALL_DARK or WALL_LIGHT
        for y = yMin, yMax do
            setPixel(x, y, col)
        end
    end

    flushScreen()
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
