ITEM.name = "Stackable Item"
ITEM.desc = "A stackable item base"
ITEM.model = "models/Gibs/HGIBS.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.max = 1

ITEM.functions.split = {
  tip = "splitTip",
  icon = "icon16/box.png",
  onRun = function(item)
    local inventory = nut.item.inventories[item.invID]
    local half = math.floor(item:getData("amount")/2)
    item:setData("amount", item:getData("amount") - half)
    inventory:add(item.uniqueID, 1, {amount = half})
    return false
  end,
  onCanRun = function(item)
    return (item.max and item:getData("amount") > 1)
  end
}

if (CLIENT) then
  function ITEM:paintOver(self, w, h)
		if self.max and self:getData("amount") then
			 draw.SimpleText(self:getData("amount"), "nutSmallFont", w-3,h-2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black)
		end
	 end
end

function ITEM:onInstanced()
    if (self.max) then
      self:setData("amount", self:getData("amount") or 1)
    end
end

function ITEM:canCombine(item)
    return (self.uniqueID == item.uniqueID and self.max != 1)
end

function ITEM:onCombine(item)
  if (self.max) then

    if (self:getData("amount") < self.max) then
      self:setData("amount", self:getData("amount") + item:getData("amount"))

      if (self:getData("amount") > self.max) then
        item:setData("amount", self:getData("amount") - self.max)
        self:setData("amount", self.max)
      else
        item:remove()
      end
    end
  end
end
