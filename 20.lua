local pixelbox = require("pixelbox_lite")

local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11") or term.current()
local modem = peripheral.wrap("right") or peripheral.find("modem")

if not monitor then error("Монитор не найден!") end

monitor.setTextScale(0.5)

local box = pixelbox.new(monitor)
local W, H = box.width, box.height

-- Радиус обзора спутника (сколько блоков вокруг игрока захватывать)
local RADIUS = 8
local MAP_SIZE = (RADIUS * 2) + 1

local function renderRealMap(playerX, playerY, playerZ, heading)
    -- Очищаем экран (фон)
    for y = 1, H do
        for x = 1, W do
            box.canvas[y][x] = colors.black
        end
    end

    local scaleX = math.floor(W / MAP_SIZE)
    local scaleY = math.floor(H / MAP_SIZE)
    local scale = math.min(scaleX, scaleY)
    scale = math.max(scale, 2)

    -- Сканируем блоки вокруг игрока в реальном мире Minecraft
    -- Требуется подключенный датчик/модем или стандартные функции мира, если они доступны,
    -- либо прием данных от черепахи/спутника в мире.
    for dz = -RADIUS, RADIUS do
        for dx = -RADIUS, RADIUS do
            local worldX = math.floor(playerX + dx)
            local worldZ = math.floor(playerZ + dz)

            -- Пример определения цвета блока (в CC:Tweaked можно использовать world.getBlockData или geoscanner)
            -- Здесь для демонстрации рисуем сетку на основе координат
            local color = colors.lightGray
            if (worldX + worldZ) % 2 == 0 then
                color = colors.gray
            end

            local screenX = (dx + RADIUS) * scale + 1
            local screenY = (dz + RADIUS) * scale + 1

            for py = screenY, screenY + scale - 1 do
                for px = screenX, screenX + scale - 1 do
                    if px <= W and py <= H then
                        box.canvas[py][px] = color
                    end
                end
            end
        end
    end

    -- Рисуем маркер игрока в центре
    local centerX = RADIUS * scale + math.floor(scale / 2)
    local centerY = RADIUS * scale + math.floor(scale / 2)

    if centerX >= 1 and centerX <= W and centerY >= 1 and centerY <= H then
        box.canvas[centerY][centerX] = colors.red
    end

    box:render()
end

-- Пример главного цикла (координаты могут приходить от GPS или датчиков)
local pX, pY, pZ = 0, 64, 0

while true do
    -- Здесь можно обновлять координаты игрока из GPS: pX, pY, pZ = gps.locate(2)
    renderRealMap(pX, pY, pZ, 0)

    local timerId = os.startTimer(0.1)
    os.pullEvent("timer")
end
