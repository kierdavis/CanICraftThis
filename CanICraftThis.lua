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

local function iterImprovementMaterials(skill, desiredQualityId)
  local i = 0
  return function()
    while i < 100 do
      i = i + 1
      local material, _, _, _, _, _, _, materialQualityId = GetSmithingImprovementItemInfo(skill.id, i)
      if material == nil or material == "" then break end
      if materialQualityId <= desiredQualityId then
        return {
          name = CanICraftThis.Material:sanitise(material),
          requiredQuantity = GetSmithingGuaranteedImprovementItemAmount(skill.id, i),
        }
      end
    end
    return nil
  end
end

local function getMaterialQuantities()
  local quantities = {}
  local bagId
  for _, bagId in ipairs({BAG_BACKPACK, BAG_VIRTUAL, BAG_BANK, BAG_SUBSCRIBER_BANK}) do
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
    local slotIndex
    for slotIndex in ZO_IterateBagSlots(bagId) do
      local slot = bagCache[slotIndex]
      if slot then
        local name = CanICraftThis.Material:sanitise(slot.name)
        quantities[name] = (quantities[name] or 0) + slot.stackCount
      end
    end
  end
  return quantities
end

local function appendCriterion(options)
  if options.have ~= nil then
    CanICraftThis.assert(options.needed ~= nil, "options.needed ~= nil")
    CanICraftThis.assert(options.textIfMet ~= nil, "options.textIfMet ~= nil")
    CanICraftThis.assert(options.textIfNotMet ~= nil, "options.textIfNotMet ~= nil")
    local suffix = " [" .. tostring(options.have) .. "/" .. tostring(options.needed) .. "]"
    options.textIfMet = options.textIfMet .. suffix
    options.textIfNotMet = options.textIfNotMet .. suffix
    options.isMet = options.have >= options.needed
  end
  if options.isMet ~= nil then
    CanICraftThis.assert(options.textIfMet ~= nil, "options.textIfMet ~= nil")
    CanICraftThis.assert(options.textIfNotMet ~= nil, "options.textIfNotMet ~= nil")
    if options.colorIfMet == nil then options.colorIfMet = ZO_SUCCEEDED_TEXT end
    if options.colorIfNotMet == nil then options.colorIfNotMet = ZO_ERROR_COLOR end
    if options.isMet then
      options.text = options.textIfMet
      options.color = options.colorIfMet
    else
      options.text = options.textIfNotMet
      options.color = options.colorIfNotMet
    end
  end
  CanICraftThis.assert(options.text ~= nil, "options.text ~= nil")
  CanICraftThis.assert(options.color ~= nil, "options.color ~= nil")
  ItemTooltip:AddLine(options.text, nil, options.color:UnpackRGB())
end

local function appendEqPassiveAbilityCriterion(skill, requiredPassiveAbility)
  appendCriterion({
    textIfMet = "Sufficient " .. skill.equipmentInfo.passiveAbilityName .. " skill.",
    textIfNotMet = "Insufficient " .. skill.equipmentInfo.passiveAbilityName .. " skill.",
    have = GetNonCombatBonus(skill.equipmentInfo.passiveAbilityId),
    needed = requiredPassiveAbility,
  })
end

local function appendEqTraitKnownCriterion(trait, recipe)
  appendCriterion({
    textIfMet = trait.name .. " trait known for " .. recipe.name .. ".",
    textIfNotMet = trait.name .. " trait not known for " .. recipe.name .. ".",
    isMet = isTraitKnown(trait, recipe),
  })
end

local function appendEqStyleKnownCriterion(style, recipe, styleCollectibleCache)
  local collectibleId = styleCollectibleCache:getCollectibleId(style, recipe)
  if collectibleId == nil then return end -- this can happen due to bugs in ESO's database
  appendCriterion({
    textIfMet = style.name .. " style known for " .. recipe.name .. ".",
    textIfNotMet = style.name .. " style not known for " .. recipe.name .. ".",
    isMet = IsCollectibleUnlocked(collectibleId),
  })
end

local function appendEqSetNumTraitsCriterion(set, recipe)
  appendCriterion({
    textIfMet = "Sufficient traits known for " .. recipe.name .. ".",
    textIfNotMet = "Insufficient traits known for " .. recipe.name .. ".",
    have = getNumKnownTraits(recipe),
    needed = set.getNumRequiredTraits(recipe),
  })
end

local function appendEqSetDLCCriterion(name)
  local instance = CanICraftThis.DLC:tryFromName(name)
  local isUnlocked
  if instance ~= nil then
    isUnlocked = IsCollectibleUnlocked(instance.collectibleId)
  else
    isUnlocked = false
  end
  appendCriterion({
    textIfMet = name .. " DLC owned, which contains the set crafting station.",
    textIfNotMet = name .. " DLC not owned, which contains the set crafting station.",
    isMet = isUnlocked,
  })
end

local function appendMaterialQuantityCriterion(options)
  CanICraftThis.assert(options.material ~= nil, "options.material ~= nil")
  CanICraftThis.assert(options.needed ~= nil, "options.needed ~= nil")
  CanICraftThis.assert(options.materialQuantities ~= nil, "options.materialQuantities ~= nil")
  options.suffix = options.suffix or ""
  options.textIfMet = "Sufficient " .. options.material .. options.suffix .. "."
  options.textIfNotMet = "Insufficient " .. options.material .. options.suffix .. "."
  options.have = options.materialQuantities[options.material] or 0
  appendCriterion(options)
end

local function appendStyleMaterialQuantityCriterion(options)
  CanICraftThis.assert(options.material ~= nil, "options.material ~= nil")
  CanICraftThis.assert(options.needed ~= nil, "options.needed ~= nil")
  CanICraftThis.assert(options.materialQuantities ~= nil, "options.materialQuantities ~= nil")
  options.suffix = " (style)"
  local wildcardMaterial = CanICraftThis.Material.wildcardStyle
  local have = options.materialQuantities[options.material] or 0
  local wildcardHave = options.materialQuantities[wildcardMaterial] or 0
  if have < options.needed and wildcardHave >= options.needed then
    options.colorIfNotMet = ZO_SECOND_CONTRAST_TEXT
    appendMaterialQuantityCriterion(options)
    options.colorIfNotMet = nil
    options.material = wildcardMaterial
    appendMaterialQuantityCriterion(options)
  else
    appendMaterialQuantityCriterion(options)
  end
end

local function extendTooltip(itemLink, craftingStationCache, styleCollectibleCache)
  local itemType = GetItemLinkItemType(itemLink)
  if itemType ~= ITEMTYPE_MASTER_WRIT then return end
  local skill = CanICraftThis.Skill:tryFromWritName(GetItemLinkName(itemLink))
  if skill == nil then return end
  local writText = GenerateMasterWritBaseText(itemLink)
  local qualityId = GetItemLinkDisplayQuality(itemLink)
  if skill.equipmentInfo then
    local mainMaterial = CanICraftThis.Material:eqMainFromWritText(writText)
    local recipe = CanICraftThis.EqRecipe:fromWritText(writText)
    local trait = CanICraftThis.EqTrait:fromWritText(writText, recipe)
    local style = nil
    if skill.equipmentInfo.usesStyle then
      style = CanICraftThis.EqStyle:fromWritText(writText)
    end
    local set = CanICraftThis.EqSet:fromWritText(writText)
    local requiredPassiveAbility = craftingStationCache:getRequiredPassiveAbility(mainMaterial)
    local requiredMainMaterialQuantity = craftingStationCache:getRequiredMainMaterialQuantity(mainMaterial, recipe)
    if requiredPassiveAbility == nil or requiredMainMaterialQuantity == nil then
      ItemTooltip:AddLine("You must visit a " .. skill.name .. " Station before detailed information about this writ can be displayed.")
      return
    end
    local materialQuantities = getMaterialQuantities()
    ItemTooltip:AddLine("--- Knowledge ---")
    appendEqPassiveAbilityCriterion(skill, requiredPassiveAbility)
    appendEqTraitKnownCriterion(trait, recipe)
    if style ~= nil then
      appendEqStyleKnownCriterion(style, recipe, styleCollectibleCache)
    end
    appendEqSetNumTraitsCriterion(set, recipe)
    if set.dlcName ~= nil then
      appendEqSetDLCCriterion(set.dlcName)
    end
    ItemTooltip:AddLine("--- Materials ---")
    appendMaterialQuantityCriterion({
      material = mainMaterial,
      needed = requiredMainMaterialQuantity,
      materialQuantities = materialQuantities,
    })
    appendMaterialQuantityCriterion({
      material = trait.material,
      suffix = " (trait)",
      needed = 1,
      materialQuantities = materialQuantities,
    })
    if style ~= nil then
      appendStyleMaterialQuantityCriterion({
        material = style.material,
        needed = 1,
        materialQuantities = materialQuantities,
      })
    end
    for improvementMaterial in iterImprovementMaterials(skill, qualityId) do
      appendMaterialQuantityCriterion({
        material = improvementMaterial.name,
        suffix = " (improve)",
        needed = improvementMaterial.requiredQuantity,
        materialQuantities = materialQuantities,
      })
    end
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
  ZO_PostHook(ItemTooltip, "SetAttachedMailItem", function(_, mailId, attachmentIndex)
    extendTooltip(GetAttachedItemLink(mailId, attachmentIndex), craftingStationCache, styleCollectibleCache)
  end)
end

local function installDeveloperHooks()
  local onlyOnce = true
  EVENT_MANAGER:RegisterForEvent(CanICraftThis.addonName, EVENT_PLAYER_ACTIVATED, function()
    if onlyOnce then
      onlyOnce = false
      if CanICraftThis.isHonorGuardCollectibleBugPresent then
        CanICraftThis.reportInfo("Honor Guard collectible bug is still present.")
      else
        CanICraftThis.reportInfo("Honor Guard collectible bug is fixed!")
      end
    end
  end)
end

local function initialise()
  local craftingStationCache = CanICraftThis.CraftingStationCache:open()
  local styleCollectibleCache = CanICraftThis.StyleCollectibleCache:open()
  craftingStationCache:installHook()
  styleCollectibleCache:populateIfNeeded()
  styleCollectibleCache:verify()
  installTooltipExtensionHooks(craftingStationCache, styleCollectibleCache)
  if GetDisplayName() == CanICraftThis.authorName then
    installDeveloperHooks()
  end
end

local function onAddOnLoaded(eventCode, eventAddonName)
  if eventAddonName == CanICraftThis.addonName then
    initialise()
  end
end

EVENT_MANAGER:RegisterForEvent(CanICraftThis.addonName, EVENT_ADD_ON_LOADED, onAddOnLoaded)
