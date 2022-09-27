--[[
TheNexusAvenger

Main module for Nexus Feature Flags.
--]]

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

return _G.NexusFeatureFlagsSingletonInstance