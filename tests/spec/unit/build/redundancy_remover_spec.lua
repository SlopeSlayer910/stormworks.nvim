describe("RedundancyRemover", function()
  local TestUtils = require("test_utils")
  local remover_class

  setup(function()
    TestUtils.setup_lifeboat()
    require("stormworks.common.nameouschangey.Common.LifeBoatAPI.Tools.Build.RedundancyRemover")
    remover_class = LifeBoatAPI.Tools.RedundancyRemover
  end)

  describe("removeRedundantCode", function()
    it("should remove unused section", function()
      local remover = remover_class:new()
      local input = [[
---@section UnusedFunc
function UnusedFunc()
  return "test"
end
---@endsection

function onTick()
  output.setNumber(1, 42)
end
]]

      local output = remover:removeRedundantCode(input)

      -- The UnusedFunc section should be removed since the function isn't called
      TestUtils.assert_not_contains(output, "UnusedFunc")
      TestUtils.assert_contains(output, "onTick")
    end)

    it("should keep used section", function()
      local remover = remover_class:new()
      local input = [[
---@section UsedFunc
function UsedFunc()
  return "test"
end
---@endsection

function onTick()
  local result = UsedFunc()
  output.setNumber(1, #result)
end
]]

      local output = remover:removeRedundantCode(input)

      TestUtils.assert_contains(output, "UsedFunc")
      TestUtils.assert_contains(output, "onTick")
    end)

    it("should handle multiple sections", function()
      local remover = remover_class:new()
      local input = [[
---@section NotUsed
function NotUsed() end
---@endsection

---@section IsUsed
function IsUsed() end
---@endsection

function onTick()
  IsUsed()
end
]]

      local output = remover:removeRedundantCode(input)

      TestUtils.assert_not_contains(output, "NotUsed")
      TestUtils.assert_contains(output, "IsUsed")
    end)

    it("should handle section with count parameter", function()
      local remover = remover_class:new()
      local input = [[
---@section Func 2
function Func() return 1 end
---@endsection

function onTick()
  Func()
end
]]

      local output = remover:removeRedundantCode(input)

      -- Should remove because Func is used only 1 time, but needs 2
      TestUtils.assert_not_contains(output, "---@section")
    end)
  end)

  it("should keep used nested sections in used root sections and the used root sections", function()
    local remover = remover_class:new()
    local input = [[
---@section UsedNestedHelperRoot
local function UsedNestedHelperRoot()
  local stringToReturn = ""
  ---@section UsedNestedHelperInUsedRoot
  function UsedNestedHelperInUsedRoot()
    return "UsedNestedHelperInUsedRoot"
  end
  ---@endsection
  
  stringToReturn = stringToReturn .. UsedNestedHelperInUsedRoot()
  
  ---@section UnusedNestedHelperInUsedRoot
  function UnusedNestedHelperInUsedRoot()
    return "UnusedNestedHelperInUsedRoot"
  end
  ---@endsection

  return stringToReturn
end
---@endsection

function onTick()
  UsedNestedHelperRoot()
end
]]

    local output = remover:removeRedundantCode(input)

    TestUtils.assert_contains(output, "UsedNestedHelperRoot")
    TestUtils.assert_contains(output, "UsedNestedHelperInUsedRoot")
  end)

  it("should remove unused nested sections in used root sections", function()
    local remover = remover_class:new()
    local input = [[
---@section UsedNesterHelperRoot
local function UsedNesterHelperRoot()
  local stringToReturn = ""
  
  ---@section UsedNestedHelperInUsedRoot
  function UsedNestedHelperInUsedRoot()
    return "UsedNestedHelperInUsedRoot"
  end
  ---@endsection
  
  stringToReturn = stringToReturn .. UsedNestedHelperInUsedRoot()
  
  ---@section UnusedNestedHelperInUsedRoot
  function UnusedNestedHelperInUsedRoot()
    return "UnusedNestedHelperInUsedRoot"
  end
  ---@endsection

  return stringToReturn
end
---@endsection

function onTick()
  UsedNestedHelperRoot()
end
]]

    local output = remover:removeRedundantCode(input)

    TestUtils.assert_not_contains(output, "UnusedNestedHelperInUsedRoot")
  end)

  it("should remove used nested sections in unused root sections and the unused root sections", function()
    local remover = remover_class:new()
    local input = [[
---@section UnusedNesterHelperRoot
local function UnusedNestedHelperRoot()
  local stringToReturn = ""
  ---@section UsedNesterHelperInUnusedRoot
  function UsedNesterHelperInUnusedRoot()
    return "UsedNesterHelperInUnusedRoot"
  end
  ---@endsection
  
  stringToReturn = stringToReturn .. UsedNesterHelperInUnusedRoot()
  
  ---@section UnusedNestedHelperInUnusedRoot
  function UnusedNestedHelperInUnusedRoot()
    return "UnusedNestedHelperInUnusedRoot"
  end
  ---@endsection

  return stringToReturn
end
---@endsection
]]

    local output = remover:removeRedundantCode(input)

    TestUtils.assert_not_contains(output, "UnusedNesterHelperRoot")
    TestUtils.assert_not_contains(output, "UsedNesterHelperInUsedRoot")
  end)
end)
