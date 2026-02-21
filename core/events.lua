-- core/events.lua
Event = {}

function Event.New()
    local self = {
        _handlers = {},  -- table associative: [id] = callback
        _nextId = 0
    }

    ---@param callback function
    ---@return number id  identifiant stable pour Off()
    function self.On(callback)
        self._nextId = self._nextId + 1
        self._handlers[self._nextId] = callback
        return self._nextId
    end

    ---@param id number  identifiant retourné par On()
    function self.Off(id)
        self._handlers[id] = nil
    end

    ---@param ... any
    function self.Emit(...)
        for _, cb in pairs(self._handlers) do
            cb(...)
        end
    end

    function self.Clear()
        self._handlers = {}
        self._nextId = 0
    end

    return self
end