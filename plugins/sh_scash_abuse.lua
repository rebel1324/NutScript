/* Due to the amount of servers that have been absolutely braindead in their configuration, allowing assholes like me to write a nice little script to infinitely spawn money, I thought it's high time people used their brains. */

PLUGIN.name = "Spawning money Anti-Abuse"
PLUGIN.author = "Rusty"
PLUGIN.desc = "Prevent people from using ye-olde classic money maker."

function PLUGIN:CanDeleteChar(ply, char)
  if char:getMoney() < nut.config.get("defMoney", 0) then
    return true
  end
end
