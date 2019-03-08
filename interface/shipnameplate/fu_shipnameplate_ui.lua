require "/scripts/util.lua"
require "/scripts/interp.lua"

local currTypeIndex = 1;
local typeLen;

function init()
   shipTypes = {"Cruiser","Battleship","Fighter","Transport","Cargo","Recon","Explorer"}
   typeLen = getTableLength(shipTypes)
   
   shipName = config.getParameter("shipName", "was nil")
   shipType = config.getParameter("shipType", "was nil")

   widget.setText("tboxName",shipName)
   widget.setText("lblType",shipType)
end

function update(dt)
	
end

-- widget functions
function btnAccept_Click()

   object.setConfigParameter("shipName", widget.getText("tboxName"))
   object.setConfigParameter("shipType", widget.getText("lblType"))

   hasBeenSet = true
   
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