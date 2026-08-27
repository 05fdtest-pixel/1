-- Карманный ПК (Беспроводной пульт)
local modem = peripheral.find("modem")
if not modem then error("Нужен беспроводной модем!") end
rednet.open(peripheral.getName(modem))

local SERVER_ID = 11 -- Замените 0 на ID главного компьютера!

term.setBackgroundColor(colors.black)
term.clear()

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        rednet.send(SERVER_ID, {type = "key", key = p1})
        
        if p1 == keys.x then
            term.clear()
            term.setCursorPos(1, 1)
            print("Пульт выключен.")
            break
        end
    end
end
