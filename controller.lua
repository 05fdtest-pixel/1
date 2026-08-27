local SERVER_ID = 11 -- Zamenis 1 na ID tvoego servera!

local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        modemSide = side
        break
    end
end

if not modemSide then error("Net modem!") end
rednet.open(modemSide)

term.clear()
term.setCursorPos(1, 1)
print("Pult zapushen. Nazhimi W")

while true do
    local event, p1 = os.pullEvent()
    if event == "key" then
        print("Klavisha: " .. tostring(p1))
        rednet.send(SERVER_ID, {type = "key", key = p1})
    end
end
