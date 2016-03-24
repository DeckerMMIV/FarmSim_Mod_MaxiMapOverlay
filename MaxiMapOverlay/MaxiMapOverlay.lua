--
-- MaxiMap Overlay - Adding more functionality for the maxi-map
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com
-- @date    2015-11-xx
--

local modItem = ModsUtil.findModItemByModName(g_currentModName);

MaxiMapOverlay = {

version = (modItem and modItem.version) and modItem.version or "?.?.?",
modDir = g_currentModDirectory,
initialized = false,

loadMap = function(self, name)
    --
    self.foliageStateOverlay = createFoliageStateOverlay("maxiMapOverlay", 512, 512);
    self.overlayRefreshIntervalSecs = 15
    self.overlayPage = 0 -- 0=off
    self.currentPanes = {}
    self.legendFruits = {}
    self.paneOverlay = createImageOverlay(Utils.getFilename("$dataS2/menu/white.png"));

    --
    self.pdaBeepSound = createSample("pdaBeepSample")
    loadSample(self.pdaBeepSound, Utils.getFilename("pdaBeep.wav", self.modDir), false)
    
    --
    -- ATTENTION! Please use my AAA_ModsSettings.ZIP mod, to customize you personal settings for MaxiMapOverlay.
    --
    self.growthColors = {
        ["growing"] = {
            {0.00; 0.45; 1.00; 1}; 
            {0.00; 0.31; 0.86; 1}; 
            {0.00; 0.20; 0.70; 1}; 
            {0.00; 0.10; 0.60; 1};
            {0.00; 0.10; 0.50; 1};
        };
        ["readyToHarvest"] = {
            {0.00; 0.90; 0.10; 1}; 
            {0.00; 0.70; 0.10; 1}; 
            {0.00; 0.50; 0.20; 1};
        };
        ["readyToPrepare"] = {
            {0.50; 0.90; 1.00; 1};
            {0.30; 1.00; 0.90; 1};
            {0.10; 1.00; 0.80; 1};
        };
        ["cutted"] = {
            {0.10; 0.10; 0.10; 1};
        };
        ["withered"] = {
            {0.70; 0.00; 0.10; 1};
        };
    }

    --
    -- ATTENTION! Please use my AAA_ModsSettings.ZIP mod, to customize you personal settings for MaxiMapOverlay.
    --
    FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_GRASS].mod_HideFruitOnMap = true

    --
    local function setFruitGroup(fruitType, fruitGroupNum)
        if fruitType ~= nil then
            local desc = FruitUtil.fruitIndexToDesc[fruitType]
            if desc ~= nil then
                desc.mod_FruitGroupNum = fruitGroupNum
            end
        end
    end
    
    --
    -- ATTENTION! Please use my AAA_ModsSettings.ZIP mod, to customize you personal settings for MaxiMapOverlay.
    --
    setFruitGroup(FruitUtil.FRUITTYPE_WHEAT       , 1)
    setFruitGroup(FruitUtil.FRUITTYPE_BARLEY      , 1)
    setFruitGroup(FruitUtil.FRUITTYPE_OAT         , 1)
    setFruitGroup(FruitUtil.FRUITTYPE_RYE         , 1)
    setFruitGroup(FruitUtil.FRUITTYPE_DINKEL      , 1) -- Spelt
    setFruitGroup(FruitUtil.FRUITTYPE_TRITICALE   , 1)

    --
    -- ATTENTION! Please use my AAA_ModsSettings.ZIP mod, to customize you personal settings for MaxiMapOverlay.
    --
    setFruitGroup(FruitUtil.FRUITTYPE_RAPE        , 2)
    setFruitGroup(FruitUtil.FRUITTYPE_OSR         , 2)
    setFruitGroup(FruitUtil.FRUITTYPE_SORGHUM     , 2)
    setFruitGroup(FruitUtil.FRUITTYPE_HOPS        , 2)

    --
    -- ATTENTION! Please use my AAA_ModsSettings.ZIP mod, to customize you personal settings for MaxiMapOverlay.
    --
    setFruitGroup(FruitUtil.FRUITTYPE_MAIZE       , 3)
    setFruitGroup(FruitUtil.FRUITTYPE_SUNFLOWER   , 3)

    --
    -- ATTENTION! Please use my AAA_ModsSettings.ZIP mod, to customize you personal settings for MaxiMapOverlay.
    --
    setFruitGroup(FruitUtil.FRUITTYPE_POTATO      , 4)
    setFruitGroup(FruitUtil.FRUITTYPE_SUGARBEET   , 4)
    setFruitGroup(FruitUtil.FRUITTYPE_ONION       , 4)
    setFruitGroup(FruitUtil.FRUITTYPE_CARROT      , 4)

    --
    -- ATTENTION! Please use my AAA_ModsSettings.ZIP mod, to customize you personal settings for MaxiMapOverlay.
    --
    setFruitGroup(FruitUtil.FRUITTYPE_GRASS       , 10)
    setFruitGroup(FruitUtil.FRUITTYPE_DRYGRASS    , 10) -- "Hay"
    setFruitGroup(FruitUtil.FRUITTYPE_KLEE        , 10) -- Clover
    setFruitGroup(FruitUtil.FRUITTYPE_LUZERNE     , 10) -- Alfalfa
    setFruitGroup(FruitUtil.FRUITTYPE_CLOVER      , 10) -- Klee
    setFruitGroup(FruitUtil.FRUITTYPE_ALFALFA     , 10) -- Luzerne
    
    --
    if  ModsSettings ~= nil
    and ModsSettings.isVersion ~= nil 
    and ModsSettings.isVersion("0.1.0", "MaxiMapOverlay")
    then
        local modName = "MaxiMapOverlay"
        self.overlayRefreshIntervalSecs = ModsSettings.getIntLocal(modName, "mapOverlay", "refreshInterval", self.overlayRefreshIntervalSecs)
    
        --
        function getCustomColor(modName, keyName, attrName, defaultColorArray)
            local defColor = ("%.3f %.3f %.3f"):format(defaultColorArray[1], defaultColorArray[2], defaultColorArray[3])
            defColor = ModsSettings.getStringLocal(modName, keyName, attrName, defColor);
            defColor = Utils.getVectorNFromString(defColor, 3)
            if defColor ~= nil then
                if #defaultColorArray == 4 then
                    table.insert(defColor, defaultColorArray[4])
                end
                return defColor
            end
            return defaultColorArray
        end
    
        for fruitType,fruitDesc in pairs(FruitUtil.fruitIndexToDesc) do
            if fruitDesc.fruitMapColor ~= nil and #fruitDesc.fruitMapColor >= 3 then
                local keyName = "Fruit_" .. fruitDesc.name
                fruitDesc.fruitMapColor      = getCustomColor(           modName, keyName, "color",     fruitDesc.fruitMapColor     )
                fruitDesc.mod_HideFruitOnMap = ModsSettings.getBoolLocal(modName, keyName, "hideOnMap", fruitDesc.mod_HideFruitOnMap)
                fruitDesc.mod_FruitGroupNum  = ModsSettings.getIntLocal( modName, keyName, "groupNum",  Utils.getNoNil(fruitDesc.mod_FruitGroupNum, 99))
            end
        end

        for growthType,growthDesc in pairs(self.growthColors) do
            local keyName = "Growth_"..growthType
            for i=1,#growthDesc do
                local attrName = ("color%d"):format(i)
                growthDesc[i] = getCustomColor(modName, keyName, attrName, growthDesc[i])
            end
        end
    else
        print("")
        print("MaxiMapOverlay: Optional 'AAA_ModsSettings'-mod not found or not required version. Unable to use player customized settings for the 'MaxiMapOverlay'-mod.")
        print("")
        self.isMissingModsSettingsMod = true
    end

    --
    if not self.initialized then
        -- Need to render the overlay _after_ the actual in-game PDA map,
        -- so using "painter's algorithm"... well, if that can be said about 'code'.
        IngameMap.draw = Utils.appendedFunction(IngameMap.draw, MaxiMapOverlay.ingameMapDraw)
        self.initialized = true
    end
end,

deleteMap = function(self)
    delete(self.paneOverlay)
    delete(self.pdaBeepSound)
    delete(self.foliageStateOverlay)
end,

mouseEvent = function(self, posX, posY, isDown, isUp, button)
    if self.isEditable then
        if isDown then
            for idx,pane in pairs(self.currentPanes) do
                if pane.inBox ~= nil and pane:inBox(posX,posY) then
                    if pane.onMouseEvent ~= nil then
                        pane:onMouseEvent(posX, posY, isDown, isUp, button)
                    end
                end
            end
        end
    end
end,

keyEvent = function(self, unicode, sym, modifier, isDown)
end,

refreshMapOverlay = function(self, pageNum, updateLegend)
    if pageNum == 1 then
        self:refreshMapOverlayFruit(updateLegend)
    elseif pageNum == 2 then
        self:refreshMapOverlayGrowth(updateLegend)
    else
        self.overlayReadyState = 0;
        resetFoliageStateOverlay(self.foliageStateOverlay);
    end
end,

refreshMapOverlayFruit = function(self, updateLegend)
    self.overlayReadyState = 0;
    resetFoliageStateOverlay(self.foliageStateOverlay)

    if updateLegend then
        self.legendFruits = {}
    end

    for fruitType,fruit in pairs(g_currentMission.fruits) do
        if fruit ~= nil and fruit.id ~= nil and fruit.id ~= 0 then
            local fruitDesc = FruitUtil.fruitIndexToDesc[fruitType]
            if fruitDesc ~= nil and fruitDesc.fruitMapColor ~= nil then
                if updateLegend then
                    local element = { 
                        groupNum    = Utils.getNoNil(fruitDesc.mod_FruitGroupNum, 99),
                        hidden      = fruitDesc.mod_HideFruitOnMap, 
                        color       = fruitDesc.fruitMapColor, 
                        title       = Fillable.fillTypeIndexToDesc[FruitUtil.fruitTypeToFillType[fruitType]].nameI18N,
                        fruitType   = fruitType,
                    }
                    
                    if ModsSettings ~= nil and ModsSettings.setStringLocal ~= nil and ModsSettings.setBoolLocal ~= nil then
                        local fruitName = fruitDesc.name
                        local modName = "MaxiMapOverlay"
                        local keyName = "Fruit_" .. fruitName
                        
                        element.setColor = function(self,color)
                            fruitDesc.fruitMapColor = color
                            self.color = color
                            --
                            local attrValue = ("%.3f %.3f %.3f"):format(color[1],color[2],color[3])
                            ModsSettings.setStringLocal(modName, keyName, "color", attrValue)
                        end
                        element.setVisibility = function(self,visible)
                            fruitDesc.mod_HideFruitOnMap = visible
                            self.hidden = visible
                            --
                            local attrValue = (visible == true) -- In case ´visible´ is not of type bool.
                            ModsSettings.setBoolLocal(modName, keyName, "hideOnMap", attrValue)
                        end
                    else
                        element.setColor = function(self,color)
                            fruitDesc.fruitMapColor = color
                            self.color = color
                        end
                        element.setVisibility = function(self,visible)
                            fruitDesc.mod_HideFruitOnMap = visible
                            self.hidden = visible
                        end
                    end
                    
                    table.insert(self.legendFruits, element);
                end

                if not fruitDesc.mod_HideFruitOnMap then
                    setFoliageStateOverlayFruitTypeColor(self.foliageStateOverlay, fruit.id, unpack(fruitDesc.fruitMapColor, 1, 3))
                end
            end
        end
    end

    if updateLegend then
        table.sort(
            self.legendFruits,
            function(elem1, elem2)
                if elem1.groupNum < elem2.groupNum then
                    return true
                end
                if elem1.groupNum == elem2.groupNum then
                    return elem1.title:lower() < elem2.title:lower()
                end
                return false
            end
        );
    end
    
    generateFoliageStateOverlayFruitTypeColors(self.foliageStateOverlay)
    self.overlayReadyState = 1;
end,

refreshMapOverlayGrowth = function(self, updateLegend)
    self.overlayReadyState = 0;
    resetFoliageStateOverlay(self.foliageStateOverlay)

    if updateLegend then
        local sequence = {
            "growing",
            "readyToPrepare",
            "readyToHarvest",
            "withered",
            "cutted",
        }
        self.legendFruits = {}
        for i=1,#sequence do
            local growthType = sequence[i]
            for j=1,#self.growthColors[growthType] do
                local element = { 
                    groupNum    = i,
                    title       = g_i18n:getText(("%s%d"):format(growthType,j)),
                    color       = MaxiMapOverlay.growthColors[growthType][j],
                }
                
                local jj = j
                if ModsSettings ~= nil and ModsSettings.setStringLocal ~= nil then
                    local modName = "MaxiMapOverlay"
                    local keyName = "Growth_" .. growthType
                    local attrName = ("color%d"):format(jj)
                    
                    element.setColor = function(self,color)
                        MaxiMapOverlay.growthColors[growthType][jj] = color
                        self.color = color
                        --
                        local attrValue = ("%.3f %.3f %.3f"):format(color[1],color[2],color[3])
                        ModsSettings.setStringLocal(modName, keyName, attrName, attrValue)
                    end
                else
                    element.setColor = function(self,color)
                        MaxiMapMod.growthColors[growthType][jj] = color
                        self.color = color
                    end
                end
                element.setVisibility = function(self,visible) end
                
                table.insert(self.legendFruits, element);
            end
        end
        
    end
    
    for fruitType,fruit in pairs(g_currentMission.fruits) do
      if fruit ~= nil then
        local foliageId = fruit.id
        local fruitDesc = FruitUtil.fruitIndexToDesc[fruitType]
        
        if foliageId ~= nil and foliageId ~= 0 
        and fruitDesc ~= nil and (not fruitDesc.mod_HideFruitOnMap) and fruitDesc.minHarvestingGrowthState > 0
        then
            local minMatureValue =          1 + (fruitDesc.minPreparingGrowthState>=0 and fruitDesc.minPreparingGrowthState or fruitDesc.minHarvestingGrowthState)
            local maxMatureValue = math.max(1 + (fruitDesc.maxPreparingGrowthState>=0 and fruitDesc.maxPreparingGrowthState or fruitDesc.maxHarvestingGrowthState), minMatureValue)
        
            local minGrowthValue =          1
            local maxGrowthValue = math.max(minMatureValue - 1, minGrowthValue)

            local minHarvestValue =          1 + fruitDesc.minHarvestingGrowthState
            local maxHarvestValue = math.max(1 + fruitDesc.maxHarvestingGrowthState, minHarvestValue)
            
            local cuttedValue = 1 + fruitDesc.cutState

            local witheredValue = 0
            -- Needs preparing?
            if fruitDesc.maxPreparingGrowthState >= 0 then
                -- ...and can be withered?
                if fruitDesc.minPreparingGrowthState < fruitDesc.maxPreparingGrowthState then -- Assumption that if there are multiple stages for preparing, then it can be withered too.
                    witheredValue = maxMatureValue  -- Assumption that 'withering' is just after max-mature.
                end
            else
                -- Can be withered?
                if fruitDesc.cutState > fruitDesc.maxHarvestingGrowthState then -- Assumption that if 'cutState' is after max-harvesting, then fruit can be withered.
                    witheredValue = maxMatureValue  -- Assumption that 'withering' is just after max-mature.
                end
            end
            
            local function getColor(growthType, idx)
                local growthDesc = self.growthColors[growthType]
                if growthDesc == nil then
                    return {1,1,1,1}
                end
                return growthDesc[Utils.clamp(idx, 1, #growthDesc)]
            end
            
            --
            if fruitDesc.needsSeeding == true and witheredValue > 0 and cuttedValue > witheredValue then
                setFoliageStateOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, cuttedValue, unpack(getColor("cutted", 1), 1, 3))
            end
            --
            if witheredValue > 0 then
                setFoliageStateOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, witheredValue, unpack(getColor("withered", 1), 1, 3))
            end
            --
            if fruitDesc.maxPreparingGrowthState >= 0 then
                for i=minMatureValue,maxMatureValue do
                    setFoliageStateOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i, unpack(getColor("readyToPrepare", (i - minMatureValue) + 1), 1, 3))
                end
            end
            --
            for i=minHarvestValue,maxHarvestValue do
                setFoliageStateOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i, unpack(getColor("readyToHarvest", (i - minHarvestValue) + 1), 1, 3))
            end
            for i=minGrowthValue,maxGrowthValue do
                setFoliageStateOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i, unpack(getColor("growing", (i - minGrowthValue) + 1), 1, 3))
            end
        end
      end
    end
    
    generateFoliageStateOverlayGrowthStateColors(self.foliageStateOverlay)
    self.overlayReadyState = 1;
end,

toggleHotspots = function(self, enabled)
    for _,hotspot in pairs(g_currentMission.ingameMap.hotspots) do
        hotspot.enabled = enabled
    end

    if not enabled then
        -- Enable all field-number hotspots again.
        for _,fieldDef in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
            fieldDef.fieldMapHotspot.enabled = true
        end
    end
end,

update = function(self, dt)
    --
    if g_currentMission.ingameMap.isFullSize   -- Only allow input when mini-map is at full size.
    then
        if self.overlayReadyState ~= 1   -- Do NOT allow input while overlay is being build (strange things may happen).
        and InputBinding.hasEvent(InputBinding.MAXIMAPOVERLAY_TOGGLE)
        then
            playSample(self.pdaBeepSound, 1, 0.3, 0)
            
            self.overlayPage = (self.overlayPage + 1) % 3

            self.selectedElement = 0
            
            self.pageIsDirty = true
            self:refreshMapOverlay(self.overlayPage, true)
        end
    end

    --
    if self.overlayReadyState == 1 and getIsFoliageStateOverlayReady(self.foliageStateOverlay) then
        self.overlayReadyState = 2
        self.nextOverlayRefreshTime = g_currentMission.time + (math.max(10, self.overlayRefreshIntervalSecs) * 1000)
    elseif self.overlayReadyState == 2 and self.nextOverlayRefreshTime < g_currentMission.time then
        self:refreshMapOverlay(self.overlayPage, false)
    end
end,

draw = function(self)
    if  g_currentMission.ingameMap.isFullSize
    and g_currentMission.ingameMap.isVisible 
    and g_currentMission.ingameMap.resizeDir == 0
    then
        if self.pageIsDirty or self.isEditable ~= g_currentMission.controlPlayer then
            self:buildPage(self.overlayPage, g_currentMission.controlPlayer)
            InputBinding.setShowMouseCursor(self.isEditable);
        end
        self:renderPanes_v2()
    elseif self.isEditable then
        self.isEditable = false
        InputBinding.setShowMouseCursor(self.isEditable);
    end
end,

ingameMapDraw = function(self)
    if MaxiMapOverlay.overlayReadyState == 2 and g_gui.currentGui == nil then
        if self.isVisible then
            setOverlayUVs(MaxiMapOverlay.foliageStateOverlay, unpack(self.mapUVs));
            renderOverlay(MaxiMapOverlay.foliageStateOverlay
                ,self.mapPosX
                ,self.mapPosY
                ,self.mapWidth
                ,self.mapHeight
            )
        end
    end
end,

setRGB = function(self,r,g,b)
    if self.selectedElement > 0 then
        local color = self.legendFruits[self.selectedElement].color
        if r ~= nil then color[1] = Utils.clamp(r, 0, 1); end
        if g ~= nil then color[2] = Utils.clamp(g, 0, 1); end
        if b ~= nil then color[3] = Utils.clamp(b, 0, 1); end
        
        self.legendFruits[self.selectedElement]:setColor(color)

        self:setSpinRGB()
    end
end,

offsetRGB = function(self,r,g,b)
    if self.selectedElement > 0 then
        local color = self.legendFruits[self.selectedElement].color
        local function chg(current, offset)
            return Utils.clamp(math.floor((255*current) + offset)/255, 0, 1)
        end

        self.legendFruits[self.selectedElement]:setColor({
            chg(color[1], r),
            chg(color[2], g),
            chg(color[3], b)
        } )
        
        self:setSpinRGB()
    end
end,

setSpinRGB = function(self)
    if self.selectedElement > 0 then
        local color = self.legendFruits[self.selectedElement].color
        local colorText = {
            g_i18n:getText("spinRed"),
            g_i18n:getText("spinGreen"),
            g_i18n:getText("spinBlue"),
            g_i18n:getText("spinAlpha"),
        }
        for i=1,3 do
            colorText[i] = colorText[i]:format(color[i], math.floor(255*color[i]))
        end

        self.spinRed:setText(   colorText[1])
        self.spinGreen:setText( colorText[2])
        self.spinBlue:setText(  colorText[3])
        
        local colorBox = self.legendFruits[self.selectedElement].colorBox
        if colorBox ~= nil then
            colorBox:setColor( { color[1],color[2],color[3],1 } )
        end
        
        self:refreshMapOverlay(self.overlayPage, false)
    end
end,

toggleShowHide = function(self)
    if self.selectedElement > 0 then
        if self.overlayPage == 1 then
            local fruitType = self.legendFruits[self.selectedElement].fruitType
            local fruitDesc = FruitUtil.fruitIndexToDesc[fruitType]
            
            self.legendFruits[self.selectedElement]:setVisibility(not fruitDesc.mod_HideFruitOnMap)
            
            self:refreshMapOverlay(self.overlayPage, false)
            self.pageIsDirty = true
        end
    end
end,

selectElement = function(self, elementIdx)
    elementIdx = Utils.clamp(elementIdx, 0, #self.legendFruits)
    self.selectedElement = elementIdx
    self.pageIsDirty = true
end,

buildPage = function(self, pageNum, enableEditable)
    self.currentPanes = {}
    self.pageIsDirty = false
    self.isEditable = enableEditable
    if pageNum < 1 then
        return
    end
    
    local function add(pane)
        table.insert(self.currentPanes, pane)
        return pane
    end
    local function onClick(pane, callback)
        pane.onClick = callback
        return pane
    end

    local colorBlack = {0,0,0,1}
    
    local panelBackgroundColor = {1,1,1,0.5}
    local panelPaddingVerti = 0.008
    local panelPaddingHoriz = panelPaddingVerti / g_screenAspectRatio
    
    local titleBackgroundColor = {0,0,0,1}
    local titleForegroundColor = {1,1,1,1}
    local titleHeight = 0.04
    local titleFontSize = 0.02
    
    local spinBackgroundColor = {1,1,1,1}
    local spinForegroundColor = {0,0,0,1}
    local spinHeight = 0.03
    local spinFontSize = 0.02

    local cropRowHeight = 0.02
    local cropRightIndent = panelPaddingHoriz
    local cropFontSize = cropRowHeight * 0.8
    local cropForegroundColor = {0,0,0,1}
    local cropColorBoxHeight = cropRowHeight * 0.8
    local cropColorBoxWidth = cropColorBoxHeight / g_screenAspectRatio
    local cropColorBoxPaddingVerti = cropColorBoxHeight * 0.06
    local cropColorBoxPaddingHoriz = cropColorBoxWidth * (0.06 / g_screenAspectRatio)
    
    local h = 0.80
    local y = (1.0 - 0.1) - h
    local x = g_currentMission.ingameMap.mapPosX + g_currentMission.ingameMap.mapWidth
    local w = getTextWidth(titleFontSize, "MM MaxiMap Overlay mod MM")
    
    local yy = (y+h)-titleHeight
    add(self:createLabel_v2(    "title", {x,yy, w,titleHeight}, titleBackgroundColor, "MaxiMap Overlay mod", titleFontSize, titleForegroundColor, nil, true))
    add(self:createRectangle_v2("panel", {x,y,  w,(h-titleHeight)}, panelBackgroundColor))
    
    yy = yy-spinHeight
    local pageNames = {
        g_i18n:getText("pageFruitTypes"),
        g_i18n:getText("pageGrowth"),
    }
    add(self:createLabel_v2("pageSelector", {x+panelPaddingHoriz,yy, w-panelPaddingHoriz*2,spinHeight}, spinBackgroundColor, pageNames[pageNum], spinFontSize, spinForegroundColor, nil, true))

    local xB = x + panelPaddingHoriz
    local xR = xB + cropColorBoxPaddingHoriz
    local wR = cropColorBoxWidth  - (cropColorBoxPaddingHoriz*2)
    local hR = cropColorBoxHeight - (cropColorBoxPaddingVerti*2)
    local xT = xB + (cropColorBoxWidth + cropFontSize)
    local wT = w - (panelPaddingHoriz*2 + cropColorBoxWidth + cropFontSize)

    if pageNum == 1 or pageNum == 2 then
        local prevGroupNum = nil
        for i,legend in ipairs(self.legendFruits) do
            local title = legend.title
            local color = legend.color
            local colorFruit = {color[1],color[2],color[3],1}
    
            if prevGroupNum ~= legend.groupNum then
                yy = yy-cropRowHeight/7
            end
            prevGroupNum = legend.groupNum
    
            yy=yy-cropRowHeight
            onClick(
                add(self:createRectangle_v2("rect", {xB,yy, w-panelPaddingHoriz*2,cropRowHeight}, nil)),
                function() self:selectElement(i) end
            )
            
            legend.colorBox = add(self:createColorBox_v2("box", {xB,yy, cropColorBoxWidth,cropColorBoxHeight}, colorFruit, cropColorBoxPaddingHoriz,cropColorBoxPaddingVerti))
            add(self:createLabel_v2("text", {xT,yy, wT,cropRowHeight}, nil, legend.title, cropFontSize, cropForegroundColor, RenderText.ALIGN_LEFT, false))
            if legend.hidden then
                add(self:createRectangle_v2("hide", {x + (panelPaddingHoriz/2),yy+(cropColorBoxHeight/2 - cropColorBoxPaddingVerti),w-(panelPaddingHoriz),cropColorBoxPaddingVerti*2}, {0,0,0,1}))
            end
        end
    end

    self.spinRed   = nil
    self.spinGreen = nil
    self.spinBlue  = nil
    
    if self.isEditable
    and self.selectedElement > 0
    then
        local colorRed      = {1,0,0,1}
        local colorGreen    = {0,1,0,1}
        local colorBlue     = {0,0,1,1}

        local spinHeight = 0.02
        local spinFontSize = 0.018

        local labelEdit = g_i18n:getText("titleEdit"):format(self.legendFruits[self.selectedElement].title)
        
        yy = yy - spinHeight * 1.2
        add(self:createLabel_v2("selectedElement", {x+panelPaddingHoriz,yy, w-panelPaddingHoriz*2,cropRowHeight}, panelBackgroundColor, labelEdit, cropFontSize, cropForegroundColor, RenderText.ALIGN_CENTER, true))
        
        yy = yy - spinHeight * 1.05
        self.spinRed   = add(self:createSpinLabel_v2("red",   {x+panelPaddingHoriz,yy, w-panelPaddingHoriz*2,spinHeight}, {1,0.9,0.9,1}, g_i18n:getText("spinRed"),   spinFontSize, spinForegroundColor, spinForegroundColor, {1,1,1,1}))
        yy = yy - spinHeight * 1.05
        self.spinGreen = add(self:createSpinLabel_v2("green", {x+panelPaddingHoriz,yy, w-panelPaddingHoriz*2,spinHeight}, {0.9,1,0.9,1}, g_i18n:getText("spinGreen"), spinFontSize, spinForegroundColor, spinForegroundColor, {1,1,1,1}))
        yy = yy - spinHeight * 1.05
        self.spinBlue  = add(self:createSpinLabel_v2("blue",  {x+panelPaddingHoriz,yy, w-panelPaddingHoriz*2,spinHeight}, {0.9,0.9,1,1}, g_i18n:getText("spinBlue"),  spinFontSize, spinForegroundColor, spinForegroundColor, {1,1,1,1}))
        
        if pageNum == 1 then
            yy = yy - spinHeight * 1.05
            onClick(
                add(self:createLabel_v2("showHide", {x+panelPaddingHoriz,yy, w-panelPaddingHoriz*2,spinHeight}, {0.9,0.9,0.9,1}, g_i18n:getText("toggleVisible"), cropFontSize, cropForegroundColor, RenderText.ALIGN_CENTER, false)),
                function() self:toggleShowHide() end
            )
        end
        
        self:setSpinRGB()
        
        self.spinRed  .onDecrease = function() self:offsetRGB(-1,0,0) end
        self.spinRed  .onIncrease = function() self:offsetRGB( 1,0,0) end
        self.spinGreen.onDecrease = function() self:offsetRGB(0,-1,0) end
        self.spinGreen.onIncrease = function() self:offsetRGB(0, 1,0) end
        self.spinBlue .onDecrease = function() self:offsetRGB(0,0,-1) end
        self.spinBlue .onIncrease = function() self:offsetRGB(0,0, 1) end
        
        self.spinRed  .onSetAbsolute = function(absValue) self:setRGB(absValue, nil, nil) end
        self.spinGreen.onSetAbsolute = function(absValue) self:setRGB(nil, absValue, nil) end
        self.spinBlue .onSetAbsolute = function(absValue) self:setRGB(nil, nil, absValue) end

        --
        if self.isMissingModsSettingsMod then
            yy = yy - spinHeight * 1.1
            add(self:createLabel_v2("warning", {x+panelPaddingHoriz,yy, w-panelPaddingHoriz*2,cropRowHeight}, nil, g_i18n:getText("missingModsSettingsMod"), cropFontSize * 0.9, cropForegroundColor, RenderText.ALIGN_LEFT, false, nil, nil, true))
        end
    end
    
end,

createRectangle_v2 = function(self, paneName, xywh, rectColor)
    local x,y,w,h = unpack(xywh)
    local pane = {
        _rectColor = rectColor,
        render = function(self)
            if self._rectColor ~= nil then
                setOverlayColor(MaxiMapOverlay.paneOverlay, unpack(self._rectColor));
                renderOverlay(MaxiMapOverlay.paneOverlay, x,y, w,h);
            end
        end,
        inBox = function(self, posX,posY)
            return (x <= posX and posX <= x+w
                and y <= posY and posY <= y+h)
        end,
        onMouseEvent = function(self, posX,posY,isDown,isUp,button)
            if isDown and self.onClick ~= nil then
                self.onClick()
            end
        end,
        setColor = function(self, rectColor)
            self._rectColor = rectColor
        end,
    }
    return pane
end,

createColorBox_v2 = function(self, paneName, xywh, rectColor, borderHoriz,borderVerti)
    local x,y,w,h = unpack(xywh)
    local xB,yB,wB,hB = x+borderHoriz,y+borderVerti,w-borderHoriz*2,h-borderVerti*2
    local pane = {
        _black = self:createRectangle_v2(paneName, {x,y,w,h}, {0,0,0,1}),
        _color = self:createRectangle_v2(paneName, {xB,yB,wB,hB}, rectColor),
        render = function(self)
            self._black:render()
            self._color:render()
        end,
        inBox = function(self, posX,posY)
            return (x <= posX and posX <= x+w
                and y <= posY and posY <= y+h)
        end,
        onMouseEvent = function(self, posX,posY,isDown,isUp,button)
        end,
        setColor = function(self, rectColor)
            self._color:setColor(rectColor)
        end,
    }
    return pane
end,

createLabel_v2 = function(self, paneName, xywh, rectColor, text, fontSize, fontColor, textAlign, fontBold, fontShadeColor, fontShadeOffset, wordWrap)
    textAlign = Utils.getNoNil(textAlign, RenderText.ALIGN_CENTER)
    fontBold  = Utils.getNoNil(fontBold, false)

    local x,y,w,h = unpack(xywh)
    local xT,yT = x,y
    if textAlign == RenderText.ALIGN_CENTER then
        xT = x + (w / 2)
    elseif textAlign == RenderText.ALIGN_RIGHT then
        xT = x + w
    end
    --yT = y + ((h * 0.5) - (fontSize * 0.6))
    local txtHeight, txtLines = getTextHeight(fontSize, text)
    yT = y + ((h * 0.5) - (txtHeight * 0.5)) * 1.15
    
    local fR,fG,fB,fA = unpack(fontColor)
    
    local sR,sG,sB,sA 
    if fontShadeColor ~= nil then
        sR,sG,sB,sA = unpack(fontShadeColor)
        fontShadeOffset = Utils.getNoNil(fontShadeOffset, 0.009)
    end
    
    local pane = {
        _paneRect = self:createRectangle_v2(paneName, xywh, rectColor),
        _text = text,
        render = function(self)
            self._paneRect:render()
            
            setTextAlignment(textAlign)
            setTextBold(fontBold)
            if wordWrap == true then
                setTextWrapWidth(w)
            else
                setTextWrapWidth(0)
            end
        
            if sR ~= nil then
                setTextColor(sR,sG,sB,sA)
                renderText(xT+fontShadeOffset,yT-fontShadeOffset, fontSize, self._text)
            end
        
            setTextColor(fR,fG,fB,fA)
            renderText(xT,yT, fontSize, self._text)
        end,
        setText = function(self, text)
            self._text = text
        end,
        inBox = function(self, posX,posY)
            return (x <= posX and posX <= x+w
                and y <= posY and posY <= y+h)
        end,
        onMouseEvent = function(self, posX,posY,isDown,isUp,button)
            if isDown and self.onClick ~= nil then
                self.onClick()
            end
        end,
    }
    return pane
end,

createSpinLabel_v2 = function(self, paneName, xywh, backColor, text, fontSize, fontColor, spinBackColor, spinFontColor)
    local x,y,w,h = unpack(xywh)
    local ww = h * 0.7 -- TODO aspect ratio
    local xL,yL,wL,hL = x,y,ww,h
    local xR,yR,wR,hR = x+w-ww,y,ww,h
    local xT,yT,wT,hT = x+ww,y,w-ww*2,h
    
    local pane = {
        _paneLeft = self:createLabel_v2(paneName, {xL,yL,wL,hL}, spinBackColor, "<",  fontSize, spinFontColor, RenderText.ALIGN_CENTER, true ),
        _paneRght = self:createLabel_v2(paneName, {xR,yR,wR,hR}, spinBackColor, ">",  fontSize, spinFontColor, RenderText.ALIGN_CENTER, true ),
        _paneText = self:createLabel_v2(paneName, {xT,yT,wT,hT}, backColor,     text, fontSize, fontColor,     RenderText.ALIGN_CENTER, false),
        render = function(self)
            self._paneText:render()
            self._paneLeft:render()
            self._paneRght:render()
        end,
        setText = function(self, text)
            self._paneText:setText(text)
        end,
        inBox = function(self, posX,posY)
            return (x <= posX and posX <= x+w
                and y <= posY and posY <= y+h)
        end,
        onMouseEvent = function(self, posX,posY,isDown,isUp,button)
            if isDown then
                if (xT <= posX and posX <= xT+wT
                and yT <= posY and posY <= yT+hT)
                and self.onSetAbsolute ~= nil
                then
                    self.onSetAbsolute((posX - xT) / wT)
                elseif (xL <= posX and posX <= xL+wL
                    and yL <= posY and posY <= yL+hL)
                    and self.onDecrease ~= nil
                then
                    self.onDecrease()
                elseif (xR <= posX and posX <= xR+wR
                    and yR <= posY and posY <= yR+hR)
                    and self.onIncrease ~= nil
                then
                    self.onIncrease()
                end
            end
        end,
    }
    return pane
end,

renderPanes_v2 = function(self)
    for _,pane in pairs(self.currentPanes) do
        pane:render()
    end
    -- Reset font/text properties
    setTextColor(1,1,1,1)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextWrapWidth(0)
end,

}

--
addModEventListener(MaxiMapOverlay);

print(string.format("Script loaded: MaxiMapOverlay.lua (v%s)", MaxiMapOverlay.version));
