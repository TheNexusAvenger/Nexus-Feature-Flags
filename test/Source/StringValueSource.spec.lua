--[[
TheNexusAvenger

Tests for the StringValueSource class.
--]]
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local StringValueSource = require(ReplicatedStorage:WaitForChild("NexusFeatureFlags"):WaitForChild("Source"):WaitForChild("StringValueSource"))

return function()
    --Create the source.
    local StringValue = nil
    local Source = nil
    local function CreateSource(InitialValue: string): ()
        StringValue = Instance.new("StringValue")
        StringValue.Value = InitialValue
        Source = StringValueSource.new(StringValue)
    end
    afterEach(function()
        Source:Destroy()
        StringValue:Destroy()
    end)

    --Run the tests.
    describe("An empty StringValue", function()
        it("should initialize with no feature flags.", function()
            CreateSource("")
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(nil)
        end)

        it("should invoke FeatureFlagChanged.", function()
            CreateSource("")

            local PreviousCalls = {}
            Source.FeatureFlagChanged:Connect(function(Key, Value)
                table.insert(PreviousCalls, {
                    Key = Key,
                    Value = Value,
                })
            end)

            StringValue.Value = "{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value2\"}"
            task.wait()
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value1")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value2")
            expect(#PreviousCalls).to.equal(2)
            expect(PreviousCalls[1].Key).to.equal("TestFlag1")
            expect(PreviousCalls[1].Value).to.equal("Value1")
            expect(PreviousCalls[2].Key).to.equal("TestFlag2")
            expect(PreviousCalls[2].Value).to.equal("Value2")

            StringValue.Value = "{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value3\"}"
            task.wait()
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value1")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value3")
            expect(#PreviousCalls).to.equal(3)
            expect(PreviousCalls[1].Key).to.equal("TestFlag1")
            expect(PreviousCalls[1].Value).to.equal("Value1")
            expect(PreviousCalls[2].Key).to.equal("TestFlag2")
            expect(PreviousCalls[2].Value).to.equal("Value2")
            expect(PreviousCalls[3].Key).to.equal("TestFlag2")
            expect(PreviousCalls[3].Value).to.equal("Value3")
        end)

        it("should invoke GetFeatureFlagChangedEvent.", function()
            CreateSource("")

            local PreviousCalls = {}
            Source:GetFeatureFlagChangedEvent("TestFlag2"):Connect(function(Value)
                table.insert(PreviousCalls, Value)
            end)

            StringValue.Value = "{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value2\"}"
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value1")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value2")
            task.wait()
            expect(#PreviousCalls).to.equal(1)
            expect(PreviousCalls[1]).to.equal("Value2")

            StringValue.Value = "{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value3\"}"
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value1")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value3")
            task.wait()
            expect(#PreviousCalls).to.equal(2)
            expect(PreviousCalls[1]).to.equal("Value2")
            expect(PreviousCalls[2]).to.equal("Value3")
        end)

        it("should list no feature flags.", function()
            CreateSource("")

            expect(#Source:GetAllFeatureFlags()).to.equal(0)
        end)
    end)

    describe("An empty table StringValue", function()
        it("should initialize with no feature flags.", function()
            CreateSource("[]")
            expect(Source:GetFeatureFlag("TestFlag")).to.equal(nil)
        end)

        it("should invoke FeatureFlagChanged.", function()
            CreateSource("[]")

            local PreviousCalls = {}
            Source.FeatureFlagChanged:Connect(function(Key, Value)
                table.insert(PreviousCalls, {
                    Key = Key,
                    Value = Value,
                })
            end)

            StringValue.Value = "{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value2\"}"
            task.wait()
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value1")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value2")
            expect(#PreviousCalls).to.equal(2)
            expect(PreviousCalls[1].Key).to.equal("TestFlag1")
            expect(PreviousCalls[1].Value).to.equal("Value1")
            expect(PreviousCalls[2].Key).to.equal("TestFlag2")
            expect(PreviousCalls[2].Value).to.equal("Value2")
        end)

        it("should invoke GetFeatureFlagChangedEvent.", function()
            CreateSource("[]")

            local PreviousCalls = {}
            Source:GetFeatureFlagChangedEvent("TestFlag2"):Connect(function(Value)
                table.insert(PreviousCalls, Value)
            end)

            StringValue.Value = "{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value2\"}"
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value1")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value2")
            task.wait()
            expect(#PreviousCalls).to.equal(1)
            expect(PreviousCalls[1]).to.equal("Value2")
        end)

        it("should list no feature flags.", function()
            CreateSource("")

            expect(#Source:GetAllFeatureFlags()).to.equal(0)
        end)
    end)

    describe("A populated StringValue", function()
        it("should initialize with feature flags.", function()
            CreateSource("{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value2\"}")
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value1")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value2")
        end)

        it("should invoke FeatureFlagChanged.", function()
            CreateSource("{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value2\"}")

            local PreviousCalls = {}
            Source.FeatureFlagChanged:Connect(function(Key, Value)
                table.insert(PreviousCalls, {
                    Key = Key,
                    Value = Value,
                })
            end)

            StringValue.Value = "{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value3\"}"
            task.wait()
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value1")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value3")
            expect(#PreviousCalls).to.equal(1)
            expect(PreviousCalls[1].Key).to.equal("TestFlag2")
            expect(PreviousCalls[1].Value).to.equal("Value3")
        end)

        it("should invoke GetFeatureFlagChangedEvent.", function()
            CreateSource("{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value2\"}")

            local PreviousCalls = {}
            Source:GetFeatureFlagChangedEvent("TestFlag2"):Connect(function(Value)
                table.insert(PreviousCalls, Value)
            end)

            StringValue.Value = "{\"TestFlag1\":\"Value3\",\"TestFlag2\":\"Value3\"}"
            expect(Source:GetFeatureFlag("TestFlag1")).to.equal("Value3")
            expect(Source:GetFeatureFlag("TestFlag2")).to.equal("Value3")
            task.wait()
            expect(#PreviousCalls).to.equal(1)
            expect(PreviousCalls[1]).to.equal("Value3")
        end)

        it("should list all feature flags.", function()
            CreateSource("{\"TestFlag1\":\"Value1\",\"TestFlag2\":\"Value2\"}")

            expect(HttpService:JSONEncode(Source:GetAllFeatureFlags())).to.equal(HttpService:JSONEncode({"TestFlag1", "TestFlag2"}))
        end)
    end)
end
