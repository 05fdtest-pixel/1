local monitor = nil
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
        monitor = peripheral.wrap(name)
        break
    end
end

if not monitor then
    error("Monitor not found")
end

monitor.setTextScale(0.5)
monitor.clear()

local cam = nil
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "cmos_camera" or pType == "exposure_receiver" or pType == "wireless_receiver" or pType == "digitizer" or pType == "camera" then
        cam = peripheral.wrap(name)
        break
    end
end

if not cam then
    for _, name in ipairs(peripheral.getNames()) do
        if name ~= "computer" and peripheral.getType(name) ~= "monitor" and peripheral.getType(name) ~= "modem" then
            cam = peripheral.wrap(name)
            break
        end
    end
end

if not cam then
    error("Camera not found")
end

while true do
    local success, imgData = pcall(function()
        if cam.getImage then return cam.getImage() end
        if cam.capture then return cam.capture() end
        if cam.readImage then return cam.readImage() end
    end)

    if success and imgData then
        if type(imgData) == "function" then
            monitor.clear()
            imgData()
        else
            monitor.setCursorPos(1, 1)
            monitor.clear()
            monitor.write("Streaming...")
        end
    else
        monitor.setCursorPos(1, 1)
        monitor.clear()
        monitor.write("No signal...")
    end

    sleep(0.1)
    collectgarbage("collect")
end
