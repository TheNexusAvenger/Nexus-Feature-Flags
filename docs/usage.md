# Usage
## Adding Feature Flags
In order for feature flags to be read or set, they need to be
added using `AddFeatureFlag` **on the server**. `AddFeatureFlag`
accepts a required `Name` and `Value`. Optionally, a `Type` can
be specified. Currently, `Type` is only stored for external
applications to use and is not used internally. They can be
read with `GetFeatureFlag`.

```lua
local NexusFeatureFlags = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusFeatureFlags"))

NexusFeatureFlags:AddFeatureFlag("MyFeatureFlag1", true) --Adds a feature flag named MyFeature1 with a default value of true.
NexusFeatureFlags:AddFeatureFlag("MyFeatureFlag2", "MyValue2") --Adds a feature flag named MyFeature2 with a default value of "MyValue2".
NexusFeatureFlags:AddFeatureFlag("MyFeatureFlag3", 123, "int") --Adds a feature flag named MyFeature3 with a default value of 123 and a custom type of "int" for external tools to reference.

print(NexusFeatureFlags:GetFeatureFlag("MyFeatureFlag1")) --true
print(NexusFeatureFlags:GetFeatureFlag("MyFeatureFlag2")) --"MyValue2"
print(NexusFeatureFlags:GetFeatureFlag("MyFeatureFlag3")) --123
```

## Changing Feature Flags
Feature flags can be changed after being added using `SetFeatureFlag`.
`SetFeatureFlag` currently can be called without `AddFeatureFlag`, but
this is unsupported. Like `AddFeatureFlag`, **this only works on the server.**

```lua
local NexusFeatureFlags = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusFeatureFlags"))
NexusFeatureFlags:AddFeatureFlag("MyFeatureFlag1", true) --Adds a feature flag named MyFeature1 with a default value of true
NexusFeatureFlags:AddFeatureFlag("MyFeatureFlag2", "MyValue2") --Adds a feature flag named MyFeature2 with a default value of "MyValue2"

print(NexusFeatureFlags:GetFeatureFlag("MyFeatureFlag1")) --true
print(NexusFeatureFlags:GetFeatureFlag("MyFeatureFlag2")) --"MyValue2"

NexusFeatureFlags:SetFeatureFlag("MyFeatureFlag1", false) --Sets MyFeatureFlag1 to false.
NexusFeatureFlags:SetFeatureFlag("MyFeatureFlag2", 456) --Sets MyFeatureFlag2 to 456. The type is not enforced and can be changed at any time.

print(NexusFeatureFlags:GetFeatureFlag("MyFeatureFlag1")) --false
print(NexusFeatureFlags:GetFeatureFlag("MyFeatureFlag2")) --456
```

## Listing Feature Flags
All the feature flags that are registered can be listed
using `GetAllFeatureFlags`.

```lua
local NexusFeatureFlags = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusFeatureFlags"))
NexusFeatureFlags:AddFeatureFlag("MyFeatureFlag1", true) --Adds a feature flag named MyFeature1 with a default value of true
NexusFeatureFlags:AddFeatureFlag("MyFeatureFlag2", "MyValue2") --Adds a feature flag named MyFeature2 with a default value of "MyValue2"

print(NexusFeatureFlags:GetAllFeatureFlags()) --{"MyFeatureFlag1", "MyFeatureFlag2"}
```

## Events
When possible, it is recommended to monitor for changes to feature
flags instead of only reading feature flags on start. This can be
done by listening to `FeatureFlagChanged` for when a feature flag
changees or calling `GetFeatureFlagChangedEvent` to get the an event
for a specific feature flag changing.

```lua
local NexusFeatureFlags = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusFeatureFlags"))
NexusFeatureFlags:AddFeatureFlag("MyFeatureFlag", true)

NexusFeatureFlags.FeatureFlagChanged:Connect(function(Name, Value)
    print(tostring(Name)..","..tostring(Value))
end)
NexusFeatureFlags:GetFeatureFlagChangedEvent("MyFeatureFlag"):Connect(function(Value)
    print("GetFeatureFlagChangedEvent(MyFeatureFlag),"..tostring(Value))
end)

NexusFeatureFlags:SetFeatureFlag("MyFeatureFlag", false)
--MyFeatureFlag,false
--GetFeatureFlagChangedEvent(MyFeatureFlag),false
```