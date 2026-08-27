local SERVER_ID = 11 -- Замени 0 на ID твоего сервера!

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

-- Делаем экран пульта полностью черным и чистым
term.clear()
term.setCursorPos(1, 1)

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        -- Отправляем код нажатой клавиши на сервер без вывода текста на экран пульт
        rednet.send(SERVER_ID, {type = "key", key = p1})
        
        -- Выход по клавише X (если все же захочешь выйти)
        if p1 == keys.x then
            term.clear()
            term.setCursorPos(1, 1)
            break
        end
    end
end
