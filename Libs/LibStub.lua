-- Minimal vendored LibStub (guarded)
-- Only create if a global LibStub doesn't already exist
if _G.LibStub then
    return
end

local LibStub = {}
LibStub._registry = {}

setmetatable(LibStub, { __call = function(self, name, silent)
    return self._registry[name]
end })

function LibStub:NewLibrary(name, minor)
    local cur = self._registry[name]
    if not cur or (cur._minor or 0) < (minor or 0) then
        local lib = {}
        lib._minor = minor or 0
        self._registry[name] = lib
        return lib
    end
    return nil
end

_G.LibStub = LibStub
