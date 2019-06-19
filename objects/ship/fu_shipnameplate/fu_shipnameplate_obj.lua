require "/scripts/util.lua"
require "/scripts/interp.lua"


shipTypes = {"Battleship","Cargo","Cruiser","Explorer","Fighter","Recon","Transport","Shuttle"}
self.shipName = "My Ship"
self.shipType = "Cruiser"


function init()
   self.hasBeenSet = false
   
   message.setHandler("setVars", function(shipN,shipT)
      sb.logInfo("info == \""..shipN.."\", \""..shipT.."\"")
      local a = false
      if shipN ~=nil then
         self.shipName = shipN
         a=true
      end
      if shipTypes[shipT] ~= nil then
         self.shipType = shipT
         a=true
      end
      if a==true then
         self.hasBeenSet = true
         sb.logInfo("info's been set!")
      end
	end)
end

function update(dt)
	
end

function onInteraction(args)
  if self.hasBeenSet == true then
      object.sayPortrait("Reading the plague, it says the ship name is: "..shipName.."; It's also a "..shipType)
   elseif hasBeenSet == false then
      return { "ScriptPane","/interface/shipnameplate/fu_shipnameplate.config" }
   end
end