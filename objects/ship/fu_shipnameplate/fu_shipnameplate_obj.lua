require "/scripts/util.lua"
require "/scripts/interp.lua"



function init()
  object.setConfigParameter("shipName", "My Ship")
  object.setConfigParameter("shipType", "Cruiser")
  
  hasBeenSet = true
end

function update(dt)
	
end

function onInteraction(args)
  if hasBeenSet == true then
      object.sayPortrait("Reading the plague, it says the ship name is: "..config.getParameter("shipName", "was nil").."; It's also a "..config.getParameter("shipType", "was nil").." type of ship.")
   elseif hasBeenSet == false then
      return { "ScriptPane","/interface/shipnameplate/fu_shipnameplate.config" }
   end
end