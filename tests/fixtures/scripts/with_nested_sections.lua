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

---@section UnusedNesterHelperRoot
local function UnusedNestedHelperRoot()
  local stringToReturn = ""
  ---@section UsedNestedHelperInUnusedRoot
  function UsedNestedHelperInUnusedRoot()
    return "UsedNestedHelperInUnusedRoot"
  end
  ---@endsection
  
  stringToReturn = stringToReturn .. UsedNestedHelperInUnusedRoot()
  
  ---@section UnusedNestedHelperInUnusedRoot
  function UnusedNestedHelperInUnusedRoot()
    return "UnusedNestedHelperInUnusedRoot"
  end
  ---@endsection

  return stringToReturn
end
---@endsection

function onTick()
  local result = UsedNestedHelperRoot()
  output.setNumber(1, #result)
end
