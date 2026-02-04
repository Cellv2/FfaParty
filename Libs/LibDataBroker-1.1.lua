-- Minimal vendored LibDataBroker-1.1 (guarded)
if LibStub and LibStub("LibDataBroker-1.1", true) then
    return
end

local LDB = LibStub:NewLibrary("LibDataBroker-1.1", 1)
if not LDB then return end

LDB.objects = LDB.objects or {}

function LDB:NewDataObject(name, obj)
    obj = obj or {}
    obj.name = name
    self.objects[name] = obj
    return obj
end

function LDB:GetDataObjectByName(name)
    return self.objects[name]
end
