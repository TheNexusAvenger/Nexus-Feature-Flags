--[[
TheNexusAvenger

Main module for Nexus Feature Flags.
--]]

if game:GetService("RunService"):IsClient() then
    return require(script:WaitForChild("Source"):WaitForChild("StringValueSource")).new(script:WaitForChild("FeatureFlags"))
else
    local FeatureFlagsValue = Instance.new("StringValue")
    FeatureFlagsValue.Name = "FeatureFlags"
    FeatureFlagsValue.Parent = script

    return require(script:WaitForChild("Source"):WaitForChild("NexusDataStoreSource")).new(FeatureFlagsValue)
end