--Feature flag souurce that uses a StringValue.
--!strict

local HttpService = game:GetService("HttpService")

local Types = require(script.Parent.Parent:WaitForChild("Types"))

local StringValueSource = {}
StringValueSource.__index = StringValueSource

export type StringValueSource = {
    FeatureFlagValues: {[string]: any},
    FeatureFlagChangedEvent: BindableEvent,
    FeatureFlagChanged: RBXScriptSignal,
    EventObjects: {BindableEvent},
    FeatureFlagChangedEvents: {[string]: BindableEvent},
    StringValueChangedEvent: RBXScriptConnection,
} & typeof(setmetatable({}, StringValueSource)) & Types.NexusFeatureFlagsSource



--[[
Creates a StringValue source.
--]]
function StringValueSource.new(StringValue: StringValue): StringValueSource
    --Create the object.
    local FeatureFlagChangedEvent = Instance.new("BindableEvent")
    local self = setmetatable({
        FeatureFlagValues = {},
        FeatureFlagChangedEvent = FeatureFlagChangedEvent,
        FeatureFlagChanged = FeatureFlagChangedEvent.Event :: RBXScriptSignal,
        EventObjects = {FeatureFlagChangedEvent},
        FeatureFlagChangedEvents = {},
    }, StringValueSource) :: StringValueSource

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
function StringValueSource.GetFeatureFlag(self: StringValueSource, Name: string): any?
    return self.FeatureFlagValues[Name]
end

--[[
Returns the names of all the feature flags.
--]]
function StringValueSource.GetAllFeatureFlags(self: StringValueSource): {string}
    local FeatureFlags = {}
    for Name, _ in self.FeatureFlagValues do
        table.insert(FeatureFlags, Name)
    end
    return FeatureFlags
end


--[[
Adds a feature flag if it wasn't set before.
--]]
function StringValueSource.AddFeatureFlag(self: StringValueSource): nil
    error("AddFeatureFlag is not supported on the client.")
end

--[[
Sets the value of a feature flag.
--]]
function StringValueSource.SetFeatureFlag(self: StringValueSource): nil
    error("SetFeatureFlag is not supported on the client.")
end

--[[
Returns an event for a specific feature flag changing.
--]]
function StringValueSource.GetFeatureFlagChangedEvent(self: StringValueSource, Name: string): RBXScriptSignal
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
function StringValueSource.Destroy(self: StringValueSource): ()
    if self.StringValueChangedEvent then
        self.StringValueChangedEvent:Disconnect()
    end
    for _, Event in self.EventObjects do
        Event:Destroy()
    end
    self.EventObjects = {}
end



return StringValueSource