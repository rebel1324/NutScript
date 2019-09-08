/* Due to the amount of servers that have been absolutely braindead in their configuration, allowing assholes like me to write a nice little script to infinitely spawn money, I thought it's high time people used their brains. */

PLUGIN.name = "Crosshair"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "A Crosshair."

function PLUGIN:CanDeleteChar(ply, char)
  if char:getMoney() < nut.config.get("defMoney", 0) then
    return true
  end
end
