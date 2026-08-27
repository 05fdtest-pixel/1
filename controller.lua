local SERVER_ID = 0 -- Замените 0 на ID вашего сервера!

local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        modemSide = side
        break
    end
end

if not modemSide then error("Нет модема!") end
rednet.open(modemSide)

term.clear()
term.setCursorPos(1, 1)
print("Пульт запущен. Нажимайте W, A, S, D")

while true do
    local event, p1 = os.pullEvent()
    if event == "key" then
        print("Нажата клавиша код: " .. tostring(p1)) -- Пишет на экране пульта
        rednet.send(SERVER_ID, {type = "key", key = p1})
    end
end
