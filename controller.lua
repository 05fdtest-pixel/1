local SERVER_ID = 0 -- Замени 0 на ID твоего сервера!

local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        modemSide = side
        break
    end
end

if not modemSide then error("No modem found!") end
rednet.open(modemSide)

term.clear()
term.setCursorPos(1, 1)
print("=== CONTROLLER ===")
print("Use W, A, S, D to move")
print("Press X to exit")

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        rednet.send(SERVER_ID, {type = "key", key = p1})
        
        if p1 == keys.x then
            term.clear()
            term.setCursorPos(1, 1)
            print("Controller stopped.")
            break
        end
    end
end
