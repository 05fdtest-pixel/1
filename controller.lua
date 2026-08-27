-- Карманный ПК (Беспроводной пульт)
local SERVER_ID = 11 -- ЗАМЕНИТЕ 0 НА ID СЕРВЕРА!

local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        modemSide = side
        break
    end
end

if not modemSide then
    error("На карманном ПК нет беспроводного модема!")
end

rednet.open(modemSide)

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1, 1)
print("=== ПУЛЬТ УПРАВЛЕНИЯ ===")
print("Сервер ID: " .. SERVER_ID)
print("Нажмите W, A, S, D для движения")
print("Нажмите X для выхода")

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        -- Отправляем сигнал на сервер
        rednet.send(SERVER_ID, {type = "key", key = p1})
        
        if p1 == keys.x then
            term.clear()
            term.setCursorPos(1, 1)
            print("Пульт выключен.")
            break
        end
    end
end
