--[[
TheNexusAvenger

Feature flag souurce that uses a StringValue.
--]]

local HttpService = game:GetService("HttpService")

local Types = require(script.Parent.Parent:WaitForChild("Types"))

local StringValueSource = {}
StringValueSource.__index = StringValueSource



--[[
Creates a StringValue source.
--]]
function StringValueSource.new(StringValue: StringValue): Types.NexusFeatureFlagsSource
    --Create the object.
    local self = {
        FeatureFlagValues = {},
    }
    self.FeatureFlagChangedEvent = Instance.new("BindableEvent")
    self.FeatureFlagChanged = self.FeatureFlagChangedEvent.Event
    self.EventObjects = {self.FeatureFlagChangedEvent}
    self.FeatureFlagChangedEvents = {}
    setmetatable(self, StringValueSource)

    --Load the values.
    if StringValue.Value ~= "" then
        self.FeatureFlagValues = HttpService:JSONDecode(StringValue.Value)
    end

    --Connect the values changing.
    self.StringValueChangedEvent = StringValue.Changed:Connect(function()
        local NewValues = HttpService:JSONDecode(StringValue.Value)
        local OldValues = self.FeatureFlagValues
        self.FeatureFlagValues = NewValues
        for Key, Value in NewValues do
            if OldValues[Key] ~= Value then
                self.FeatureFlagChangedEvent:Fire(Key, Value)
                if self.FeatureFlagChangedEvents[Key] then
                    self.FeatureFlagChangedEvents[Key]:Fire(Value)
                end
            end
        end
    end)

    --Return the object.
    return self
end

--[[
Returns the value of a feature flag.
--]]
function StringValueSource:GetFeatureFlag(Name: string): any?
    return self.FeatureFlagValues[Name]
end

--[[
Returns the names of all the feature flags.
--]]
function StringValueSource:GetAllFeatureFlags(): {string}
    local FeatureFlags = {}
    for Name, _ in self.FeatureFlagValues do
        table.insert(FeatureFlags, Name)
    end
    return FeatureFlags
end


--[[
Adds a feature flag if it wasn't set before.
--]]
function StringValueSource:AddFeatureFlag(): nil
    error("AddFeatureFlag is not supported on the client.")
end

--[[
Sets the value of a feature flag.
--]]
function StringValueSource:SetFeatureFlag(): nil
    error("SetFeatureFlag is not supported on the client.")
end

--[[
Returns an event for a specific feature flag changing.
--]]
function StringValueSource:GetFeatureFlagChangedEvent(Name: string): RBXScriptSignal
    --Create the event if it doesn't exist.
    if not self.FeatureFlagChangedEvents[Name] then
        self.FeatureFlagChangedEvents[Name] = Instance.new("BindableEvent")
        table.insert(self.EventObjects, self.FeatureFlagChangedEvents[Name])
    end

    --Return the event.
    return self.FeatureFlagChangedEvents[Name].Event
end

--[[
Destroys the source.
--]]
function StringValueSource:Destroy()
    if self.StringValueChangedEvent then
        self.StringValueChangedEvent:Disconnect()
        self.StringValueChangedEvent = nil
    end
    for _, Event in self.EventObjects do
        Event:Destroy()
    end
    self.EventObjects = {}
end



return StringValueSource