local PLAYER = FindMetaTable("Player")

-- I suggest you to follow the Nutscript Coding Rules.
-- This is just for the DarkRP things mate.
-- trust me, you're going to use character class a lot if you're going to make something with Nutscript.

function PLAYER:addMoney(amt)
    local char = self:getChar()

    if (char) then
        char:giveMoney(amt)
    end
end

function PLAYER:takeMoney()
    local char = self:getChar()

    if (char) then
        char:giveMoney(-amt)
    end
end

function PLAYER:getMoney()
    local char = self:getChar()
    return (char and char:getMoney() or 0)
end

function PLAYER:canAfford(amount)
    local char = self:getChar()
    return (char and char:hasMoney(amount))
end

if (CLIENT) then
    netstream.Hook("nutSyncGesture", function(entity, a, b, c)
        if (IsValid(entity)) then
            entity:AnimRestartGesture(a, b, c)
        end
    end)
end

function PLAYER:doGesture(a, b, c)
    self:AnimRestartGesture(a, b, c)
    netstream.Start(self:GetPos(), "nutSyncGesture", self, a, b, c)
end