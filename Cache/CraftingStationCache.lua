CanICraftThis.CraftingStationCache = {
  version = 1,
}

function CanICraftThis.CraftingStationCache:open()
  local data = ZO_SavedVars:NewAccountWide(CanICraftThis.savedVarsName, self.version, "craftingStationCache", {}, GetWorldName())
  CanICraftThis.assert(data ~= nil, "data ~= nil")
  local instance = { data = data }
  setmetatable(instance, { __index = self })
  return instance
end

function CanICraftThis.CraftingStationCache:updateFromCurrentCraftingStation()
  local skillId = GetCraftingInteractionType()
  local skill = CanICraftThis.Skill:fromId(skillId)
  if not skill.equipmentInfo then return end
  local skillData = {
    requiredPassiveAbilityForMainMaterial = {},
  }
  local recipeIndex
  for recipeIndex = 1, GetNumSmithingPatterns() do
    local recipeName, _, _, numMaterials = GetSmithingPatternInfo(recipeIndex)
    local materialIndex
    for materialIndex = 1, numMaterials do
      local material, _, requiredQuantity, _, _, _, _, _, _, requiredPassiveAbility = GetSmithingPatternMaterialItemInfo(recipeIndex, materialIndex)
      local material = CanICraftThis.Material:sanitise(material)
      if CanICraftThis.Material:isEqMain(material) then
        local prevRequiredPassiveAbility = skillData.requiredPassiveAbilityForMainMaterial[material]
        if prevRequiredPassiveAbility ~= nil and prevRequiredPassiveAbility ~= requiredPassiveAbility then
          CanICraftThis.reportUnexpected(
            "multiple values of requiredPassiveAbility for same material " .. material .. ": " ..
            tostring(prevRequiredPassiveAbility) .. ", " .. tostring(requiredPassiveAbility)
          )
        end
        skillData.requiredPassiveAbilityForMainMaterial[material] = requiredPassiveAbility
      end
    end
  end
  self.data[skillId] = skillData
end

function CanICraftThis.CraftingStationCache:installHook()
  EVENT_MANAGER:RegisterForEvent(CanICraftThis.addonName, EVENT_CRAFTING_STATION_INTERACT, function()
    self:updateFromCurrentCraftingStation()
  end)
end

function CanICraftThis.CraftingStationCache:getDataForSkill(skill)
  return self.data[skill.id]
end
