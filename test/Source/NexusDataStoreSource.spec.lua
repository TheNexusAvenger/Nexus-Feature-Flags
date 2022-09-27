--[[
TheNexusAvenger

Tests for the NexusDataStoreSource class.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local NexusDataStoreSource = require(ReplicatedStorage:WaitForChild("NexusFeatureFlags"):WaitForChild("Source"):WaitForChild("NexusDataStoreSource"))
local EmptyNexusDataStore = require(ReplicatedStorage:WaitForChild("NexusFeatureFlags"):WaitForChild("Util"):WaitForChild("EmptyNexusDataStore"))

return function()
    --Create the source.
    local Source = nil
    local StringValue = nil
    beforeEach(function()
        StringValue = Instance.new("StringValue")
        NexusDataStoreSource.NexusDataStore = {
            GetDataStore = function()
                return EmptyNexusDataStore.new()
            end,
        }
        Source = NexusDataStoreSource.new(StringValue)
    end)
    afterEach(function()
        StringValue:Destroy()
        StringValue = nil
        Source:Destroy()
        Source = nil
    end)

    --Run the tests.
    describe("An empty DataStore", function()
        it("should store a default.", function()
            Source:AddFeatureFlag("TestFlag", true)
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(true)
            expect(Source.OverridesDataStore:Get("TestFlag")).to.equal(nil)
            expect(Source.DefaultsDataStore:Get("TestFlag").Type).to.equal("boolean")
            expect(Source.DefaultsDataStore:Get("TestFlag").LastRegisterTime).to.be.near(os.time())
            expect(Source.DefaultsDataStore:Get("TestFlag").DefaultValue).to.equal(true)
            expect(StringValue.Value).to.equal("{\"TestFlag\":true}")
        end)

        it("should store a default with an explicit type.", function()
            Source:AddFeatureFlag("TestFlag", true, "CustomType")
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(true)
            expect(Source.OverridesDataStore:Get("TestFlag")).to.equal(nil)
            expect(Source.DefaultsDataStore:Get("TestFlag").Type).to.equal("CustomType")
            expect(Source.DefaultsDataStore:Get("TestFlag").DefaultValue).to.equal(true)
            expect(StringValue.Value).to.equal("{\"TestFlag\":true}")
        end)

        it("should store a default that is only set.", function()
            Source:SetFeatureFlag("TestFlag", true)
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(true)
            expect(Source.OverridesDataStore:Get("TestFlag")).to.equal(nil)
            expect(Source.DefaultsDataStore:Get("TestFlag").Type).to.equal("boolean")
            expect(Source.DefaultsDataStore:Get("TestFlag").DefaultValue).to.equal(true)
            expect(StringValue.Value).to.equal("{\"TestFlag\":true}")
        end)

        it("should store an override.", function()
            Source:AddFeatureFlag("TestFlag", true)
            Source:SetFeatureFlag("TestFlag", false)
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(false)
            expect(Source.OverridesDataStore:Get("TestFlag")).to.equal(false)
            expect(Source.DefaultsDataStore:Get("TestFlag").DefaultValue).to.equal(true)
            expect(StringValue.Value).to.equal("{\"TestFlag\":false}")
        end)

        it("should not store an override that is default.", function()
            Source:AddFeatureFlag("TestFlag", true)
            Source:SetFeatureFlag("TestFlag", false)
            expect(Source.OverridesDataStore:Get("TestFlag")).to.equal(false)
            expect(StringValue.Value).to.equal("{\"TestFlag\":false}")

            Source:SetFeatureFlag("TestFlag", true)
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(true)
            expect(Source.OverridesDataStore:Get("TestFlag")).to.equal(nil)
            expect(Source.DefaultsDataStore:Get("TestFlag").DefaultValue).to.equal(true)
            expect(StringValue.Value).to.equal("{\"TestFlag\":true}")
        end)

        it("should store a default and allow changes without a defaults DataStore.", function()
            Source.DefaultsDataStore = nil
            Source.DataStoreUpdateEvents = nil
            Source:AddFeatureFlag("TestFlag", true)
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(true)
            expect(Source.OverridesDataStore:Get("TestFlag")).to.equal(nil)
            expect(StringValue.Value).to.equal("{\"TestFlag\":true}")

            Source:SetFeatureFlag("TestFlag", false)
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(false)
            expect(Source.OverridesDataStore:Get("TestFlag")).to.equal(false)
            expect(StringValue.Value).to.equal("{\"TestFlag\":false}")
        end)

        it("should list all feature flags.", function()
            Source:AddFeatureFlag("TestFlag1", "Value1")
            Source:AddFeatureFlag("TestFlag2", "Value1")

            expect(HttpService:JSONEncode(Source:GetAllFeatureFlags())).to.equal(HttpService:JSONEncode({"TestFlag1", "TestFlag2"}))
        end)

        it("should fire FeatureFlagChanged when a flag changes.", function()
            Source:AddFeatureFlag("TestFlag1", "Value1")
            Source:AddFeatureFlag("TestFlag2", "Value1")

            local TotalCalls = 0
            local LastKey, LastValue = nil, nil
            Source.FeatureFlagChanged:Connect(function(Key, Value)
                TotalCalls += 1
                LastKey, LastValue = Key, Value
            end)

            Source:SetFeatureFlag("TestFlag1", "Value2")
            task.wait()
            expect(TotalCalls).to.equal(1)
            expect(LastKey).to.equal("TestFlag1")
            expect(LastValue).to.equal("Value2")
            expect(StringValue.Value).to.equal("{\"TestFlag1\":\"Value2\",\"TestFlag2\":\"Value1\"}")

            Source:SetFeatureFlag("TestFlag1", "Value3")
            task.wait()
            expect(TotalCalls).to.equal(2)
            expect(LastKey).to.equal("TestFlag1")
            expect(LastValue).to.equal("Value3")
            expect(StringValue.Value).to.equal("{\"TestFlag1\":\"Value3\",\"TestFlag2\":\"Value1\"}")

            Source:SetFeatureFlag("TestFlag2", "Value3")
            task.wait()
            expect(TotalCalls).to.equal(3)
            expect(LastKey).to.equal("TestFlag2")
            expect(LastValue).to.equal("Value3")
            expect(StringValue.Value).to.equal("{\"TestFlag1\":\"Value3\",\"TestFlag2\":\"Value3\"}")
        end)

        it("should not fire FeatureFlagChanged when set to the same value several times.", function()
            Source:AddFeatureFlag("TestFlag", "Value1")

            local TotalCalls = 0
            Source.FeatureFlagChanged:Connect(function()
                TotalCalls += 1
            end)

            Source:SetFeatureFlag("TestFlag", "Value2")
            task.wait()
            expect(TotalCalls).to.equal(1)
            expect(StringValue.Value).to.equal("{\"TestFlag\":\"Value2\"}")

            Source:SetFeatureFlag("TestFlag", "Value2")
            task.wait()
            expect(TotalCalls).to.equal(1)
            expect(StringValue.Value).to.equal("{\"TestFlag\":\"Value2\"}")
        end)

        it("should fire for GetFeatureFlagChangedEvent when a flag changes.", function()
            Source:AddFeatureFlag("TestFlag1", "Value1")
            Source:AddFeatureFlag("TestFlag2", "Value1")

            local TotalCalls = 0
            local LastValue = nil
            Source:GetFeatureFlagChangedEvent("TestFlag2"):Connect(function(Value)
                TotalCalls += 1
                LastValue =  Value
            end)

            Source:SetFeatureFlag("TestFlag1", "Value2")
            task.wait()
            expect(TotalCalls).to.equal(0)
            expect(LastValue).to.equal(nil)

            Source:SetFeatureFlag("TestFlag2", "Value3")
            task.wait()
            expect(TotalCalls).to.equal(1)
            expect(LastValue).to.equal("Value3")

            Source:SetFeatureFlag("TestFlag2", "Value4")
            task.wait()
            expect(TotalCalls).to.equal(2)
            expect(LastValue).to.equal("Value4")

            Source:SetFeatureFlag("TestFlag2", "Value4")
            task.wait()
            expect(TotalCalls).to.equal(2)
            expect(LastValue).to.equal("Value4")
        end)

        it("should not fire FeatureFlagChanged when an external change is made.", function()
            Source:AddFeatureFlag("TestFlag", "Value1")

            local TotalCalls = 0
            local LastKey, LastValue = nil, nil
            Source.FeatureFlagChanged:Connect(function(Key, Value)
                TotalCalls += 1
                LastKey, LastValue = Key, Value
            end)

            Source.OverridesDataStore:Set("TestFlag", "Value2")
            task.wait()
            expect(TotalCalls).to.equal(1)
            expect(LastKey).to.equal("TestFlag")
            expect(LastValue).to.equal("Value2")

            Source.OverridesDataStore:Set("TestFlag", "Value3")
            task.wait()
            expect(TotalCalls).to.equal(2)
            expect(LastKey).to.equal("TestFlag")
            expect(LastValue).to.equal("Value3")
        end)
    end)

    describe("An initialied DataStore", function()
        it("should update the defaults.", function()
            Source.OverridesDataStore:Set("TestFlag", false)
            Source.DefaultsDataStore:Set("TestFlag", {
                Type = "boolean",
                DefaultValue = true,
                LastRegisterTime = 0,
            })

            Source:AddFeatureFlag("TestFlag", "Value")
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(false)
            expect(Source.DefaultsDataStore:Get("TestFlag").Type).to.equal("string")
            expect(Source.DefaultsDataStore:Get("TestFlag").LastRegisterTime).to.be.near(os.time())
            expect(Source.DefaultsDataStore:Get("TestFlag").DefaultValue).to.equal("Value")
            expect(StringValue.Value).to.equal("{\"TestFlag\":false}")
        end)

        it("should list all feature flags.", function()
            Source.OverridesDataStore:Set("TestFlag1", false)
            Source.DefaultsDataStore:Set("TestFlag1", {
                Type = "boolean",
                DefaultValue = true,
                LastRegisterTime = 0,
            })
            Source:AddFeatureFlag("TestFlag2", "Value1")

            expect(HttpService:JSONEncode(Source:GetAllFeatureFlags())).to.equal(HttpService:JSONEncode({"TestFlag2", "TestFlag1"}))
        end)
    end)
end