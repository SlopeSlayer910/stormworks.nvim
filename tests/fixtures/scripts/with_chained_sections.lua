---@section UsedHelperA
--Only used in the unused caller and should be removed with it
local function UsedHelperA()
  return "UsedHelperA"
end
---@endsection

---@section UnusedCaller
local function UnusedCaller()
  return "UnusedCaller " .. UsedHelperB()
end
---@endsection

---@section UsedHelperB
local function UsedHelperB()
  return "UsedHelperB"
end
---@endsection

---@section UsedCaller
local function UsedCaller()
  return "UsedCaller " .. UsedHelperB()
end
---@endsection

function onTick()
  local result = UsedCaller()
  output.setNumber(1, #result)
end