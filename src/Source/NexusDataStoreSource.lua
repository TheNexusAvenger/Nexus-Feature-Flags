--[[
TheNexusAvenger

Feature flag source that uses NexusDataStore.
--]]

local HttpService = game:GetService("HttpService")

local NexusDataStore = require(script.Parent.Parent:WaitForChild("NexusDataStore"))
local EmptyNexusDataStore = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("EmptyNexusDataStore"))

local NexusDataStoreSource = {}
NexusDataStoreSource.NexusDataStore = NexusDataStore
NexusDataStoreSource.__index = NexusDataStoreSource


--[[
Creates a NexusDataStore source.
--]]
function NexusDataStoreSource.new(OutputStringValue: StringValue)
    --Create the object.
    local self = {
        FeatureFlagDefaults = {},
        FeatureFlagTypes = {},
        OutputStringValue = OutputStringValue,
    }
    self.FeatureFlagChangedEvent = Instance.new("BindableEvent")
    self.FeatureFlagChanged = self.FeatureFlagChangedEvent.Event
    self.EventObjects = {self.FeatureFlagChangedEvent}
    self.FeatureFlagChangedEvents = {}
    setmetatable(self, NexusDataStoreSource)

    --Load the data stores.
    local Worked, Error = pcall(function()
        --Get the DataStores.
        self.OverridesDataStore = self.NexusDataStore:GetDataStore("NexusAdminFeatureFlags", "FeatureFlagOverrides")
        self.DefaultsDataStore = self.NexusDataStore:GetDataStore("NexusAdminFeatureFlags", "FeatureFlagDefaults")

        --Listen for changes to the overrides.
        self.DataStoreUpdateEvents = {}
        if self.OverridesDataStore.Data and typeof(self.OverridesDataStore.Data) == "table" then
            for FeauterFlagName, _ in self.OverridesDataStore.Data do
                self:ConnectFeatureFlagDataStoreChanges(FeauterFlagName)
            end
        end
    end)
    if not Worked then
        warn("Failed to load NexusDataStore for feature flags because: "..tostring(Error))
    end
    if not self.OverridesDataStore then
        self.OverridesDataStore = EmptyNexusDataStore.new()
    end

    --Update the StringValue.
    self:UpdateOutputStringValue()

    --Return the object.
    return self
end

--[[
Fires the changed events for a feature flag.
--]]
function NexusDataStoreSource:FireChangedEvents(Name: string): nil
    self.FeatureFlagChangedEvent:Fire(Name, self:GetFeatureFlag(Name))
    if self.FeatureFlagChangedEvents[Name] then
        self.FeatureFlagChangedEvents[Name]:Fire(self:GetFeatureFlag(Name))
    end
end

--[[
Updates the output StringValue.
--]]
function NexusDataStoreSource:UpdateOutputStringValue(): nil
    local FeatureFlags = {}
    for Key, Value in self.FeatureFlagDefaults do
        FeatureFlags[Key] = Value
    end
    for Key, Value in self.OverridesDataStore.Data do
        FeatureFlags[Key] = Value
    end
    self.OutputStringValue.Value = HttpService:JSONEncode(FeatureFlags)
end

--[[
Listens for changes to a feature flag in the DataStore.
--]]
function NexusDataStoreSource:ConnectFeatureFlagDataStoreChanges(Name: string): nil
    if not self.DataStoreUpdateEvents or self.DataStoreUpdateEvents[Name] then return end
    self.DataStoreUpdateEvents[Name] = self.OverridesDataStore:OnUpdate(Name, function()
        self:FireChangedEvents(Name)
    end)
    self:UpdateOutputStringValue()
end

--[[
Returns the value of a feature flag.
--]]
function NexusDataStoreSource:GetFeatureFlag(Name: string): any?
    if self.OverridesDataStore:Get(Name) ~= nil then
        return self.OverridesDataStore:Get(Name)
    end
    return self.FeatureFlagDefaults[Name]
end

--[[
Adds a feature flag if it wasn't set before.
--]]
function NexusDataStoreSource:AddFeatureFlag(Name: string, Value: any?, Type: string?): nil
    --Return if the feature flag default is already set.
    if self.FeatureFlagDefaults[Name] == Value and Value ~= nil then
        return
    end

    --Determine the type if it isn't set.
    if Type == nil then
        if Value == nil then
            warn("Unable to determine type for "..tostring(Name).." because the type parameter is not defined and the value is nil.")
        else
            Type = typeof(Value)
        end
    end

    --Store the default.
    self.FeatureFlagDefaults[Name] = Value
    self.FeatureFlagTypes[Name] = Type

    --Store the default in the DataStore.
    --This is intended to be read externally by apps, not internally. It is not designed to be reliable.
    if self.DefaultsDataStore then
        self.DefaultsDataStore:Set(Name, {
            Type = Type,
            DefaultValue = Value,
            LastRegisterTime = os.time(),
        })
    end

    --Listten for DataStore changes.
    self:ConnectFeatureFlagDataStoreChanges(Name)

    --Send the events.
    if self:GetFeatureFlag(Name) == Value then
        self:UpdateOutputStringValue()
        return
    end
    self:FireChangedEvents(Name)
end

--[[
Sets the value of a feature flag.
--]]
function NexusDataStoreSource:SetFeatureFlag(Name: string, Value: any?): nil
    --If there is no default set, add the feature flag first.
    if self.FeatureFlagDefaults[Name] == nil and Value ~= nil then
        self:AddFeatureFlag(Name, Value)
        return
    end

    --Return if the value hasn't changed.
    if self:GetFeatureFlag(Name) == Value then
        return
    end

    --Store the updated value.
    --This will invoke the events.
    if self.FeatureFlagDefaults[Name] == Value then
        self.OverridesDataStore:Set(Name, nil)
    else
        self.OverridesDataStore:Set(Name, Value)
    end
    self:UpdateOutputStringValue()
end

--[[
Returns an event for a specific feature flag changing.
--]]
function NexusDataStoreSource:GetFeatureFlagChangedEvent(Name: string): CustomEvent
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
function NexusDataStoreSource:Destroy()
    self.OverridesDataStore:Disconnect()
    if self.DefaultsDataStore then
        self.DefaultsDataStore:Disconnect()
    end

    for _, Event in self.EventObjects do
        Event:Destroy()
    end
    self.EventObjects = {}
    if self.DataStoreUpdateEvents then
        for _, Event in self.DataStoreUpdateEvents do
            Event:Destroy()
        end
        self.DataStoreUpdateEvents = nil
    end
end



return NexusDataStoreSource