local SERVER_ID = 11 -- ЗАМЕНИ 0 НА ID СВОЕГО СЕРВЕРА!

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

while true do
    local event, p1 = os.pullEvent()
    
    if event == "key" then
        rednet.send(SERVER_ID, {type = "key", key = p1})
        
        -- Выход по клавише X
        if p1 == keys.x then
            term.clear()
            term.setCursorPos(1, 1)
            break
        end
    end
end
