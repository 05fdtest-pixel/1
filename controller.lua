local SERVER_ID = 11 -- Замени 0 на ID твоего главного компьютера!

-- Автоматический поиск модема на карманном ПК
local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" or peripheral.getType(side) == "wireless_modem" then
        modemSide = side
        break
    end
end

if not modemSide then
    error("Wireless modem not found on pocket computer!")
end

rednet.open(modemSide)

term.clear()
term.setCursorPos(1, 1)
print("=== PULT ZAPUSHEN ===")
print("Nazhimay W, A, S, D")

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        -- Выводим на экран пульта для проверки
        print("Key sent: " .. tostring(p1))
        rednet.send(SERVER_ID, {type = "key", key = p1})
    end
end
