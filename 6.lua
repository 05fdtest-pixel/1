local c3d = require("c3d")

local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)

-- Инициализация дисплея под актуальный синтаксис C3D
local display = c3d.display.new(monitor)
local scene = c3d.scene.new()

-- Камера
local camera = c3d.camera.new()
camera.fov = 70
camera.pos = {0, 1, 0}
camera.rot = {0, 0, 0}
scene:set_camera(camera)

-- Цвета
local floorColor = colors.green
local pillarColor = colors.lightGray

-- Размеры комнаты
local roomSize = 10

-- Пол
local floor = c3d.object.plane(roomSize, roomSize)
floor.pos = {0, 0, 0}
floor.color = floorColor
scene:add(floor)

-- 4 Столба на равном расстоянии
local pillarOffset = 2.5
local pillarSize = 1

local positions = {
    {-pillarOffset, 0.5, -pillarOffset},
    { pillarOffset, 0.5, -pillarOffset},
    {-pillarOffset, 0.5,  pillarOffset},
    { pillarOffset, 0.5,  pillarOffset}
}

for _, pos in ipairs(positions) do
    local pillar = c3d.object.cube(pillarSize, 2, pillarSize)
    pillar.pos = pos
    pillar.color = pillarColor
    scene:add(pillar)
end

-- Управление
local keysHeld = { forward = false, back = false, left = false, right = false }
local moveSpeed = 4.0
local rotSpeed = 2.0

local function update(dt)
    if keysHeld.right then
        camera.rot[2] = camera.rot[2] + rotSpeed * dt
    end
    if keysHeld.left then
        camera.rot[2] = camera.rot[2] - rotSpeed * dt
    end

    local rad = math.rad(camera.rot[2])
    local dx = math.sin(rad) * moveSpeed * dt
    local dz = math.cos(rad) * moveSpeed * dt

    if keysHeld.forward then
        camera.pos[1] = camera.pos[1] + dx
        camera.pos[3] = camera.pos[3] + dz
    end
    if keysHeld.back then
        camera.pos[1] = camera.pos[1] - dx
        camera.pos[3] = camera.pos[3] - dz
    end
end

-- Рендер-цикл
local lastTime = os.clock()
while true do
    local now = os.clock()
    local dt = math.min(now - lastTime, 0.05)
    lastTime = now

    update(dt)

    display:clear(colors.cyan)
    display:render(scene)
    display:draw()

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
