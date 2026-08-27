-- 3D Raycast Server with Pixelbox Lite
local pixelbox = require("pixelbox_lite")

local monitor = peripheral.wrap("left") or term.current()
if monitor.setTextScale then
    monitor.setTextScale(0.5)
end

local box = pixelbox.new(monitor, colors.black)
local w, h = box.width, box.height

local x, y = 4.5, 4.5
local dirX, dirY = -1, 0
local planeX, planeY = 0, 0.66

local map = {
    {1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,1},
    {1,0,1,0,0,1,0,1},
    {1,0,0,0,0,0,0,1},
    {1,0,1,0,0,1,0,1},
    {1,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1},
}
local mapSize = 8

-- Ищем модем на любой стороне (включая беспроводной)
local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        modemSide = side
        break
    end
end

if not modemSide then
    error("Беспроводной модем не найден! Установите его на компьютер.")
end

rednet.open(modemSide)
print("Сервер запущен! Мой ID: " .. os.getComputerID())
print("Ожидание сигналов от пульта...")

local function rotate(angle)
    local oldDirX = dirX
    dirX = dirX * math.cos(angle) - dirY * math.sin(angle)
    dirY = oldDirX * math.sin(angle) + dirY * math.cos(angle)
    
    local oldPlaneX = planeX
    planeX = planeX * math.cos(angle) - planeY * math.sin(angle)
    planeY = oldPlaneX * math.sin(angle) + planeY * math.cos(angle)
end

local function render()
    local halfH = math.floor(h / 2)
    for py = 1, h do
        local color = (py <= halfH) and colors.lightBlue or colors.green
        for px = 1, w do
            box.canvas[py][px] = color
        end
    end

    for col = 1, w do
        local cameraX = 2 * col / w - 1
        local rayDirX = dirX + planeX * cameraX
        local rayDirY = dirY + planeY * cameraX

        local mapX = math.floor(x)
        local mapY = math.floor(y)

        local deltaDistX = math.abs(1 / rayDirX)
        local deltaDistY = math.abs(1 / rayDirY)

        local sideDistX, sideDistY
        local stepX, stepY
        local hit = 0
        local side = 0

        if rayDirX < 0 then
            stepX = -1
            sideDistX = (x - mapX) * deltaDistX
        else
            stepX = 1
            sideDistX = (mapX + 1.0 - x) * deltaDistX
        end

        if rayDirY < 0 then
            stepY = -1
            sideDistY = (y - mapY) * deltaDistY
        else
            stepY = 1
            sideDistY = (mapY + 1.0 - y) * deltaDistY
        end

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

            if mapX < 1 or mapX > mapSize or mapY < 1 or mapY > mapSize then
                hit = 1
            elseif map[mapY][mapX] > 0 then
                hit = 1
            end
        end

        local perpWallDist
        if side == 0 then
            perpWallDist = (mapX - x + (1 - stepX) / 2) / rayDirX
        else
            perpWallDist = (mapY - y + (1 - stepY) / 2) / rayDirY
        end

        if perpWallDist < 0.05 then perpWallDist = 0.05 end

        local lineHeight = math.floor(h / perpWallDist)
        local drawStart = math.max(1, math.floor(-lineHeight / 2 + halfH))
        local drawEnd = math.min(h, math.floor(lineHeight / 2 + halfH))

        local wallColor = (side == 1) and colors.gray or colors.lightGray
        for row = drawStart, drawEnd do
            box.canvas[row][col] = wallColor
        end
    end

    box:render()
end

monitor.clear()

while true do
    render()
    
    -- Проверяем события rednet с небольшим таймаутом, чтобы игра не зависала, если нет нажатий
    local success, event, senderId, message = pcall(os.pullEvent, "rednet_message")
    
    if success and event == "rednet_message" then
        if type(message) == "table" and message.type == "key" then
            local moveSpeed = 0.3
            local rotSpeed = 0.25
            local key = message.key

            if key == keys.w or key == keys.up then
                x = x + dirX * moveSpeed
                y = y + dirY * moveSpeed
            elseif key == keys.s or key == keys.down then
                x = x - dirX * moveSpeed
                y = y - dirY * moveSpeed
            elseif key == keys.a or key == keys.left then
                rotate(rotSpeed)
            elseif key == keys.d or key == keys.right then
                rotate(-rotSpeed)
            elseif key == keys.x then
                monitor.clear()
                print("Выход.")
                break
            end
        end
    end
end
