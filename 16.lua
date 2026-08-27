local modem = peripheral.find("modem")
if not modem then
    error()
end

modem.open(1234)

while true do
    local event, key = os.pullEvent("key")
    local cmd = nil
    
    if key == keys.w then cmd = "FORWARD"
    elseif key == keys.s then cmd = "BACKWARD"
    elseif key == keys.a then cmd = "LEFT"
    elseif key == keys.d then cmd = "RIGHT"
    elseif key == keys.q then cmd = "TURN_LEFT"
    elseif key == keys.e then cmd = "TURN_RIGHT"
    elseif key == keys.t then 
        break
    end
    
    if cmd then
        modem.transmit(1235, 1234, cmd)
    end
end
