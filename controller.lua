local SERVER_ID = 11 -- Вставь сюда ID сервера!

local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" or peripheral.getType(side) == "wireless_modem" then
        modemSide = side
        break
    end
end

if not modemSide then error("No modem!") end
rednet.open(modemSide)

term.clear()
term.setCursorPos(1, 1)
print("Testing keys...")

while true do
    local event, p1 = os.pullEvent()
    if event == "key" then
        print("Sent key: " .. tostring(p1))
        rednet.send(SERVER_ID, {type = "key", key = p1})
    end
end
