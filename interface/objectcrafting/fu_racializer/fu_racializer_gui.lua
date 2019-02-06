require "/scripts/util.lua"
require "/scripts/interp.lua"

local itemOld = nil
local itemOldCfg = nil
local itemNew = nil
local itemPGI = nil
local cost = 0

-- Table of allowed objects.
local raceTable

function init()
  self.baseCost = config.getParameter("cost", 100)
  self.costModifier = config.getParameter("costModifier", 4)
  self.itemConversions = config.getParameter("objectConversions", {})
  self.newItem = {}
  self.raceTableOverride = root.assetJson("/interface/objectcrafting/fu_racializer/fu_racializer_racetableoverride.config")
  raceTable = buildRaceTable()
  populateList()
  widget.setButtonEnabled("btnConvert",false)
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
		local itemOldInfo = root.itemConfig(itemOld)
        itemOldCfg = itemOldInfo.config
		itemOldRace = itemOldCfg.objectName:gsub("captainschair", ""):gsub("fuelhatch", ""):gsub("shipdoor", ""):gsub("shiphatch", ""):gsub("shiplocker", ""):gsub("techstation", ""):gsub("teleporter", ""):gsub("deco", "")
		if itemOldRace == "" then
			itemOldRace = "apex"
		end
        local raceStr = itemOldRace:gsub(itemOldRace:sub(0,1),itemOldRace:sub(0,1):upper(),1) -- Meh, this mess is to make the first letter uppercase to match the list item.
        --sb.logInfo(itemOldCfg.objectName)
        --sb.logInfo(itemOldCfg.race)
        --sb.logInfo(raceStr)
        if raceTable[raceStr] and raceTable[raceStr]["items"][itemOldCfg.objectName] then
			local oldObjectCfg = util.mergeTable(itemOldCfg, itemOld.parameters)
            widget.setImage("imgPreviewIn", oldObjectCfg.placementImage or getPlacementImage(oldObjectCfg.imageConfig or oldObjectCfg.defaultImageConfig or oldObjectCfg.orientations, itemOldInfo.directory))
            widget.setText(string.format("%s",  "races1Label"), "Supported Races  |  Input: "..raceStr)
			oldItemOld = itemOld.name
			self.newName = nil
			self.newItem = {}
			raceList_SelectedChanged()
        else
            widget.setImage("imgPreviewIn", "")
            eject(0)
			oldItemOld = nil
			self.newName = nil
			self.newItem = {}
        end
    elseif not itemOld or itemOld.name ~= oldItemOld then
        widget.setImage("imgPreviewIn", "")
        widget.setImage("imgPreviewOut", "")
        widget.setText("lblCost", "Cost:   x--")
        widget.setText("preview_lbl2", "Output: --")
		widget.setText("races1Label", "Supported Races  |  Input: --")
        setCost = false
		oldItemOld = nil
		self.newName = nil
		self.newItem = {}
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
        itemNew = {name = self.newItem.type, count = itemOld.count, parameters = {}}
        itemNew.parameters = itemOld.parameters
		itemNew.parameters.shortdescription = self.newItem.name
		itemNew.parameters.shipPetType = itemNewInfo.config.shipPetType
		itemNew.parameters.orientations = nil
		itemNew.parameters.racialisedTo = self.newName
		itemNew.parameters = util.mergeTable(itemNew.parameters, getNewParameters(itemNewInfo, self.newItem.positionOverride))
		

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
				self.newItem.type = self.itemConversions[oldName] or self.itemConversions[base]
				self.newItem.name = root.itemConfig(self.newItem.type).config.shortdescription .. " (" .. self.selectedText .. ")"
				local newItemData = raceTable[self.selectedText].items[self.newName]
				if type(newItemData) == "table" then
					self.newItem.positionOverride = newItemData
				else
					self.newItem.positionOverride = nil
				end
                --sb.logInfo(base)
                --sb.logInfo(self.newName)
				itemNewInfo = root.itemConfig(self.newName) or {}
				local itemNewCfg = itemNewInfo.config
				if itemNewCfg then
					widget.setImage("imgPreviewOut", itemNewCfg.placementImage or getPlacementImage(itemNewCfg.orientations, itemNewInfo.directory))
				elseif string.lower(self.selectedText) == "apex" then
					self.newName = base
					itemNewInfo = root.itemConfig(self.newName) or {}
					local itemNewCfg = itemNewInfo.config
					if itemNewCfg then
						widget.setImage("imgPreviewOut", itemNewCfg.placementImage or getPlacementImage(itemNewCfg.orientations, itemNewInfo.directory))
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
	local raceObjects = config.getParameter("raceObjects")
	local races = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
	for _, race in pairs (races) do
		local raceName = race:gsub(race:sub(0,1),race:sub(0,1):upper(),1)
		tempRaceTable[raceName] = {}
		tempRaceTable[raceName].icon = race .. "male.png"
		tempRaceTable[raceName].items = {}
		for _, objectType in pairs (raceObjects) do
			local objectInfo = root.itemConfig(race .. objectType)
			if objectInfo then
				tempRaceTable[raceName].items[race .. objectType] = true
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
	for race, info in pairs (self.raceTableOverride) do
		if race == "Fu_byos" then
			tempRaceTable[race] = {items = {}}
		end
		if tempRaceTable[race] then
			tempRaceTable[race].icon = info.icon or tempRaceTable[race].icon
			if info.items then
				for item, itemInfo in pairs (info.items) do
					if root.itemConfig(item) then
						tempRaceTable[race].items[item] = itemInfo
					end
				end
			end
		end
	end
	return tempRaceTable
end

function getPlacementImage(objectOrientations, objectDirectory, positionOverride)
	local objectOrientation = objectOrientations[1]
	local objectImage
	if objectOrientation.imageLayers then
		objectImage = objectOrientation.imageLayers[1].image
	else
		objectImage = objectOrientation.dualImage or objectOrientation.image
	end
	local newPlacementImage = objectDirectory .. objectImage
	
	local newPlacementImagePosition = objectOrientation.imagePosition
	if positionOverride then
		newPlacementImagePosition = positionOverride
	end
	return newPlacementImage:gsub("<frame>", 0):gsub("<color>", "default"):gsub("<key>", 1), newPlacementImagePosition
end

function getNewParameters(newItemInfo, positionOverride)
	local newParameters = {}
	if newItemInfo then
		newParameters.inventoryIcon = newItemInfo.directory .. newItemInfo.config.inventoryIcon
		newParameters.placementImage, newParameters.placementImagePosition = getPlacementImage(newItemInfo.config.orientations, newItemInfo.directory, positionOverride)
		newParameters.imageConfig = getNewOrientations(newItemInfo, positionOverride)
		newParameters.imageFlipped = newItemInfo.config.sitFlipDirection
	end
	return newParameters
end

function getNewOrientations(newItemInfo, positionOverride)
	local newOrientations = newItemInfo.config.orientations
	for num, _ in pairs (newOrientations) do
		local imageLayers = newOrientations[num].imageLayers
		if imageLayers then
			for num2, _ in pairs (imageLayers) do
				local imageLayer = imageLayers[num2].image
				newOrientations[num].imageLayers[num2].image = newItemInfo.directory .. imageLayer
			end
		end
		local dualImage = newOrientations[num].dualImage
		if dualImage then
			newOrientations[num].dualImage = newItemInfo.directory .. dualImage
		end
		local image = newOrientations[num].image
		if image and not imageLayers then --Avali teleporter fix
			newOrientations[num].image = newItemInfo.directory .. image
		end
	end
	if positionOverride then
		newOrientations[1].imagePosition = positionOverride
	end
	return newOrientations
end