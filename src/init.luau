--Main module for Nexus Feature Flags.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script:WaitForChild("Types"))

export type NexusFeatureFlagsSource = Types.NexusFeatureFlagsSource

--Create the singleton instance if it doesn't exist.
--This ensures there aren't multiple NexusFeatureFlag instances if separate projects include them independently.
if not _G.NexusFeatureFlagsSingletonInstance then
    if game:GetService("RunService"):IsClient() then
        _G.NexusFeatureFlagsSingletonInstance = require(script:WaitForChild("Source"):WaitForChild("StringValueSource")).new(ReplicatedStorage:WaitForChild("NexusFeatureFlagValues"))
    else
        local FeatureFlagsValue = Instance.new("StringValue")
        FeatureFlagsValue.Name = "NexusFeatureFlagValues"
        FeatureFlagsValue.Parent = ReplicatedStorage

        _G.NexusFeatureFlagsSingletonInstance = require(script:WaitForChild("Source"):WaitForChild("NexusDataStoreSource")).new(FeatureFlagsValue)
    end
end

--Return the singleton instance.
return _G.NexusFeatureFlagsSingletonInstance :: Types.NexusFeatureFlagsSource