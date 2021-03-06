CanICraftThis.StyleCollectibleCache = {
  version = 2,
}

function CanICraftThis.StyleCollectibleCache:open()
  local data = ZO_SavedVars:NewAccountWide(CanICraftThis.savedVarsName, self.version, "styleCollectibleCache", {}, GetWorldName())
  CanICraftThis.assert(data ~= nil, "data ~= nil")
  local instance = { data = data }
  setmetatable(instance, { __index = self })
  return instance
end

local recipesBySubCategory = {
  ["Staff"] = {
    ["staff$"] = {
      CanICraftThis.EqRecipe:fromName("Inferno Staff"),
      CanICraftThis.EqRecipe:fromName("Ice Staff"),
      CanICraftThis.EqRecipe:fromName("Lightning Staff"),
      CanICraftThis.EqRecipe:fromName("Restoration Staff"),
    },
  },
  ["Two-Handed"] = {
    ["battle axe$"] = {CanICraftThis.EqRecipe:fromName("Battle Axe")},
    ["maul$"] = {CanICraftThis.EqRecipe:fromName("Maul")},
    ["greatsword$"] = {CanICraftThis.EqRecipe:fromName("Greatsword")},
  },
  ["Bow"] = {
    ["bow$"] = {CanICraftThis.EqRecipe:fromName("Bow")},
  },
  ["Shield"] = {
    ["shield$"] = {CanICraftThis.EqRecipe:fromName("Shield")},
  },
  ["One-Handed"] = {
    ["axe$"] = {CanICraftThis.EqRecipe:fromName("Axe")},
    ["mace$"] = {CanICraftThis.EqRecipe:fromName("Mace")},
    ["sword$"] = {CanICraftThis.EqRecipe:fromName("Sword")},
    ["dagger$"] = {CanICraftThis.EqRecipe:fromName("Dagger")},
  },
  ["Feet"] = {
    ["sabatons$"] = {CanICraftThis.EqRecipe:fromName("Sabatons")},
    ["shoes$"] = {CanICraftThis.EqRecipe:fromName("Shoes")},
    ["boots$"] = {CanICraftThis.EqRecipe:fromName("Boots")},
  },
  ["Legs"] = {
    ["greaves$"] = {CanICraftThis.EqRecipe:fromName("Greaves")},
    ["breeches$"] = {CanICraftThis.EqRecipe:fromName("Breeches")},
    ["guards$"] = {CanICraftThis.EqRecipe:fromName("Guards")},
  },
  ["Waist"] = {
    ["girdle$"] = {CanICraftThis.EqRecipe:fromName("Girdle")},
    ["sash$"] = {CanICraftThis.EqRecipe:fromName("Sash")},
    ["belt$"] = {CanICraftThis.EqRecipe:fromName("Belt")},
  },
  ["Chest"] = {
    ["cuirass$"] = {CanICraftThis.EqRecipe:fromName("Cuirass")},
    ["robe$"] = {CanICraftThis.EqRecipe:fromName("Robe")},
    ["jerkin$"] = {CanICraftThis.EqRecipe:fromName("Jerkin")},
    ["jack$"] = {CanICraftThis.EqRecipe:fromName("Jack")},
  },
  ["Hands"] = {
    ["gauntlets$"] = {CanICraftThis.EqRecipe:fromName("Gauntlets")},
    ["gloves$"] = {CanICraftThis.EqRecipe:fromName("Gloves")},
    ["bracers$"] = {CanICraftThis.EqRecipe:fromName("Bracers")},
  },
  ["Head"] = {
    ["helm$"] = {CanICraftThis.EqRecipe:fromName("Helm")},
    ["hat$"] = {CanICraftThis.EqRecipe:fromName("Hat")},
    ["helmet$"] = {CanICraftThis.EqRecipe:fromName("Helmet")},
  },
  ["Shoulders"] = {
    ["pauldrons?$"] = {CanICraftThis.EqRecipe:fromName("Pauldron")},
    ["epaulets$"] = {CanICraftThis.EqRecipe:fromName("Epaulets")},
    ["arm cops$"] = {CanICraftThis.EqRecipe:fromName("Arm Cops")},
  },
}

local nameExceptions = {
  ["daedric skirt"] = "daedric breeches",
}

local function detectStyle(collectibleName)
  local style
  for _, style in pairs(CanICraftThis.EqStyle.instances) do
    if string.find(collectibleName, style.collectibleNamePattern) then
      return style
    end
  end
end

local function detectRecipes(collectibleName, subCategoryName)
  local recipesForSubCategory = recipesBySubCategory[subCategoryName]
  if #recipesForSubCategory == 1 then
    local _, recipesForCollectible = pairs(recipesForSubCategory)()
    return recipesForCollectible
  else
    local pattern, recipesForCollectible
    for pattern, recipesForCollectible in pairs(recipesForSubCategory) do
      if string.find(collectibleName, pattern) then
        return recipesForCollectible
      end
    end
  end
end

local function makeKey(style, recipe)
  return style.id * 100 + recipe.id
end

function CanICraftThis.StyleCollectibleCache:populate()
  local data = self.data
  local categoryIndex
  for categoryIndex = 1, GetNumCollectibleCategories() do
    local categoryName, numSubCategories = GetCollectibleCategoryInfo(categoryIndex)
    if categoryName == "Weapon Styles" or categoryName == "Armor Styles" then
      local subCategoryIndex
      for subCategoryIndex = 1, numSubCategories do
        local subCategoryName, numCollectibles = GetCollectibleSubCategoryInfo(categoryIndex, subCategoryIndex)
        local collectibleIndex
        for collectibleIndex = 1, numCollectibles do
          local collectibleId = GetCollectibleId(categoryIndex, subCategoryIndex, collectibleIndex)
          local collectibleName = GetCollectibleInfo(collectibleId)
          local collectibleName = string.gsub(string.lower(collectibleName), "%s*%d+$", "")
          local collectibleName = nameExceptions[collectibleName] or collectibleName
          local style = detectStyle(collectibleName)
          local recipes = detectRecipes(collectibleName, subCategoryName)
          if style ~= nil and recipes ~= nil then
            local recipe
            for _, recipe in ipairs(recipes) do
              self.data[makeKey(style, recipe)] = collectibleId
            end
          end
        end
      end
    end
  end
end

function CanICraftThis.StyleCollectibleCache:populateIfNeeded()
  if #self.data == 0 then
    self:populate()
  end
end

function CanICraftThis.StyleCollectibleCache:verify()
  local data = self.data
  local style
  for _, style in pairs(CanICraftThis.EqStyle.instances) do
    local recipe
    for _, recipe in pairs(CanICraftThis.EqRecipe.instancesByName) do
      if recipe.skill.equipmentInfo.usesStyle then
        if data[makeKey(style, recipe)] == nil then
          if style.name == "Outlaw" and recipe.name == "Robe" then
            -- Ignore; this style is a special case and does not have a Robe page.
            -- https://en.uesp.net/wiki/Online:Outlaw_Style#Notes
          elseif style.name == "Honor Guard" and recipe.name == "Jack" then
            -- Ignore; due to a bug in ESO's collectible database,
            -- no collectible ID yields the name "Honor Guard Jack", while
            -- multiple collectible IDs yield the name "Honor Guard Jerkin".
          else
            CanICraftThis.reportUnexpected("Failed to find a collectible ID for the " .. style.name .. " " .. recipe.name .. " style.")
          end
        end
      end
    end
  end
end

function CanICraftThis.StyleCollectibleCache:getCollectibleId(style, recipe)
  return self.data[makeKey(style, recipe)]
end
