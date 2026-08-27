local monitor = nil
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" or string.find(name, "monitor") then
        monitor = peripheral.wrap(name)
        break
    end
end

if not monitor then
    error("Monitor not found")
end

monitor.setTextScale(0.5)
monitor.clear()

local cam = peripheral.wrap("left")

if not cam then
    error("Wireless receiver not found on left side")
end

while true do
    local success, imgData = pcall(function()
        if cam.getImage then return cam.getImage() end
        if cam.capture then return cam.capture() end
        if cam.readImage then return cam.readImage() end
        if cam.getFrame then return cam.getFrame() end
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
end
