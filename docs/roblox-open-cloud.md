# Roblox-Open-Cloud
## Creating API Key
In order to interact with Nexus Feature Flags using Roblox Open Cloud,
an API key needs to be created. This can be done in the [credentials view](https://create.roblox.com/credentials)
of the Roblox Creator Dashboard. For each experience for the API key that
is set up, DataStore access must be set for at least "NexusAdminFeatureFlags"
with "Read Entry" and "Update Entry". For MessagingService, "Publish"
permissions are required.

## Listing All Feature Flags
The default values for all of the feature flags is stored in the
`FeatureFlagDefaults` key in the `NexusAdminFeatureFlags` DataStore.
All of the feature flags registered are stored in the table where the
key is the name of the feature flag and the value is a table containing
`DefaultValue` for the default value, `Type` for the type of the value,
and `LastRegisterTime` for the last time it was registered. Depending
on the total servers being started, this is not guarenteed to be the
absolute latest time, but it will give an indicator that a feature flag
is actively being registered instead of stale.

```python
import requests

gameId = ...
apiKey = ...
url = "https://apis.roblox.com/datastores/v1/universes/" + str(gameId) + "/standard-datastores/datastore/entries/entry?datastoreName=NexusAdminFeatureFlags&entryKey=FeatureFlagDefaults"
response = requests.get(url, headers={
    "x-api-key": apiKey
}).json()

for featureFlag in response.keys():
    print(featureFlag)
    print("\tDefaultValue: " + str(response[featureFlag]["DefaultValue"]))
    print("\tType: " + response[featureFlag]["Type"])
    print("\tLastRegisterTime: " + str(response[featureFlag]["LastRegisterTime"]))
```

## Getting Feature Flag Value
Getting the value of a feature flag is a bit more difficult because
there are 2 keys to check in the `NexusAdminFeatureFlags` DataStore:
`FeatureFlagOverrides` and then `FeatureFlagDefaults`. `FeatureFlagOverrides`
should be checked first, which will be a table with the key being
name of the feature flag and the value being the overriden value.
If the key doesn't exist, `DefaultValue` in the table for the
feature flag in `FeatureFlagOverrides` should be used. This design
is intended to allow explicit overriding of feature flags and allow
unchanged feature flags to be re-registered with a different value.

```python
import requests

gameId = ...
apiKey = ...
featureFlagName = "MyFeatureFlag"

featureFlagValue = None
overridesUrl = "https://apis.roblox.com/datastores/v1/universes/" + str(gameId) + "/standard-datastores/datastore/entries/entry?datastoreName=NexusAdminFeatureFlags&entryKey=FeatureFlagOverrides"
overridesResponse = requests.get(overridesUrl, headers={
    "x-api-key": apiKey
}).json()
if featureFlagName in overridesResponse.keys():
    featureFlagValue = overridesResponse[featureFlagName]
else:
    defaultsUrl = "https://apis.roblox.com/datastores/v1/universes/" + str(gameId) + "/standard-datastores/datastore/entries/entry?datastoreName=NexusAdminFeatureFlags&entryKey=FeatureFlagDefaults"
    defaultsResponse = requests.get(defaultsUrl, headers={
        "x-api-key": apiKey
    }).json()
    featureFlagValue = defaultsResponse[featureFlagName]["DefaultValue"]

print(featureFlagName + " = " + str(featureFlagValue))
```

## Setting Feature Flag Value
Setting feature flags requires both a DataStore and MessagingService
call to function. For persisting the feature flag, the table in the
`FeatureFlagOverrides` key in the `NexusAdminFeatureFlags` DataStore
needs to be set with the key of the feature flag set to the new value.
The value can be set to `nil` to remove the override entirely.

After the DataStore call, a MessagingService call is required to update
the current servers. Due to MessagingService limitations, NexusDataStore
bulks together messages for DataStore changes into a single message.
The topic to send is `NexusBulkMessagingService`, which must be a table
with the key being `NSD_FeatureFlagOverrides` and the value being a list
of tables containing 1 or many feature flags to change. Each entry must
have the `Action` as `Set`, `Key` as the name of the feature flag, and
`Value` as the value of the feature flag (or `nil` to remove the override).

```python
import json
import requests

gameId = ...
apiKey = ...
featureFlagName = "MyFeatureFlag"
featureFlagValue = True

# Update the override.
overridesUrl = "https://apis.roblox.com/datastores/v1/universes/" + str(gameId) + "/standard-datastores/datastore/entries/entry?datastoreName=NexusAdminFeatureFlags&entryKey=FeatureFlagOverrides"
overridesResponse = requests.get(overridesUrl, headers={
    "x-api-key": apiKey
}).json()
overridesResponse[featureFlagName] = featureFlagValue
# Use overridesResponse[featureFlagName] = None to remove the override.
requests.post(overridesUrl, json=overridesResponse, headers={
    "x-api-key": apiKey
})

# Messaging service call.
messageUrl = "https://apis.roblox.com/messaging-service/v1/universes/" + str(gameId) + "/topics/NexusBulkMessagingService"
requests.post(messageUrl, json={
    "message": json.dumps({
        "NSD_FeatureFlagOverrides": [
            json.dumps({
                "Action": "Set",
                "Key": featureFlagName,
                "Value": featureFlagValue
            }),
        ],
    })
}, headers={
    "x-api-key": apiKey
})
```