local c3d = require("c3d")

local monitor = peripheral.wrap("left") or peripheral.wrap("monitor_11")
local modem = peripheral.wrap("right")

local CHANNEL = 15
modem.open(CHANNEL)

monitor.setTextScale(0.5)

-- Инициализация холста и сцены
local display = c3d.new(monitor)
local scene = c3d.scene()

-- Камера
local camera = c3d.camera({
    fov = 70,
    pos = {0, 1.5, 0},
    rot = {0, 0, 0}
})
scene:set_camera(camera)

-- Пол
local floor = c3d.object.plane(12, 12)
floor.pos = {0, 0, 0}
floor.color = colors.green
scene:add(floor)

-- 4 Столба (Кубы на равном расстоянии)
local pillarOffset = 3.0
local pillarPositions = {
    {-pillarOffset, 1, -pillarOffset},
    { pillarOffset, 1, -pillarOffset},
    {-pillarOffset, 1,  pillarOffset},
    { pillarOffset, 1,  pillarOffset}
}

for _, pos in ipairs(pillarPositions) do
    local pillar = c3d.object.cube(1, 2, 1)
    pillar.pos = pos
    pillar.color = colors.lightGray
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
