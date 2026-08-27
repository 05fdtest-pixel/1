-- Карманный пульт управления
local SERVER_ID = 11 -- Вставь сюда ID главного компьютера (сервера)

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
print("Controller active.")
print("Use W, A, S, D to move.")
print("Press X to exit.")

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        -- Отправляем нажатую клавишу на сервер через Rednet
        rednet.send(SERVER_ID, {type = "key", key = p1})
        
        -- Выход по клавише X
        if p1 == keys.x then
            term.clear()
            term.setCursorPos(1, 1)
            print("Exited.")
            break
        end
    end
end
