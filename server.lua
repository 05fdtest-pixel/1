local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)
monitor.clear()

local MW, MH = monitor.getSize()
local W, H = MW, MH * 2

local SKY_COLOR = colors.cyan
local FLOOR_COLOR = colors.green
local WALL_MAIN = colors.lightGray
local WALL_SHADE = colors.gray

-- Просторная квадратная карта с широкими коридорами
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
local dirX, dirY = 0, 1

-- Корректировка угла обзора под пропорции монитора (убирает fish-eye)
local aspect = W / H
local fov = 0.66
local planeX, planeY = -fov * dirY * aspect, fov * dirX * aspect

local moveSpeed = 3.5
local rotSpeed = 2.5
local RADIUS = 0.2

local keysHeld = { forward = false, back = false, left = false, right = false }

local topColors, botColors = {}, {}
for y = 1, MH do
    topColors[y], botColors[y] = {}, {}
end

local function setPixel(x, y, color)
    local my = math.floor((y - 1) / 2) + 1
    if y % 2 == 1 then
        topColors[my][x] = color
    else
        botColors[my][x] = color
    end
end

local function drawPixelbox()
    for y = 1, MH do
        monitor.setCursorPos(1, y)
        local tRow, bRow = topColors[y], botColors[y]
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
        for y = 1, H / 2 do setPixel(x, y, SKY_COLOR) end
        for y = H / 2 + 1, H do setPixel(x, y, FLOOR_COLOR) end
    end

    for x = 1, W do
        local cameraX = 2 * x / W - 1
        local rayDirX = dirX + planeX * cameraX
        local rayDirY = dirY + planeY * cameraX

        local mapX, mapY = math.floor(posX), math.floor(posY)
        
        local deltaDistX = (rayDirX == 0) and 1e30 or math.abs(1 / rayDirX)
        local deltaDistY = (rayDirY == 0) and 1e30 or math.abs(1 / rayDirY)

        local stepX, stepY
        local sideDistX, sideDistY

        if rayDirX < 0 then
            stepX, sideDistX = -1, (posX - mapX) * deltaDistX
        else
            stepX, sideDistX = 1, (mapX + 1.0 - posX) * deltaDistX
        end

        if rayDirY < 0 then
            stepY, sideDistY = -1, (posY - mapY) * deltaDistY
        else
            stepY, sideDistY = 1, (mapY + 1.0 - posY) * deltaDistY
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
            if map[mapY] and map[mapY][mapX] and map[mapY][mapX] > 0 then hit = 1 end
        end

        local perpWallDist
        if side == 0 then
            perpWallDist = (mapX - posX + (1 - stepX) / 2) / rayDirX
        else
            perpWallDist = (mapY - posY + (1 - stepY) / 2) / rayDirY
        end

        if perpWallDist < 0.05 then perpWallDist = 0.05 end

        local lineHeight = math.floor(H / perpWallDist)

        local drawStart = math.floor(-lineHeight / 2 + H / 2)
        local drawEnd = math.floor(lineHeight / 2 + H / 2)

        local clampStart = math.max(1, drawStart)
        local clampEnd = math.min(H, drawEnd)

        local color = (side == 1) and WALL_SHADE or WALL_MAIN
        for y = clampStart, clampEnd do
            setPixel(x, y, color)
        end
    end

    drawPixelbox()
end

local function updatePhysics(dt)
    local moveStep = moveSpeed * dt
    local rotStep = rotSpeed * dt

    local r = 0
    if keysHeld.right then r = r - rotStep end
    if keysHeld.left then r = r + rotStep end
    if r ~= 0 then
        local oldDirX = dirX
        dirX = dirX * math.cos(r) - dirY * math.sin(r)
        dirY = oldDirX * math.sin(r) + dirY * math.cos(r)

        planeX = -fov * dirY * aspect
        planeY = fov * dirX * aspect
    end

    local dx, dy = 0, 0
    if keysHeld.forward then dx = dx + dirX * moveStep; dy = dy + dirY * moveStep end
    if keysHeld.back then dx = dx - dirX * moveStep; dy = dy - dirY * moveStep end

    if dx ~= 0 then
        local newX = posX + dx
        local checkX = dx > 0 and (newX + RADIUS) or (newX - RADIUS)
        if map[math.floor(posY)] and map[math.floor(posY)][math.floor(checkX)] == 0 then 
            posX = newX 
        end
    end
    if dy ~= 0 then
        local newY = posY + dy
        local checkY = dy > 0 and (newY + RADIUS) or (newY - RADIUS)
        if map[math.floor(checkY)] and map[math.floor(checkY)][math.floor(posX)] == 0 then 
            posY = newY 
        end
    end
end

local lastTime = os.clock()
while true do
    local now = os.clock()
    local dt = math.min(now - lastTime, 0.05)
    lastTime = now

    updatePhysics(dt)
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
