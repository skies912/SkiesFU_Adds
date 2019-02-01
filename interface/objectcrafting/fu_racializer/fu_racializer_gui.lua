require "/scripts/util.lua"
require "/scripts/interp.lua"

local itemOld = nil
local itemOldCfg = nil
local itemNew = nil
local itemPGI = nil
local cost = 0

-- Table of allowed objects and their assets.
local raceTable --[[ = 
{
    --Vanilla Races
    ["Apex"]={
        ["icon"]="sapemale.png",
        ["items"]=
        {
            ["apexshiplocker"]="/objects/ship/apexshiplocker/apexshiplocker.png:default.default"
        }
    },
    ["Avian"]={
        ["icon"]="avianmale.png",
        ["items"]=
        {
            ["avianshiplocker"]="/objects/ship/avianshiplocker/avianshiplocker.png:default.default"
        }
    },
    ["Floran"]={
        ["icon"]="plantmale.png",
        ["items"]=
        {
            ["floranshiplocker"]="/objects/ship/floranshiplocker/floranshiplocker.png:default.default"
        }
    },
    ["Glitch"]={
        ["icon"]="robotmale.png",
        ["items"]=
        {
            ["glitchshiplocker"]="/objects/ship/glitchshiplocker/glitchshiplocker.png:default.default"
        }
    },
    ["Human"]={
        ["icon"]="humanmale.png",
        ["items"]=
        {
            ["humanshiplocker"]="/objects/ship/humanshiplocker/humanshiplocker.png:default.default"
        }
    },
    ["Hylotl"]={
        ["icon"]="aquaticmale.png",
        ["items"]=
        {
            ["hylotlshiplocker"]="/objects/ship/hylotlshiplocker/hylotlshiplocker.png:default.default"
        }
    },
    ["Novakid"]={
        ["icon"]="novakidmale.png",
        ["items"]=
        {
            ["novakidshiplocker"]="/objects/ship/novakidshiplocker/novakidshiplocker.png:default.default"
        }
    },
    -- FU Races
    -- As of 10/5/18, Thelusians and Radiens do not have any themed ship items
    ["Kirhos"]={
        ["icon"]="kirhosmale.png",
        ["items"]=
        {
            ["kirhosshiplocker"]="/objects/ship/kirhosshiplocker/kirhosshiplocker.png:default.default"
        }
    },
    ["Shadow"]={
        ["icon"]="shadowmale.png",
        ["items"]=
        {
            ["shadowshiplocker"]="/objects/ship/shadowshiplocker/shadowshiplocker.png:default.default"
        }
    }
    -- Other Races
    
} --]]

function init()
  raceTable = buildRaceTable()
  populateList()
  widget.setButtonEnabled("btnConvert",false)
  self.baseCost = config.getParameter("cost", 100)
  self.costModifier = config.getParameter("costModifier", 4)
end

function populateList()
  self.raceList = "scr_raceList.raceList"
  self.selectedText = nil
  
  widget.clearListItems(self.raceList)
  local raceArray = {}
  for race, _ in pairs (raceTable) do
    table.insert(raceArray, race)
  end
  table.sort(raceArray)
  for _, race in ipairs (raceArray) do
	if race ~= "Fu_byos" then
      local item = string.format("%s.%s", self.raceList, widget.addListItem(self.raceList))
	  widget.setText(string.format("%s.title", item), race)
      widget.setImage(string.format("%s.icon", item), "/interface/title/"..raceTable[race].icon)
      widget.setData(item, {title = race})
	end
  end
  --[[ for raceKey,raceVal in pairs(raceTable) do
    local item = string.format("%s.%s", self.raceList, widget.addListItem(self.raceList))
    widget.setText(string.format("%s.title", item), raceKey)
    widget.setImage(string.format("%s.icon", item), "/interface/title/"..raceVal.icon)
    widget.setData(item, {title = raceKey})
  end ]]--
end

function update(dt)
    local cfg = nil
    local setCost = true
    
    itemOld = world.containerItemAt(pane.containerEntityId(),0)
    itemPGI = world.containerItemAt(pane.containerEntityId(),1)
    ItemNew = world.containerItemAt(pane.containerEntityId(),2)
    
    cost = self.baseCost
	if itemPGI == nil then
		cost = round(cost * self.costModifier,0)
    end

    if itemOld and itemOld.name ~= oldItemOld then	--Prevent checking every update
        --Validate slot#1 contains a racial item (exists in the above table)
        itemOldCfg = root.itemConfig(itemOld).config
		itemOldRace = itemOldCfg.objectName:gsub("captainschair", ""):gsub("fuelhatch", ""):gsub("shipdoor", ""):gsub("shiphatch", ""):gsub("shiplocker", ""):gsub("techstation", ""):gsub("teleporter", ""):gsub("deco", "")
		if itemOldRace == "" then
			itemOldRace = "apex"
		end
        local raceStr = itemOldRace:gsub(itemOldRace:sub(0,1),itemOldRace:sub(0,1):upper(),1) -- Meh, this mess is to make the first letter uppercase to match the list item.
        --sb.logInfo(itemOldCfg.objectName)
        --sb.logInfo(itemOldCfg.race)
        --sb.logInfo(raceStr)
        if raceTable[raceStr] and raceTable[raceStr]["items"][itemOldCfg.objectName] then
            widget.setImage("imgPreviewIn", raceTable[raceStr]["items"][itemOldCfg.objectName])
            widget.setText(string.format("%s",  "races1Label"), "Supported Races  |  Input ("..raceStr..")" )
			oldItemOld = itemOld.name
			self.newName = nil
			raceList_SelectedChanged()
        else
            widget.setImage("imgPreviewIn", "")
            eject(0)
			oldItemOld = nil
			self.newName = nil
        end
    elseif not itemOld or itemOld.name ~= oldItemOld then
        widget.setImage("imgPreviewIn", "")
        widget.setImage("imgPreviewOut", "")
        widget.setText("lblCost", "Cost:   x--")
        widget.setText("preview_lbl2", "Output: --")
		widget.setText("races1Label", "Supported Races  |  Input + Preview")
        setCost = false
		oldItemOld = nil
		self.newName = nil
    end
    
    if itemPGI then
        --Validate slot#2 contains a PGI
        cfg = root.itemConfig(itemPGI).config
        if cfg.objectName ~= "perfectlygenericitem" then
            eject(1)
        end
    end
    
    if not self.newName then
        setCost = false
    end
    
    if setCost == true then
        --Update the cost label
        widget.setText("lblCost", "Cost:   x"..cost)
		if world.getObjectParameter(pane.containerEntityId(), "racialising") then
			widget.setButtonEnabled("btnConvert",false)
		elseif ItemNew then
			widget.setButtonEnabled("btnConvert",false)			--Eventually make this take into account whether the item can actually fit
		else
			widget.setButtonEnabled("btnConvert",true)
		end
    elseif setCost == false then
        widget.setButtonEnabled("btnConvert",false)
    end
end

function btnConvert_Clicked()
    if  player.currency("money") >= cost then
        widget.playSound("/sfx/interface/fu_racializer_working.ogg", 0, 1.5)
        world.sendEntityMessage(pane.containerEntityId(), "doWorkAnim")
        
        --Create new item
        itemNew = {name = self.newName, count =itemOld.count, parameters = {}}
        itemNew.parameters = itemOld.parameters

        player.consumeCurrency("money",cost)
        --sb.logInfo("Money consumed...")
        world.containerTakeAt(pane.containerEntityId(),0)
        --sb.logInfo("Old item taken from slot 0...")
        world.containerTakeNumItemsAt(pane.containerEntityId(),1,1)
        --sb.logInfo("One PGI taken from slot 1...")
        
        --start crafting
		world.sendEntityMessage(pane.containerEntityId(), "startRacialising", {itemNew= itemNew, itemOld = itemOld, itemPGI = itemPGI, cost = cost})
    else
        widget.playSound("/sfx/interface/clickon_error.ogg", 0, 1.25)
    end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  mult = math.floor(num * mult + 0.5) / mult
  return math.floor(mult) -- Do it again to remove the decimal point (why is this even needed??)
end

--Eject the item at the specified itemGrid index
function eject(index)
    player.giveItem(world.containerItemAt(pane.containerEntityId(),index))
    world.containerTakeAt(pane.containerEntityId(),index)
    widget.playSound("/sfx/interface/clickon_error.ogg", 0, 1.25)
end

--Update selectedText variable
function raceList_SelectedChanged()
    local listItem = widget.getListSelected(self.raceList)
    if listItem then
        local itemData = widget.getData(string.format("%s.%s", self.raceList, listItem))
        if itemData then
            self.selectedText = itemData.title
            if (itemOld and itemPGI and self.selectedText) or ((itemOld and not itemPGI) and self.selectedText) then
                --update the preview output image with the value of the associated race.
                widget.setText(string.format("%s",  "preview_lbl2"), "Output ("..self.selectedText..")" )
                local oldName = itemOldCfg.objectName
                local oldRace = itemOldRace
                local base = oldName:gsub(oldRace, ""):gsub("deco", "")
                self.newName = string.lower(self.selectedText)..base
                --sb.logInfo(base)
                --sb.logInfo(self.newName)
				if root.itemConfig(self.newName) then
					local path = raceTable[self.selectedText]["items"][self.newName]
					widget.setImage("imgPreviewOut", path)
				elseif string.lower(self.selectedText) == "apex" then
					self.newName = base
					if root.itemConfig(self.newName) then
						local path = raceTable[self.selectedText]["items"][self.newName]
						widget.setImage("imgPreviewOut", path)
					else
						self.newName = false
						widget.setImage("imgPreviewOut", "")
						widget.setText(string.format("%s",  "preview_lbl2"), "Output: --")
						widget.setText("lblCost", "Cost:   x--")
					end
				else
					self.newName = false
					widget.setImage("imgPreviewOut", "")
					widget.setText(string.format("%s",  "preview_lbl2"), "Output: --")
					widget.setText("lblCost", "Cost:   x--")
				end
            end
        else
            self.selectedText = "itemData not set" --in case something went wrong
        end 
    end
end

function buildRaceTable()
	local tempRaceTable = {}
	local raceObjects = {"captainschair", "fuelhatch", "shipdoor", "shiphatch", "shiplocker", "techstation", "teleporter"}
	local races = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
	for _, race in pairs (races) do
		local raceName = race:gsub(race:sub(0,1),race:sub(0,1):upper(),1)
		tempRaceTable[raceName] = {}
		tempRaceTable[raceName].icon = race .. "male.png"
		tempRaceTable[raceName].items = {}
		for _, objectType in pairs (raceObjects) do
			local objectInfo = root.itemConfig(race .. objectType)
			if objectInfo then
				local objectOrientations = objectInfo.config.orientations[1]
				local objectImage
				if objectOrientations.imageLayers then
					objectImage = objectOrientations.imageLayers[1].image
				else
					objectImage = objectOrientations.dualImage or objectOrientations.image
				end
				local objectDirectory = objectInfo.directory .. objectImage
				tempRaceTable[raceName].items[race .. objectType] = objectDirectory:gsub("<frame>", 0):gsub("<color>", "default"):gsub("<key>", 1)
			end
		end
		local hasObjects = false
		for object, _ in pairs (tempRaceTable[raceName].items) do
			hasObjects = true
			break
		end
		if not hasObjects then
			tempRaceTable[raceName] = nil
			--sb.logInfo("Removing " .. tostring(raceName))
		end
	end
	util.mergeTable(tempRaceTable, root.assetJson("/interface/objectcrafting/fu_racializer/fu_racializer_racetableoverride.config"))
	return tempRaceTable
end