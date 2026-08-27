local monitor = peripheral.wrap("left") -- укажи сторону, где подключен монитор (или оставьнижеавтопоиск)
local cam = peripheral.wrap("right")      -- сторона, где стоит приемник или камера

-- Если стороны неизвестны, ищем автоматически:
if not cam then
    for _, name in ipairs(peripheral.getNames()) do
        local type = peripheral.getType(name)
        if type == "cmos_camera" or type == "exposure_receiver" or type == "wireless_receiver" or type == "digitizer" then
            cam = peripheral.wrap(name)
        end
    end
end

if not monitor then
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then
            monitor = peripheral.wrap(name)
        end
    end
end

if not monitor then error("Монитор не найден!") end
if not cam then error("Камера или приемник Exposure не обнаружены!") end

monitor.setTextScale(0.5)
term.redirect(monitor)

while true do
    local success, data = pcall(function()
        -- Пробуем получить кадр в зависимости от версии аддона
        if cam.getImage then return cam.getImage() end
        if cam.capture then return cam.capture() end
        if cam.readImage then return cam.readImage() end
    end)

    if success and data then
        term.clear()
        term.setCursorPos(1, 1)
        -- Если функции вывода поддерживают отрисовку таблиц/буфера
        if type(data) == "function" then
            data()
        end
    else
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("Нет сигнала с камеры...")
    end

    sleep(0.1)
    collectgarbage("collect")
end
