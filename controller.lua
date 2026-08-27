local SERVER_ID = 11 -- Замени 0 на ID твоего главного компьютера-сервера!

-- Автоматический поиск беспроводного модема на карманном ПК
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
print("=== REMOTE CONTROLLER ===")
print("Use W, A, S, D to move")
print("Press X to exit")

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        -- Отправляем код нажатой клавиши на сервер
        rednet.send(SERVER_ID, {type = "key", key = p1})
        print("Key sent: " .. tostring(p1))
        
        -- Выход по клавише X
        if p1 == keys.x then
            term.clear()
            term.setCursorPos(1, 1)
            print("Controller stopped.")
            break
        end
    end
end
