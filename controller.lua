local modem = peripheral.find("modem")
local CHANNEL = 15

term.clear()

local keyMap = {
    [keys.w] = "forward",
    [keys.s] = "back",
    [keys.a] = "left",
    [keys.d] = "right"
}

local activeTouch = nil

while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "key" and keyMap[p1] then
        modem.transmit(CHANNEL, CHANNEL, { action = keyMap[p1], state = true })
    elseif event == "key_up" and keyMap[p1] then
        modem.transmit(CHANNEL, CHANNEL, { action = keyMap[p1], state = false })
    elseif event == "mouse_click" then
        local x, y = p2, p3
        local action = nil
        if y >= 1 and y <= 5 then
            if x >= 1 and x <= 5 then action = "forward"
            elseif x >= 6 and x <= 10 then action = "left"
            elseif x >= 11 and x <= 15 then action = "back"
            elseif x >= 16 and x <= 20 then action = "right"
            end
        end
        if action then
            activeTouch = action
            modem.transmit(CHANNEL, CHANNEL, { action = action, state = true })
        end
    elseif event == "mouse_up" and activeTouch then
        modem.transmit(CHANNEL, CHANNEL, { action = activeTouch, state = false })
        activeTouch = nil
    end
end
