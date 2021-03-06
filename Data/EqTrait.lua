CanICraftThis.EqTrait = {
  instances = {},
}

function CanICraftThis.EqTrait:register(instance)
  CanICraftThis.assert(instance.id ~= nil, "instance.id ~= nil")
  instance.name = GetString("SI_ITEMTRAITTYPE", instance.id)
  instance.namePattern = CanICraftThis.literalPattern(instance.name)
  instance.writTextPattern = "trait: " .. instance.namePattern
  instance.categoryId = GetItemTraitTypeCategory(instance.id)
  table.insert(self.instances, instance)
end

function CanICraftThis.EqTrait:registerAll()
  local index
  for index = 1, GetNumSmithingTraitItems() do
    local id, materialName = GetSmithingTraitItemInfo(index)
    if id ~= nil then
      self:register { id = id }
    end
  end
end

CanICraftThis.EqTrait:registerAll()

function CanICraftThis.EqTrait:fromWritText(writText, recipe)
  local writText = string.lower(writText)
  local instance
  for _, instance in ipairs(self.instances) do
    if string.find(writText, instance.writTextPattern) and instance.categoryId == recipe.traitCategoryId then
      return instance
    end
  end
  CanICraftThis.reportUnexpected("writ text did not match any registered EqTrait: " .. writText)
  return nil
end
