--Feature flag source that uses NexusDataStore.
--!strict

local HttpService = game:GetService("HttpService")

local NexusDataStore = require(script.Parent.Parent:WaitForChild("Packages"):WaitForChild("NexusDataStore"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))

local LocalSaveData = NexusDataStore.LocalSaveData

local NexusDataStoreSource = {}
NexusDataStoreSource.NexusDataStore = NexusDataStore
NexusDataStoreSource.__index = NexusDataStoreSource

export type NexusDataStoreSource = {
    StoreLastRegisterTime: boolean,
    LastRegisterTimeIgnoreTime: number,
    FeatureFlagDefaults: {[string]: any},
    FeatureFlagTypes: {[string]: string},
    OutputStringValue: StringValue,
    FeatureFlagChangedEvent: BindableEvent,
    FeatureFlagChanged: RBXScriptSignal,
    EventObjects: {BindableEvent},
    FeatureFlagChangedEvents: {[string]: BindableEvent},
    DataStoreUpdateEvents: {[string]: RBXScriptConnection},
    OverridesDataStore: NexusDataStore.SaveData,
    DefaultsDataStore: NexusDataStore.SaveData,
} & typeof(setmetatable({}, NexusDataStoreSource)) & Types.NexusFeatureFlagsSource



--[[
Creates a NexusDataStore source.
--]]
function NexusDataStoreSource.new(OutputStringValue: StringValue): NexusDataStoreSource
    --Create the object.
    local FeatureFlagChangedEvent = Instance.new("BindableEvent")
    local self = setmetatable({
        StoreLastRegisterTime = false,
        LastRegisterTimeIgnoreTime = 5 * 60,
        FeatureFlagDefaults = {},
        FeatureFlagTypes = {},
        OutputStringValue = OutputStringValue,
        FeatureFlagChangedEvent = FeatureFlagChangedEvent,
        FeatureFlagChanged = FeatureFlagChangedEvent.Event :: RBXScriptSignal,
        EventObjects = {FeatureFlagChangedEvent},
        FeatureFlagChangedEvents = {},
        DataStoreUpdateEvents = {},
    }, NexusDataStoreSource) :: NexusDataStoreSource

    --Load the data stores.
    local Worked, Error = pcall(function()
        --Get the DataStores.
        local OverridesDataStore = self.NexusDataStore:GetDataStore("NexusAdminFeatureFlags", "FeatureFlagOverrides")
        local DefaultsDataStore = self.NexusDataStore:GetDataStore("NexusAdminFeatureFlags", "FeatureFlagDefaults")
        self.OverridesDataStore = OverridesDataStore
        self.DefaultsDataStore = DefaultsDataStore

        --Listen for changes to the overrides.
        for _, FeauterFlagName in OverridesDataStore:ListKeys() do
            self:ConnectFeatureFlagDataStoreChanges(FeauterFlagName)
        end
    end)
    if not Worked then
        warn(`Failed to load NexusDataStore for feature flags because: {Error}`)
    end
    if not self.OverridesDataStore then
        self.OverridesDataStore = LocalSaveData.new() :: any
    end

    --Update the StringValue.
    self:UpdateOutputStringValue()

    --Return the object.
    return self
end

--[[
Fires the changed events for a feature flag.
--]]
function NexusDataStoreSource.FireChangedEvents(self: NexusDataStoreSource, Name: string): ()
    self.FeatureFlagChangedEvent:Fire(Name, self:GetFeatureFlag(Name))
    if self.FeatureFlagChangedEvents[Name] then
        self.FeatureFlagChangedEvents[Name]:Fire(self:GetFeatureFlag(Name))
    end
end

--[[
Updates the output StringValue.
--]]
function NexusDataStoreSource.UpdateOutputStringValue(self: NexusDataStoreSource): ()
    local FeatureFlags = {}
    for _, Name in self:GetAllFeatureFlags() do
        FeatureFlags[Name] = self:GetFeatureFlag(Name)
    end
    self.OutputStringValue.Value = HttpService:JSONEncode(FeatureFlags)
end

--[[
Listens for changes to a feature flag in the DataStore.
--]]
function NexusDataStoreSource.ConnectFeatureFlagDataStoreChanges(self: NexusDataStoreSource, Name: string): ()
    if not self.DataStoreUpdateEvents or self.DataStoreUpdateEvents[Name] then return end
    self.DataStoreUpdateEvents[Name] = self.OverridesDataStore:OnUpdate(Name, function()
        self:FireChangedEvents(Name)
        self:UpdateOutputStringValue()
    end)
end

--[[
Returns the value of a feature flag.
--]]
function NexusDataStoreSource.GetFeatureFlag(self: NexusDataStoreSource, Name: string): any?
    if self.OverridesDataStore:Get(Name) ~= nil then
        return self.OverridesDataStore:Get(Name)
    end
    return self.FeatureFlagDefaults[Name]
end

--[[
Returns the names of all the feature flags.
--]]
function NexusDataStoreSource.GetAllFeatureFlags(self: NexusDataStoreSource): {string}
    local FeatureFlags, FeatureFlagsMap = {} :: {string}, {}
    for Name, _ in self.FeatureFlagDefaults do
        table.insert(FeatureFlags, Name :: string)
        FeatureFlagsMap[Name] = true
    end
    for _, Name in self.OverridesDataStore:ListKeys() do
        if FeatureFlagsMap[Name] then continue end
        table.insert(FeatureFlags, Name)
    end
    return FeatureFlags
end

--[[
Adds a feature flag if it wasn't set before.
--]]
function NexusDataStoreSource.AddFeatureFlag(self: NexusDataStoreSource, Name: string, Value: any, Type: string?): ()
    --Return if the feature flag default is already set.
    if self.FeatureFlagDefaults[Name] == Value and Value ~= nil then
        return
    end

    --Determine the type if it isn't set.
    if Type == nil then
        if Value == nil then
            warn(`Unable to determine type for {Name} because the type parameter is not defined and the value is nil.`)
        else
            Type = typeof(Value)
        end
    end

    --Store the default.
    self.FeatureFlagDefaults[Name] = Value
    self.FeatureFlagTypes[Name] = (Type :: string)

    --Store the default in the DataStore.
    --This is intended to be read externally by apps, not internally. It is not designed to be reliable.
    if self.DefaultsDataStore then
        local DefaultChanged = true
        local ExistingValue = self.DefaultsDataStore:Get(Name)
        if ExistingValue and ExistingValue.Type == Type and ExistingValue.DefaultValue == Value then
            if self.StoreLastRegisterTime then
                DefaultChanged = (ExistingValue.LastRegisterTime == nil or math.abs(os.time() - ExistingValue.LastRegisterTime) > self.LastRegisterTimeIgnoreTime)
            else
                DefaultChanged = (ExistingValue.LastRegisterTime ~= nil)
            end
        end
        if DefaultChanged then
            self.DefaultsDataStore:Set(Name, {
                Type = Type,
                DefaultValue = Value,
                LastRegisterTime = self.StoreLastRegisterTime and os.time() or nil,
            })
        end
    end

    --Listten for DataStore changes.
    self:ConnectFeatureFlagDataStoreChanges(Name)

    --Send the events.
    self:UpdateOutputStringValue()
    self:FireChangedEvents(Name)
end

--[[
Sets the value of a feature flag.
--]]
function NexusDataStoreSource.SetFeatureFlag(self: NexusDataStoreSource, Name: string, Value: any): ()
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
function NexusDataStoreSource.GetFeatureFlagChangedEvent(self: NexusDataStoreSource, Name: string): RBXScriptSignal
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
function NexusDataStoreSource.Destroy(self: NexusDataStoreSource): ()
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
            Event:Disconnect()
        end
        self.DataStoreUpdateEvents = {}
    end
end



return NexusDataStoreSource