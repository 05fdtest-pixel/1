local modemSide = "right"
if peripheral.getType(modemSide) ~= "modem" and peripheral.getType(modemSide) ~= "wireless_modem" then
    error("Wireless modem not found on the 'right' side of the server!")
end
rednet.open(modemSide)

print("Server started successfully!")
print("My Server ID: " .. os.getComputerID())

local map = {
    {1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,1},
    {1,0,1,1,0,1,0,1},
    {1,0,1,0,0,1,0,1},
    {1,0,0,0,1,1,0,1},
    {1,1,1,0,0,0,0,1},
    {1,0,0,0,1,1,0,1},
    {1,1,1,1,1,1,1,1},
}

local px, py, pfa = 3.5, 3.5, 0
local MOVE_SPEED = 0.08
local ROT_SPEED = 0.05

local function isWall(x, y)
    local mx = math.floor(x) + 1
    local my = math.floor(y) + 1
    if mx < 1 or mx > 8 or my < 1 or my > 8 then return true end
    return map[my][mx] == 1
end

local function renderFrame()
    term.clear()
    term.setCursorPos(2, 2)
    term.setTextColor(colors.yellow)
    print("X: " .. string.format("%.2f", px) .. " Y: " .. string.format("%.2f", py))
    
    term.setCursorPos(2, 3)
    term.setTextColor(colors.cyan)
    print("Angle: " .. string.format("%.2f", pfa))
end

while true do
    renderFrame()

    local timerId = os.startTimer(0.02)
    local event, p1, p2, p3 = os.pullEvent()

    if event == "rednet_message" then
        local senderId, message = p1, p2
        if type(message) == "table" and message.type == "key" then
            local key = message.key
            
            local newX = px
            local newY = py
            
            if key == keys.w then
                newX = px + math.cos(pfa) * MOVE_SPEED
                newY = py + math.sin(pfa) * MOVE_SPEED
            elseif key == keys.s then
                newX = px - math.cos(pfa) * MOVE_SPEED
                newY = py - math.sin(pfa) * MOVE_SPEED
            elseif key == keys.a then
                pfa = pfa - ROT_SPEED
            elseif key == keys.d then
                pfa = pfa + ROT_SPEED
            end
            
            if not isWall(newX, py) then
                px = newX
            end
            if not isWall(px, newY) then
                py = newY
            end
        end
    end
end
