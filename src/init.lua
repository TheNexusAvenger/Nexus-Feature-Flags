--[[
TheNexusAvenger

Main module for Nexus Feature Flags.
--]]
--!strict

local Types = require(script:WaitForChild("Types"))

--Create the singleton instance if it doesn't exist.
--This ensures there aren't multiple NexusFeatureFlag instances if separate projects include them independently.
if not _G.NexusFeatureFlagsSingletonInstance then
    if game:GetService("RunService"):IsClient() then
        _G.NexusFeatureFlagsSingletonInstance = require(script:WaitForChild("Source"):WaitForChild("StringValueSource")).new(script:WaitForChild("FeatureFlags"))
    else
        local FeatureFlagsValue = Instance.new("StringValue")
        FeatureFlagsValue.Name = "FeatureFlags"
        FeatureFlagsValue.Parent = script

        _G.NexusFeatureFlagsSingletonInstance = require(script:WaitForChild("Source"):WaitForChild("NexusDataStoreSource")).new(FeatureFlagsValue)
    end
end

--Return the singleton instance.
return _G.NexusFeatureFlagsSingletonInstance :: Types.NexusFeatureFlagsSource