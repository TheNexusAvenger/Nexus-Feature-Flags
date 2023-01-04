--[[
TheNexusAvenger

Types used by Nexus Feature Flags.
--]]
--!strict

export type NexusFeatureFlagsSource = {
    FeatureFlagChanged: RBXScriptSignal,
    GetFeatureFlag: (NexusFeatureFlagsSource, Name: string) -> any?,
    GetAllFeatureFlags: (NexusFeatureFlagsSource) -> {string},
    AddFeatureFlag: (NexusFeatureFlagsSource, Name: string, Value: any, Type: string?) -> nil,
    SetFeatureFlag: (NexusFeatureFlagsSource, Name: string, Value: any) -> nil,
    GetFeatureFlagChangedEvent: (NexusFeatureFlagsSource, Name: string) -> RBXScriptSignal,
    Destroy: (NexusFeatureFlagsSource) -> nil,
}

return {}