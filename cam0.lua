-- Ищем большой монитор среди всех подключенных устройств
local monitor = nil
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
        monitor = peripheral.wrap(name)
        break
    end
end

if not monitor then
    error("Большой монитор 4x4 не найден! Проверьте подключение к компьютеру.")
end

-- Настраиваем монитор для максимальной рабочей зоны
monitor.setTextScale(0.5)
monitor.clear()

-- Ищем устройство от Exposure: CMOS (камеру, приемник или дигитайзер)
local cam = nil
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    -- Проверяем распространенные типы периферии от аддона CMOS
    if pType == "cmos_camera" or pType == "exposure_receiver" or pType == "wireless_receiver" or pType == "digitizer" or pType == "camera" then
        cam = peripheral.wrap(name)
        break
    end
end

-- Если по типу не нашлось, пробуем взять первое попавшееся устройство, отличное от монитора и модема
if not cam then
    for _, name in ipairs(peripheral.getNames()) do
        if name ~= "computer" and peripheral.getType(name) ~= "monitor" and peripheral.getType(name) ~= "modem" then
            cam = peripheral.wrap(name)
            break
        end
    end
end

if not cam then
    error("Приемник Exposure CMOS не обнаружен! Проверьте сборку.")
end

-- Главный цикл трансляции
while true do
    -- Запрос кадра через pcall защищает игру от краша при обрыве связи с камерой
    local success, imgData = pcall(function()
        if cam.getImage then return cam.getImage() end
        if cam.capture then return cam.capture() end
        if cam.readImage then return cam.readImage() end
    end)

    if success and imgData then
        -- Если камера передала функцию отрисовки или данные буфера напрямую
        if type(imgData) == "function" then
            monitor.clear()
            imgData()
        else
            -- Если данные пришли в виде таблиц пикселей, выводим статус работы
            monitor.setCursorPos(1, 1)
            monitor.clear()
            monitor.write("Трансляция активна...")
        end
    else
        -- Экран ожидания при отсутствии кадра
        monitor.setCursorPos(1, 1)
        monitor.clear()
        monitor.write("Ожидание сигнала камеры...")
    end

    -- Защита от перегрузки памяти и падения FPS
    sleep(0.1)
    collectgarbage("collect")
end
