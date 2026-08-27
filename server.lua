-- Подключение периферии
local monitor = peripheral.wrap("left") or error("Подключите монитор СЛЕВА!")
local modem = peripheral.wrap("right") or error("Подключите Wireless Modem СПРАВА!")

local CHANNEL = 15
modem.open(CHANNEL)

-- Настройка монитора 4x4
monitor.setTextScale(0.5) -- Мелкий шрифт для максимума деталей
monitor.clear()

local MW, MH = monitor.getSize()
local W, H = MW, MH * 2 -- Pixelbox: 1 символ по вертикали = 2 пикселя

-- Цветовая палитра
local SKY_COLOR = colors.cyan
local FLOOR_COLOR = colors.green
local WALL_MAIN = colors.lightGray
local WALL_SHADE = colors.gray

-- Карта 10x10 (1 - стена, 0 - пусто)
local map = {
    {1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,1,0,0,0,1},
    {1,0,1,1,0,1,0,1,0,1},
    {1,0,1,0,0,0,0,1,0,1},
    {1,0,1,0,1,1,0,1,0,1},
    {1,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1}
}

-- Игрок и физика
local posX, posY = 2.5, 2.5
local dirX, dirY = -1, 0
local planeX, planeY = 0, 0.66

local moveSpeed = 3.0  -- Ограничение скорости хода
local rotSpeed = 2.2   -- Ограничение скорости поворота
local RADIUS = 0.25    -- Радиус коллизии со стенами

local keysHeld = { forward = false, back = false, left = false, right = false }

-- Буфер Pixelbox
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

-- Рендеринг сцены
local function render()
    -- Отрисовка Неба и Пола
    for x = 1, W do
        for y = 1, H / 2 do setPixel(x, y, SKY_COLOR) end
        for y = H / 2 + 1, H do setPixel(x, y, FLOOR_COLOR) end
    end

    -- Рейкастинг стен
    for x = 1, W do
        local cameraX = 2 * x / W - 1
        local rayDirX = dirX + planeX * cameraX
        local rayDirY = dirY + planeY * cameraX

        local mapX, mapY = math.floor(posX), math.floor(posY)
        local deltaDistX = math.abs(1 / rayDirX)
        local deltaDistY = math.abs(1 / rayDirY)

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
            if map[mapY] and map[mapY][mapX] > 0 then hit = 1 end
        end

        local perpWallDist = (side == 0) and (sideDistX - deltaDistX) or (sideDistY - deltaDistY)
        local lineHeight = math.floor(H / perpWallDist)

        local drawStart = math.max(1, math.floor(-lineHeight / 2 + H / 2))
        local drawEnd = math.min(H, math.floor(lineHeight / 2 + H / 2))

        -- Теневой цвет для боковых граней стен (темно-серый)
        local color = (side == 1) and WALL_SHADE or WALL_MAIN
        for y = drawStart, drawEnd do
            setPixel(x, y, color)
        end
    end

    drawPixelbox()
end

-- Физика с ограничением скорости и коллизиями
local function updatePhysics(dt)
    local moveStep = moveSpeed * dt
    local rotStep = rotSpeed * dt

    -- Вращение
    local r = 0
    if keysHeld.right then r = r - rotStep end
    if keysHeld.left then r = r + rotStep end
    if r ~= 0 then
        local oldDirX = dirX
        dirX = dirX * math.cos(r) - dirY * math.sin(r)
        dirY = oldDirX * math.sin(r) + dirY * math.cos(r)
        local oldPlaneX = planeX
        planeX = planeX * math.cos(r) - planeY * math.sin(r)
        planeY = oldPlaneX * math.sin(r) + planeY * math.cos(r)
    end

    -- Движение
    local dx, dy = 0, 0
    if keysHeld.forward then dx = dx + dirX * moveStep; dy = dy + dirY * moveStep end
    if keysHeld.back then dx = dx - dirX * moveStep; dy = dy - dirY * moveStep end

    -- Проверка столкновений
    if dx ~= 0 then
        local newX = posX + dx
        local checkX = dx > 0 and (newX + RADIUS) or (newX - RADIUS)
        if map[math.floor(posY)][math.floor(checkX)] == 0 then posX = newX end
    end
    if dy ~= 0 then
        local newY = posY + dy
        local checkY = dy > 0 and (newY + RADIUS) or (newY - RADIUS)
        if map[math.floor(checkY)][math.floor(posX)] == 0 then posY = newY end
    end
end

-- Главный игровой цикл
local lastTime = os.clock()
while true do
    local now = os.clock()
    local dt = math.min(now - lastTime, 0.1) -- Защита от резких скачков dt
    lastTime = now

    updatePhysics(dt)
    render()

    -- Обработка сетевых команд без задержек
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
