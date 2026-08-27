local pixelbox = require("pixelbox_lite")

local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

if not monitor then error("Монитор не найден!") end
if not modem then error("Модем не найден!") end

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)

local box = pixelbox.new(monitor)
local W, H = box.width, box.height

-- Цвета
local SKY_COLOR = colors.cyan
local FLOOR_COLOR = colors.green

local WALL_LIGHT = colors.lightGray
local WALL_DARK = colors.gray

-- Симметричная карта 11x11
local MAP_SIZE = 11
local map = {
    {1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,0,0,0,1,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,0,0,0,1,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1}
}

-- Старт в центре
local posX, posY = 6.0, 6.0
local dirX, dirY = 1.0, 0.0

local FOV = 0.66
local planeX, planeY = 0.0, FOV * (H / W)

local moveSpeed = 3.0
local rotSpeed = 2.0
local RADIUS = 0.2 -- Уменьшенный радиус коллизии, чтобы не липнуть к углам

local keysHeld = { forward = false, back = false, left = false, right = false }

local function isWall(x, y)
    local mx, my = math.floor(x), math.floor(y)
    if mx < 1 or mx > MAP_SIZE or my < 1 or my > MAP_SIZE then return true end
    return map[my][mx] == 1
end

local function render()
    local halfH = math.floor(H / 2)
    local canvas = box.canvas

    -- 1. Очистка фона (Небо и Зеленый пол)
    for y = 1, H do
        local row = canvas[y]
        if y <= halfH then
            for x = 1, W do row[x] = SKY_COLOR end
        else
            for x = 1, W do row[x] = FLOOR_COLOR end
        end
    end

    -- 2. Трассировка лучей высокой четкости
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

        if perpWallDist < 0.0001 then perpWallDist = 0.0001 end

        local lineHeight = math.floor(H / perpWallDist)
        local drawStart = math.floor(-lineHeight / 2 + H / 2)
        local drawEnd = math.floor(lineHeight / 2 + H / 2)

        local yMin = math.max(1, drawStart)
        local yMax = math.min(H, drawEnd)

        local wallColor = (side == 1) and WALL_DARK or WALL_LIGHT

        for y = yMin, yMax do
            canvas[y][x] = wallColor
        end
    end

    box:render()
end

local function update(dt)
    local moveStep = moveSpeed * dt
    local rotStep = rotSpeed * dt

    local rot = 0
    if keysHeld.right then rot = rot + rotStep end
    if keysHeld.left then rot = rot - rotStep end

    if rot ~= 0 then
        local oldDirX = dirX
        dirX = dirX * math.cos(rot) - dirY * math.sin(rot)
        dirY = oldDirX * math.sin(rot) + dirY * math.cos(rot)

        local oldPlaneX = planeX
        planeX = planeX * math.cos(rot) - planeY * math.sin(rot)
        planeY = oldPlaneX * math.sin(rot) + planeY * math.cos(rot)
    end

    local moveX, moveY = 0, 0
    if keysHeld.forward then 
        moveX = moveX + dirX * moveStep 
        moveY = moveY + dirY * moveStep 
    end
    if keysHeld.back then 
        moveX = moveX - dirX * moveStep 
        moveY = moveY - dirY * moveStep 
    end

    -- Раздельная плавная коллизия по осям (обеспечивает скольжение вдоль стен)
    if moveX ~= 0 then
        local targetX = posX + moveX
        local checkX = moveX > 0 and (targetX + RADIUS) or (targetX - RADIUS)
        if not isWall(checkX, posY - RADIUS) and not isWall(checkX, posY + RADIUS) then
            posX = targetX
        end
    end

    if moveY ~= 0 then
        local targetY = posY + moveY
        local checkY = moveY > 0 and (targetY + RADIUS) or (targetY - RADIUS)
        if not isWall(posX - RADIUS, checkY) and not isWall(posX + RADIUS, checkY) then
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

    -- Обработка сетевых событий и таймера кадра без фризов
    local timerId = os.startTimer(0.01)
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
