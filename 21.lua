local pixelbox = require("pixelbox_lite")

local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11") or term.current()
local modem = peripheral.wrap("right") or peripheral.find("modem")

if not monitor then error("Монитор не найден!") end

monitor.setTextScale(0.5)

local box = pixelbox.new(monitor)
local W, H = box.width, box.height

local RADIUS = 8
local MAP_SIZE = (RADIUS * 2) + 1

print("Инициализация GPS...")
local startX, startY, startZ = gps.locate(2)
if not startX then
    error("GPS-сигнал не найден! Убедитесь, что в мире установлены GPS-вышки.")
end
print(string.NIL and "" or "GPS найден: " .. math.floor(startX) .. ", " .. math.floor(startZ))

local function renderRealMap(playerX, playerZ)
    -- Очищаем экран
    for y = 1, H do
        for x = 1, W do
            box.canvas[y][x] = colors.black
        end
    end

    local scaleX = math.floor(W / MAP_SIZE)
    local scaleY = math.floor(H / MAP_SIZE)
    local scale = math.min(scaleX, scaleY)
    scale = math.max(scale, 2)

    -- Рисуем тактическую сетку координат вокруг игрока
    for dz = -RADIUS, RADIUS do
        for dx = -RADIUS, RADIUS do
            local worldX = math.floor(playerX + dx)
            local worldZ = math.floor(playerZ + dz)

            -- Чередуем цвета для сетки местности
            local color = ((worldX + worldZ) % 2 == 0) and colors.gray or colors.lightGray

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

    -- Рисуем маркер игрока строго по центру
    local centerX = RADIUS * scale + math.floor(scale / 2)
    local centerY = RADIUS * scale + math.floor(scale / 2)

    if centerX >= 1 and centerX <= W and centerY >= 1 and centerY <= H then
        box.canvas[centerY][centerX] = colors.red
    end

    box:render()
end

while true do
    -- Получаем реальные координаты игрока через GPS
    local x, _, z = gps.locate(1)
    if x then
        renderRealMap(x, z)
    end
    
    -- Обновляем каждые 0.5 секунд
    sleep(0.5)
end
