if CanICraftThis == nil then CanICraftThis = {} end

CanICraftThis.addonName = "CanICraftThis"
CanICraftThis.savedVarsName = CanICraftThis.addonName .. "Vars"

function CanICraftThis.reportInfo(message)
  d("[" .. CanICraftThis.addonName .. "] " .. message)
end

function CanICraftThis.reportUnexpected(message)
  error("Unexpected situation!\n" .. message .. "\nThis typically indicates a bug in the " .. CanICraftThis.addonName .. " add-on.")
end

function CanICraftThis.assert(condition, conditionString)
  if not condition then
    CanICraftThis.reportUnexpected("Assertion failed: " .. conditionString)
  end
end

function CanICraftThis.literalPattern(text)
  return string.gsub(string.lower(text), "([^a-zA-Z0-9 ])", "%%%1")
end
