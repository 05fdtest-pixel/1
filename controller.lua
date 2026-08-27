local SERVER_ID = 11 -- Замени 0 на ID твоего главного компьютера-сервера!

local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" or peripheral.getType(side) == "wireless_modem" then
        modemSide = side
        break
    end
end

if not modemSide then
    error("Wireless modem not found!")
end

rednet.open(modemSide)

-- Очищаем экран в черный цвет, оставляя его пустым
term.clear()
term.setCursorPos(1, 1)

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        -- Отправляем код нажатой клавиши на сервер без вывода текста
        rednet.send(SERVER_ID, {type = "key", key = p1})
        
        -- Экстренный выход по клавише X
        if p1 == keys.x then
            term.clear()
            term.setCursorPos(1, 1)
            break
        end
    end
end
