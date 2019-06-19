require "/scripts/util.lua"
require "/scripts/interp.lua"

shipTypes = {"Battleship","Cargo","Cruiser","Explorer","Fighter","Recon","Transport","Shuttle"}
local currTypeIndex = 1;
local typeLen;

function init()  
   typeLen = getTableLength(shipTypes)

   widget.setText("tboxName","My Ship")
   widget.setText("lblType","Cruiser")
end

function update(dt)
	
end

-- widget functions
function btnAccept_Click()
   local name = widget.getText("tboxName")
   local stype = widget.getText("lblType.value")
   
   if stype ~= nil then
      sb.logInfo(stype)
   else 
      sb.logInfo("stype == nil!")
   end
   
   world.sendEntityMessage(pane.sourceEntity(), "setVars", {name,stype})
   pane.dismiss()
end

function btnPickLeft_Click()
   if currTypeIndex >1 then
      currTypeIndex =currTypeIndex -1
      widget.setText("lblType",shipTypes[currTypeIndex])
   end   
end

function btnPickRight_Click()
   if currTypeIndex < typeLen then
      currTypeIndex = currTypeIndex +1
      widget.setText("lblType",shipTypes[currTypeIndex])
   end   
end

--util
function getTableLength(t)
   count = 0
   for k,v in pairs(t) do
        count = count + 1
   end
   return count
end