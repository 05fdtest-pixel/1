local pixelbox = require("pixelbox")

local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)

local box = pixelbox.new(monitor)
local W, H = box.width, box.height

-- Цветовая палитра
local SKY_COLOR = colors.cyan
local FLOOR_COLOR_1 = colors.green
local FLOOR_COLOR_2 = colors.lime

-- Серые стены и столбы одного цвета
local WALL_LIGHT = colors.lightGray
local WALL_DARK = colors.gray

-- Карта 12x12 (1 - стены, 2 - столбы)
local MAP_SIZE = 12
local map = {
    {1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,1,1,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,2,0,0,0,0,2,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,0,0,0,0,0,0,0,0,1,1},
    {1,1,0,0,0,0,0,0,0,0,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,2,0,0,0,0,2,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,1,1,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1}
}

-- Игрок
local posX, posY = 2.5, 2.5
local dirX, dirY = 1.0, 0.0

local FOV = 0.66
local planeX, planeY = 0.0, FOV * (H / W) * 0.85

local moveSpeed = 3.0
local rotSpeed = 2.0
local RADIUS = 0.25

local keysHeld = { forward = false, back = false, left = false, right = false }

local function render()
    local halfH = math.floor(H / 2)
    
    -- 1. Небо
    box:box(1, 1, W, halfH, SKY_COLOR)
    
    -- 2. Пол с сеткой для объема
    for y = halfH + 1, H do
        local col = (y % 2 == 0) and FLOOR_COLOR_1 or FLOOR_COLOR_2
        box:line(1, y, W, y, col)
    end

    -- 3. Лучи
    for x = 1, W do
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

            if mapX < 1 or mapX > MAP_SIZE or mapY < 1 or mapY > MAP_SIZE then
                hit = 1
            elseif map[mapY][mapX] > 0 then
                hit = 1
            end
        end

        local perpWallDist
        if side == 0 then
            perpWallDist = (mapX - posX + (1 - stepX) / 2) / rayDirX
        else
            perpWallDist = (mapY - posY + (1 - stepY) / 2) / rayDirY
        end

        if perpWallDist < 0.01 then perpWallDist = 0.01 end

        local lineHeight = math.floor(H / perpWallDist)
        local drawStart = math.floor(-lineHeight / 2 + H / 2)
        local drawEnd = math.floor(lineHeight / 2 + H / 2)

        local yMin = math.max(1, drawStart)
        local yMax = math.min(H, drawEnd)

        -- И стены, и столбы выкрашены в единый серый цвет
        local wallColor = (side == 1) and WALL_DARK or WALL_LIGHT

        box:line(x, yMin, x, yMax, wallColor)
    end

    box:render()
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
