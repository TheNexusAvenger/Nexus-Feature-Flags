local HttpService = game:GetService("HttpService")
--[[
TheNexusAvenger

Empty NexusDataStore to use in place of an actual NexusDataStore.
--]]

local EmptyNexusDataStore = {}
EmptyNexusDataStore.__index = EmptyNexusDataStore



--[[
Creates an empty NexusDataStore.
--]]
function EmptyNexusDataStore.new()
    return setmetatable({
        Data = {},
        UpdateCallbacks = {},
        MockEvent = Instance.new("BindableEvent"),
    }, EmptyNexusDataStore)
end

--[[
Returns the stored value for a given key.
--]]
function EmptyNexusDataStore:Get(Key: string): any?
    return self.Data[Key]
end

--[[
Sets the stored value for a given key.
--]]
function EmptyNexusDataStore:Set(Key: string, Value: any): nil
    self.Data[Key] = Value
    for _, Callback in self.UpdateCallbacks[Key] or {} do
        Callback(Value)
    end
end

--[[
Invokes the given callback when the value for a given
key changes. Returns the connection to disconnect the
changes.
--]]
function EmptyNexusDataStore:OnUpdate(Key: string, Callback): CustomEvent
    if not self.UpdateCallbacks[Key] then
        self.UpdateCallbacks[Key] = {}
    end
    table.insert(self.UpdateCallbacks[Key], Callback)
    return self.MockEvent.Event
end

--[[
Disconnects the events.
--]]
function EmptyNexusDataStore:Disconnect(): nil
    self.MockEvent:Destroy()
end



return EmptyNexusDataStore