local function isTraitKnown(trait, recipe)
  local traitIndex
  for traitIndex = 1, recipe.numTraits do
    local traitId, _, isKnown = GetSmithingResearchLineTraitInfo(recipe.skill.id, recipe.researchLineIndex, traitIndex)
    if traitId == trait.id then
      return isKnown
    end
  end
  CanICraftThis.reportUnexpected("GetSmithingResearchLineTraitInfo did not yield information for trait ID " .. tostring(trait.id))
  return nil
end

local function getNumKnownTraits(recipe)
  local n = 0
  local traitIndex
  for traitIndex = 1, recipe.numTraits do
    local _, _, isKnown = GetSmithingResearchLineTraitInfo(recipe.skill.id, recipe.researchLineIndex, traitIndex)
    if isKnown then
      n = n + 1
    end
  end
  return n
end

local function appendCriterion(textIfMet, textIfNotMet, isMet)
  local text, color
  if isMet then
    text = textIfMet
    color = ZO_SUCCEEDED_TEXT
  else
    text = textIfNotMet
    color = ZO_ERROR_COLOR
  end
  ItemTooltip:AddLine(text, nil, color:UnpackRGB())
end

local function appendQuantitativeCriterion(textIfMet, textIfNotMet, have, needed)
  local suffix = " [" .. tostring(have) .. "/" .. tostring(needed) .. "]"
  appendCriterion(textIfMet .. suffix, textIfNotMet .. suffix, have >= needed)
end

local function appendEqPassiveAbilityCriterion(skill, requiredPassiveAbility)
  appendQuantitativeCriterion(
    "Sufficient " .. skill.equipmentInfo.passiveAbilityName .. " skill.",
    "Insufficient " .. skill.equipmentInfo.passiveAbilityName .. " skill.",
    GetNonCombatBonus(skill.equipmentInfo.passiveAbilityId),
    requiredPassiveAbility
  )
end

local function appendEqTraitKnownCriterion(trait, recipe)
  appendCriterion(
    trait.name .. " trait known for " .. recipe.name .. ".",
    trait.name .. " trait not known for " .. recipe.name .. ".",
    isTraitKnown(trait, recipe)
  )
end

local function appendEqStyleKnownCriterion(style, recipe, styleCollectibleCache)
  local collectibleId = styleCollectibleCache:getCollectibleId(style, recipe)
  if collectibleId == nil then return end -- this can happen due to bugs in ESO's database
  appendCriterion(
    style.name .. " style known for " .. recipe.name .. ".",
    style.name .. " style not known for " .. recipe.name .. ".",
    IsCollectibleUnlocked(collectibleId)
  )
end

local function appendEqSetNumTraitsCriterion(set, recipe)
  appendQuantitativeCriterion(
    "Sufficient traits known for " .. recipe.name .. ".",
    "Insufficient traits known for " .. recipe.name .. ".",
    getNumKnownTraits(recipe),
    set.getNumRequiredTraits(recipe)
  )
end

local function appendEqSetDLCCriterion(dlc)
  appendCriterion(
    dlc.name .. " DLC owned, which contains the set crafting station.",
    dlc.name .. " DLC not owned, which contains the set crafting station.",
    IsCollectibleUnlocked(dlc.collectibleId)
  )
end

local function extendTooltip(itemLink, craftingStationCache, styleCollectibleCache)
  local itemType = GetItemLinkItemType(itemLink)
  if itemType ~= ITEMTYPE_MASTER_WRIT then return end
  local skill = CanICraftThis.Skill:tryFromWritName(GetItemLinkName(itemLink))
  if skill == nil then return end
  local writText = GenerateMasterWritBaseText(itemLink)
  if skill.equipmentInfo then
    local craftingStationData = craftingStationCache:getDataForSkill(skill)
    if craftingStationData == nil then
      ItemTooltip:AddLine("You must visit a " .. skill.name .. " Station before detailed information about this writ can be displayed.")
      return
    end
    local mainMaterial = CanICraftThis.Material:eqMainFromWritText(writText)
    local recipe = CanICraftThis.EqRecipe:fromWritText(writText)
    local trait = CanICraftThis.EqTrait:fromWritText(writText, recipe)
    local style = nil
    if skill.equipmentInfo.usesStyle then
      style = CanICraftThis.EqStyle:fromWritText(writText)
    end
    local set = CanICraftThis.EqSet:fromWritText(writText)
    local requiredPassiveAbility = craftingStationData.requiredPassiveAbilityForMainMaterial[mainMaterial]
    ItemTooltip:AddLine("--- Knowledge ---")
    appendEqPassiveAbilityCriterion(skill, requiredPassiveAbility)
    appendEqTraitKnownCriterion(trait, recipe)
    if style ~= nil then
      appendEqStyleKnownCriterion(style, recipe, styleCollectibleCache)
    end
    appendEqSetNumTraitsCriterion(set, recipe)
    if set.dlc ~= nil then
      appendEqSetDLCCriterion(set.dlc)
    end
    -- ItemTooltip:AddLine("--- Materials ---")
  end
end

local function installTooltipExtensionHooks(craftingStationCache, styleCollectibleCache)
  -- TODO: InventoryEnter in inventoryslot.lua has the full list of hooks we should install.
  ZO_PostHook(ItemTooltip, "SetBagItem", function(_, bagId, slotIndex)
    extendTooltip(GetItemLink(bagId, slotIndex), craftingStationCache, styleCollectibleCache)
  end)
  ZO_PostHook(ItemTooltip, "SetTradingHouseItem", function(_, searchResultIndex)
    extendTooltip(GetTradingHouseSearchResultItemLink(searchResultIndex), craftingStationCache, styleCollectibleCache)
  end)
  ZO_PostHook(ItemTooltip, "SetTradingHouseListing", function(_, listingIndex)
    extendTooltip(GetTradingHouseListingItemLink(listingIndex), craftingStationCache, styleCollectibleCache)
  end)
end

local function initialise()
  local craftingStationCache = CanICraftThis.CraftingStationCache:open()
  local styleCollectibleCache = CanICraftThis.StyleCollectibleCache:open()
  craftingStationCache:installHook()
  styleCollectibleCache:populateIfNeeded()
  styleCollectibleCache:verify()
  installTooltipExtensionHooks(craftingStationCache, styleCollectibleCache)
  -- EVENT_MANAGER:RegisterForEvent(CanICraftThis.addonName, EVENT_PLAYER_ACTIVATED, function() end)
end

local function onAddOnLoaded(eventCode, eventAddonName)
  if eventAddonName == CanICraftThis.addonName then
    initialise()
  end
end

EVENT_MANAGER:RegisterForEvent(CanICraftThis.addonName, EVENT_ADD_ON_LOADED, onAddOnLoaded)
